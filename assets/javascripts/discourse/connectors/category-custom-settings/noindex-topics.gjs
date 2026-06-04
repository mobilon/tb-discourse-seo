import Component from "@glimmer/component";

export default class NoindexTopicsSettings extends Component {
  <template>
    {{#if @outletArgs.form}}
      <@outletArgs.form.Section @title="TB Discourse SEO">
        <@outletArgs.form.Object @name="custom_fields" as |object|>
          <object.Field
            @name="noindex_topics"
            @title="Add the tag Noindex in topics from this category"
            @type="checkbox"
            @format="max"
            as |field|
          >
            <field.Control />
          </object.Field>
        </@outletArgs.form.Object>
      </@outletArgs.form.Section>
    {{/if}}
  </template>
}