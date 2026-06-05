# frozen_string_literal: true

# name: TB-Discourse-Seo
# about: Adds "X-Robots-Tag: noindex" header to topics from specific categories
# version: 0.1.0
# authors: Thiago Mobilon
# url: https://github.com/mobilon/tb-discourse-seo

enabled_site_setting :tb_discourse_seo_enabled

after_initialize do
  register_category_custom_field_type :noindex_topics, :boolean

  # Make sure the custom field is preloaded whenever categories are listed
  # (the Site bootstrap serializes every category on almost every request).
  Site.preloaded_category_custom_fields << "noindex_topics" if Site.respond_to?(:preloaded_category_custom_fields)

  add_to_serializer(:basic_category, :noindex_topics) do
    object.custom_fields["noindex_topics"]
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
