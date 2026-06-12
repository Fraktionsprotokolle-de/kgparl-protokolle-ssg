class PopupInfo extends HTMLElement {
  constructor() {
    super();
    this._title = "Popup";
    this._content = "";
    this._html = false;
    this._id = "";
  }

  connectedCallback() {
    const shadow = this.attachShadow({ mode: "open" });

    const wrapper = document.createElement("span");
    wrapper.setAttribute("class", "wrapper");

    const icon = document.createElement("span");
    icon.setAttribute("class", "icon");
    /*    icon.setAttribute("tabindex", 0);*/
    // Preserve innerHTML to keep any links in the icon
    icon.innerHTML = this.innerHTML;

    const info = document.createElement("span");
    info.setAttribute("class", "info");

    this._content = this.getAttribute("data-content");
    this._title = this.getAttribute("data-title");
    this._html = this.getAttribute("data-html");
    const content = document.createElement("span");

    var title_elem;
    if (this.content) {
      title_elem = document.createElement("h4");
    } else {
      title_elem = document.createElement("span");
    }

    title_elem.textContent = this._title;

    info.appendChild(title_elem);

    if (this._html === "true") {
      content.innerHTML = this._content;
      info.appendChild(document.createElement("hr"));
    } else {
      content.textContent = this._content;
    }

    info.appendChild(content);

    const style = document.createElement("style");

    style.textContent = `
      .wrapper {
        position: relative;
        display: inline;
      }

      .info {
        width: min(24rem, 80vw);
        border: 1px solid var(--color-border, #e0e0e0);
        padding: 0.75rem 1rem;
        background: var(--color-background, #faf9f7);
        border-radius: 0.375rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.15s ease-in, visibility 0.15s ease-in;
        position: absolute;
        bottom: calc(100% + 6px);
        left: 50%;
        transform: translateX(-50%);
        z-index: 1000;
        color: var(--text-color, #2b2b2b);
        font-size: 0.875rem;
        line-height: 1.5;
        text-align: left;
        font-weight: normal;
        font-style: normal;
      }

      .info::after {
        content: '';
        position: absolute;
        top: 100%;
        left: var(--arrow-offset, 50%);
        transform: translateX(-50%);
        border: 6px solid transparent;
        border-top-color: var(--color-border, #e0e0e0);
      }

      .wrapper:hover .info,
      .icon:focus + .info,
      .info:hover {
        opacity: 1;
        visibility: visible;
      }

      .icon {
        cursor: var(--popup-cursor, pointer);
        text-decoration: var(--popup-text-decoration, none);
        text-decoration-color: var(--popup-text-decoration-color, currentColor);
      }

      .icon a {
        color: var(--fn-color);
        text-decoration: none;
        pointer-events: auto;
      }

      .icon a:hover {
        text-decoration: underline;
      }

      .icon a.fn::before {
        content: var(--fn-prefix, '');
      }

      .icon a.fn::after {
        content: var(--fn-suffix, '');
      }

      .kgparl-link {
        color: var(--color-primary, rgb(4,130,99));
      }

      h4 {
        margin: 0 0 0.25rem 0;
        font-size: 0.9375rem;
        font-weight: 600;
        color: var(--color-text, #2b2b2b);
      }

      hr {
        border: none;
        border-top: 1px solid var(--color-border, #e0e0e0);
        margin: 0.5rem 0;
      }
    `;

    shadow.appendChild(style);
    shadow.appendChild(wrapper);
    wrapper.appendChild(icon);
    wrapper.appendChild(info);

    // Inherit text-decoration from ancestor (e.g. .note-segment underline)
    const decorated = this.closest('.note-segment');
    if (decorated) {
      const cs = window.getComputedStyle(decorated);
      if (cs.textDecorationLine !== 'none') {
        this.style.setProperty('--popup-text-decoration', cs.textDecorationLine);
        this.style.setProperty('--popup-text-decoration-color', cs.textDecorationColor);
      }
    }

    // Add event listeners for mouseenter and mouseleave
    // Listen on both wrapper and icon — wrapper can have 0 height
    // when parent uses line-height: 0 (e.g. superscript footnotes)
    wrapper.addEventListener("mouseenter", () => this.showInfo(info));
    wrapper.addEventListener("mouseleave", () => this.hideInfo(info));
    icon.addEventListener("mouseenter", () => this.showInfo(info));
    icon.addEventListener("mouseleave", () => this.hideInfo(info));
    icon.addEventListener("focus", () => this.showInfo(info));
    icon.addEventListener("blur", () => this.hideInfo(info));
  }

  showInfo(info) {
    // Reset position before measuring
    info.style.left = "50%";
    info.style.transform = "translateX(-50%)";

    info.style.transition = "opacity 0.2s ease-in, visibility 0.2s ease-in";
    info.style.opacity = "1";
    info.style.visibility = "visible";

    // Adjust horizontal position to stay within viewport
    const rect = info.getBoundingClientRect();
    const padding = 8;

    if (rect.left < padding) {
      // Overflows left edge
      const shift = padding - rect.left;
      info.style.left = `calc(50% + ${shift}px)`;
      // Move arrow to stay aligned with trigger
      info.style.setProperty("--arrow-offset", `calc(50% - ${shift}px)`);
    } else if (rect.right > window.innerWidth - padding) {
      // Overflows right edge
      const shift = rect.right - (window.innerWidth - padding);
      info.style.left = `calc(50% - ${shift}px)`;
      info.style.setProperty("--arrow-offset", `calc(50% + ${shift}px)`);
    } else {
      info.style.setProperty("--arrow-offset", "50%");
    }
  }

  hideInfo(info) {
    // Check if the mouse is still over the info element
    const isOver = info.matches(":hover");
    if (!isOver) {
      info.style.transition = "opacity 0.5s ease-out, visibility 0.5s ease-out";
      info.style.opacity = "0";
      info.style.visibility = "hidden";
      // Reset position for next show
      info.style.left = "50%";
      info.style.transform = "translateX(-50%)";
      info.style.setProperty("--arrow-offset", "50%");
    }
  }
}

customElements.define("popup-info", PopupInfo);
