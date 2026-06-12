export class CustomCheckbox extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
  }

  static get observedAttributes() {
    return ["color", "text-value", "key"];
  }

  connectedCallback() {
    this.render();
    this.setupEventListeners();
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
              display: inline-block;
            }
            .checkbox-container {
              display: inline-flex;
              align-items: center;
              cursor: pointer;
            }
            .checkbox {
              width: 20px;
              height: 20px;
              border: 2px solid #333;
              border-radius: 3px;
              margin-right: 8px;
              display: flex;
              justify-content: center;
              align-items: center;
              font-weight: bold;
              font-size: 16px;
              color: #333;
              transition: background-color 0.3s ease;
            }
            .checkbox:focus {
              outline: 2px solid blue;
              outline-offset: 2px;
            }
            .checkbox[aria-checked="true"]::after {
              content: "✓";
              color: white;
            }
            .text-value {
              margin-left: 8px;
              font-size: 14px;
            }
          </style>
          <label class="checkbox-container">
            <span class="checkbox" tabindex="0" role="checkbox" aria-checked="false"></span>
            <slot></slot>
            <span class="text-value"></span>
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
    const color = this.getAttribute("color") || "#e0e0e0";
    this.checkboxSpan = this.shadowRoot.querySelector(".checkbox");
    var isChecked;
    if (this.checkboxSpan) {
      isChecked = this.checkboxSpan.getAttribute("aria-checked") === "true";
      this.checkboxSpan.style.backgroundColor = isChecked
        ? color
        : "transparent";
    } else {
      isChecked = false;
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
