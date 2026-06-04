import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";

export default class NoindexTopicsSettings extends Component {
  @tracked checked;

  constructor(owner, args) {
    super(owner, args);
    const value = this.args.outletArgs?.transientData?.custom_fields?.noindex_topics;
    this.checked = value === true || value === "true";
  }

  @action
  toggleNoindex(event) {
    this.checked = event.target.checked;
    this.args.outletArgs?.form?.set("custom_fields.noindex_topics", this.checked);
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