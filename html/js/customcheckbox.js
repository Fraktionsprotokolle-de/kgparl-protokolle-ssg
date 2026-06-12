class CustomCheckbox extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
  }

  static get observedAttributes() {
    return ["color", "text-value", "key"];
  }

  connectedCallback() {
    // Only render if shadow DOM is empty (first time connection)
    // This prevents re-rendering when element is moved in DOM
    if (!this.shadowRoot.querySelector('.checkbox-container')) {
      this.render();
      this.setupEventListeners();
    }
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (this.shadowRoot) {
      this.updateStyle();
      this.updateTextValue();
    }
  }

  render() {
    this.shadowRoot.innerHTML = `
          <style>
           :host {
  display: block;
  width: 100%;
}
.checkbox-container {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 2px;
  width: 100%;
}
.checkbox {
  width: 16px;
  min-width: 16px;
  height: 16px;
  min-height: 16px;
  flex-shrink: 0;
  margin-right: 8px;
  margin-top: 1px;
  accent-color: var(--color-primary, rgb(4,130,99));
  cursor: pointer;
}
.checkbox:focus-visible {
  outline: 2px solid var(--color-primary, rgb(4,130,99));
  outline-offset: 2px;
}
::slotted(*) {
  flex: 1;
  text-align: right;
}
.text-value {
  font-size: 14px;
  margin-left: 0;
  text-align: right;
}

          </style>
          <label class="checkbox-container">
            <input type="checkbox" class="checkbox" aria-checked="false" />
            <slot></slot>
            <span class="text-value d-flex px-2 align-items-center mb-1 me-4 text-black"></span>
          </label>
        `;

    this.updateStyle();
    this.updateTextValue();
  }

  setupEventListeners() {
    this.checkboxSpan.addEventListener("click", () => this.toggle());
    this.checkboxSpan.addEventListener("keydown", (e) => {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        this.toggle();
      }
    });
  }

  toggle() {
    const isChecked = this.checkboxSpan.getAttribute("aria-checked") === "true";
    this.checkboxSpan.setAttribute("aria-checked", !isChecked);
    const key = this.getAttribute("key");
    this.updateStyle();

    this.dispatchEvent(
      new CustomEvent("custom-checkbox-change", {
        bubbles: true,
        composed: true,
        detail: { checked: !isChecked, key: key },
      }),
    );

    this.dispatchEvent(
      new CustomEvent("change", {
        bubbles: true,
        composed: true,
        detail: { checked: !isChecked },
      }),
    );
  }

  updateStyle() {
    this.checkboxSpan = this.shadowRoot.querySelector("input.checkbox");
    if (this.checkboxSpan) {
      var isChecked = this.checkboxSpan.getAttribute("aria-checked") === "true";
      this.checkboxSpan.checked = isChecked;
    }
  }

  updateTextValue() {
    this.textValueSpan = this.shadowRoot.querySelector(".text-value");
    if (this.textValueSpan) {
      const textValue = this.getAttribute("text-value") || "";
      this.textValueSpan.textContent = textValue;
    }
  }
}

customElements.define("custom-checkbox", CustomCheckbox);
