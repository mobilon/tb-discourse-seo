import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";

export default class NoindexTopicsSettings extends Component {
  @tracked checked;

  constructor(owner, args) {
    super(owner, args);
    const outletArgs = this.args.outletArgs || {};
    const value =
      outletArgs.transientData?.custom_fields?.noindex_topics ??
      outletArgs.category?.custom_fields?.noindex_topics;
    this.checked = value === true || value === "true";
  }

  @action
  toggleNoindex(event) {
    this.checked = event.target.checked;
    const outletArgs = this.args.outletArgs || {};

    // New FormKit-based category form.
    if (outletArgs.form?.set) {
      outletArgs.form.set("custom_fields.noindex_topics", this.checked);
      return;
    }

    // Legacy category edit form.
    const category = outletArgs.category;
    if (category?.set) {
      const customFields = Object.assign({}, category.custom_fields);
      customFields.noindex_topics = this.checked;
      category.set("custom_fields", customFields);
    }
  }

  <template>
    <div class="control-group category-noindex-topics">
      <label class="checkbox-label">
        <input
          type="checkbox"
          checked={{this.checked}}
          {{on "change" this.toggleNoindex}}
        />
        Add the tag Noindex in topics from this category
      </label>
    </div>
  </template>
}