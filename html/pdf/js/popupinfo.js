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
    icon.textContent = this.textContent;

    const info = document.createElement("span");
    info.setAttribute("class", "info");

    this._content = this.getAttribute("data-content");
    this._title = this.getAttribute("data-title");
    this._html = this.getAttribute("data-html");
    const content = document.createElement("span");

    const title_elem = document.createElement("h4");
    title_elem.textContent = this._title;

    if (this._html === "true") {
      content.innerHTML = this._content;
    } else {
      content.textContent = this._content;
    }
    info.appendChild(title_elem);
    info.appendChild(document.createElement("hr"));
    //    info.appendChild(document.createElement("br"));
    info.appendChild(content);
    icon.textContent = this.textContent;

    const style = document.createElement("style");

    style.textContent = `
      .wrapper {
        position: relative;
        display: inline-block;
      }

      .info {
        font-size: 0.8rem;
        width: 200px;
        border: 1px solid black;
        padding: 10px;
        background: white;
        border-radius: 10px;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.2s ease-in, visibility 0.2s ease-in;
        position: absolute;
        bottom: 100%;
        left: 50%;
        transform: translateX(-50%);
        z-index: 1000;
      }

      .wrapper:hover .info,
      .icon:focus + .info,
      .info:hover {
        opacity: 1;
        visibility: visible;
      }

      .icon {
        cursor: pointer;
      }

      .kgparl-link {
        color: rgb(4,130,99);
      }
      h4 {
        margin-top: 0;
      }
    `;

    shadow.appendChild(style);
    shadow.appendChild(wrapper);
    wrapper.appendChild(icon);
    wrapper.appendChild(info);

    // Add event listeners for mouseenter and mouseleave
    wrapper.addEventListener("mouseenter", () => this.showInfo(info));
    wrapper.addEventListener("mouseleave", () => this.hideInfo(info));
    icon.addEventListener("focus", () => this.showInfo(info));
    icon.addEventListener("blur", () => this.hideInfo(info));
  }

  showInfo(info) {
    info.style.transition = "opacity 0.2s ease-in, visibility 0.2s ease-in";
    info.style.opacity = "1";
    info.style.visibility = "visible";
  }

  hideInfo(info) {
    // Check if the mouse is still over the info element
    const isOver = info.matches(":hover");
    if (!isOver) {
      info.style.transition = "opacity 1.5s ease-out, visibility 1.5s ease-out";
      info.style.opacity = "0";
      info.style.visibility = "hidden";
    }
  }
}

customElements.define("popup-info", PopupInfo);
