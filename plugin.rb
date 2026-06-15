# frozen_string_literal: true

# name: TB-Discourse-Seo
# about: SEO helpers for Discourse: noindex per category and hreflang tags for translated topics
# version: 0.2.0
# authors: Thiago Mobilon
# url: https://github.com/mobilon/tb-discourse-seo

enabled_site_setting :tb_discourse_seo_enabled

module ::TbDiscourseSeo
  # Builds the hreflang <link> tags for a topic that has localized versions.
  #
  # Strategy: only emit hreflang alternates for locales the topic actually has
  # a TopicLocalization for (intersected with the locales configured in
  # `content_localization_supported_locales`). This avoids the core behaviour of
  # advertising every supported locale on every page even when no translation
  # exists for it (which is technically incorrect hreflang).
  module Hreflang
    module_function

    # Converts a Discourse locale string (e.g. "pt_BR", "zh_CN", "es") into a
    # BCP 47 / hreflang code (e.g. "pt-BR", "zh-CN", "es").
    def to_hreflang_code(locale)
      locale.to_s.tr("_", "-")
    end

    # The locales the site is configured to translate content into, plus the
    # default locale. Pipe-delimited in the site setting.
    def configured_locales
      locales = SiteSetting.content_localization_supported_locales.to_s.split("|").map(&:strip).reject(&:blank?)
      default = SiteSetting.default_locale.to_s
      locales << default if default.present? && !locales.include?(default)
      locales.uniq
    end

    # The locales that this specific topic actually has localizations for.
    def localized_locales(topic_id)
      TopicLocalization.where(topic_id: topic_id).pluck(:locale)
    rescue StandardError
      # TopicLocalization is only present on Discourse versions that ship the
      # content localization feature. Fail gracefully on older versions.
      []
    end

    # Builds the full HTML string of hreflang <link> tags for the given topic,
    # or an empty string when nothing should be emitted.
    def tags_for(topic)
      return "" if topic.blank?
      return "" unless defined?(TopicLocalization)
      return "" unless SiteSetting.content_localization_enabled

      default_locale = SiteSetting.default_locale.to_s
      configured = configured_locales
      translated = localized_locales(topic.id)

      # Only advertise locales that are both configured for translation AND
      # actually translated for this topic.
      alternates = (configured & translated).reject { |l| l == default_locale }
      return "" if alternates.empty?

      base_url = topic.url # absolute URL, e.g. https://example.com/t/slug/123
      links = []

      # Self-referencing tag for the default (source) language.
      links << link_tag(to_hreflang_code(default_locale), base_url) if default_locale.present?

      # One tag per available translation, using the ?tl=<locale> param.
      alternates.each do |locale|
        translated_url = "#{base_url}?#{Discourse::LOCALE_PARAM}=#{locale}"
        links << link_tag(to_hreflang_code(locale), translated_url)
      end

      # x-default points to the canonical (default-language) topic URL. It is a
      # standard part of an hreflang cluster (recommended by Google), so it is
      # always emitted alongside the other tags.
      links << link_tag("x-default", base_url)

      links.join("\n")
    end

    def link_tag(hreflang, href)
      %(<link rel="alternate" hreflang="#{ERB::Util.html_escape(hreflang)}" href="#{ERB::Util.html_escape(href)}" />)
    end

    # Resolves the topic currently being shown by a TopicsController#show action.
    def topic_from_controller(controller)
      return nil unless controller.is_a?(::TopicsController)
      return nil unless controller.action_name == "show"

      topic_view = controller.instance_variable_get(:@topic_view)
      topic = topic_view&.topic
      topic ||= Topic.find_by(id: controller.params[:topic_id].presence || controller.params[:id].presence)
      topic
    rescue StandardError
      nil
    end

    # Entry point used by the html builders.
    def render_for_controller(controller)
      return "" unless SiteSetting.tb_discourse_seo_enabled?
      return "" unless SiteSetting.tb_discourse_seo_hreflang_enabled?

      topic = topic_from_controller(controller)
      tags_for(topic)
    rescue StandardError => e
      Rails.logger.warn("[tb-discourse-seo] failed to build hreflang tags: #{e.message}")
      ""
    end
  end
end

after_initialize do
  register_category_custom_field_type :noindex_topics, :boolean

  # Make sure the custom field is preloaded whenever categories are listed
  # (the Site bootstrap serializes every category on almost every request).
  Site.preloaded_category_custom_fields << "noindex_topics" if Site.respond_to?(:preloaded_category_custom_fields)

  add_to_serializer(:basic_category, :noindex_topics) do
    object.custom_fields["noindex_topics"]
  end

  # Inject hreflang tags into the <head> of topic pages, for both the regular
  # (Ember) layout and the crawler layout served to search engine bots.
  register_html_builder("server:before-head-close") do |controller|
    ::TbDiscourseSeo::Hreflang.render_for_controller(controller)
  end

  register_html_builder("server:before-head-close-crawler") do |controller|
    ::TbDiscourseSeo::Hreflang.render_for_controller(controller)
  end

  ::TopicsController.class_eval do
    before_action :add_noindex_header, only: :show

    private

    def add_noindex_header
      return unless SiteSetting.tb_discourse_seo_enabled?

      topic_id = params[:topic_id].presence || params[:id].presence
      return if topic_id.blank?

      category_id = Topic.where(id: topic_id).pick(:category_id)
      return if category_id.blank?

      if tb_seo_category_noindex?(category_id)
        response.headers["X-Robots-Tag"] = "noindex"
      end
    rescue => e
      Rails.logger.warn("[tb-discourse-seo] failed to set noindex header: #{e.message}")
    end

    def tb_seo_category_noindex?(category_id)
      value = CategoryCustomField.where(
        category_id: category_id,
        name: "noindex_topics"
      ).pick(:value)

      %w[true t 1].include?(value.to_s.downcase)
    end
  end
end
