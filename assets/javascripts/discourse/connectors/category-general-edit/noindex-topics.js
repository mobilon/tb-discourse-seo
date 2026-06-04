import Component from "@glimmer/component";
import { action } from "@ember/object";

export default class NoindexTopicsSetting extends Component {
  get category() {
    return this.args.outletArgs?.category || this.args.category;
  }

  get noindexTopics() {
    const value = this.category?.custom_fields?.noindex_topics;
    return value === true || value === "true";
  }

  @action
  updateNoindex(event) {
    const category = this.category;
    if (!category) {
      return;
    }

    const checked = event.target.checked;
    const customFields = Object.assign({}, category.custom_fields);
    customFields.noindex_topics = checked;
    category.set("custom_fields", customFields);
  }
}
