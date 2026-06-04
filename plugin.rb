# frozen_string_literal: true

# name: TB Discourse SEO
# about: Adds X-Robots-Tag: noindex header to topics from specific categories
# version: 0.1.0
# authors: Mobilon
# url: https://github.com/mobilon/tb-discourse-seo

enabled_site_setting :tb_discourse_seo_enabled

register_category_custom_field_type :noindex_topics, :boolean

add_to_serializer(:basic_category, :noindex_topics) { object.custom_fields["noindex_topics"] }
add_to_serializer(:basic_category, :include_noindex_topics?) { true }

after_initialize do
  ::TopicsController.class_eval do
    after_action :add_noindex_header, only: :show

    private

    def add_noindex_header
      return unless SiteSetting.tb_discourse_seo_enabled?

      topic = @topic_view&.topic
      return unless topic&.category

      category = topic.category
      if category_noindex?(category)
        response.headers["X-Robots-Tag"] = "noindex"
      end
    end

    def category_noindex?(category)
      return true if category.custom_fields["noindex_topics"].to_s == "true"
      return false unless category.parent_category_id

      parent = Category.find_by(id: category.parent_category_id)
      parent && category_noindex?(parent)
    end
  end
end
