import { Controller } from "@hotwired/stimulus";

// Connects to data-controller='nested-form'
export default class extends Controller {
  static targets = ["target", "template"];
  static values = {
    wrapperSelector: {
      type: String,
      default: ".nested-form-wrapper",
    },
    childIndex: {
      type: String,
      default: "NEW_RECORD",
    },
  };

  add(e) {
    e.preventDefault();

    const childIndexRegex = new RegExp(this.childIndexValue, "g");
    const newContentTimestamp = new Date().getTime().toString();

    const content = this.templateTarget.innerHTML.replace(childIndexRegex, newContentTimestamp);
    this.targetTarget.insertAdjacentHTML("beforebegin", content);

    const event = new CustomEvent("rails-nested-form:add", { bubbles: true });
    this.element.dispatchEvent(event);
  }

  remove(e) {
    e.preventDefault();

    const wrapper = e.target.closest(this.wrapperSelectorValue);

    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove();
    } else {
      wrapper.style.display = "none";

      const input = wrapper.querySelector("input[name*='_destroy']");
      input.value = "1";
    }

    const event = new CustomEvent("rails-nested-form:remove", { bubbles: true });
    this.element.dispatchEvent(event);
  }
}
