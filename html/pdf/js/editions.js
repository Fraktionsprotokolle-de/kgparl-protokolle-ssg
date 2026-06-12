const targetDiv = document.getElementById("sitzungsverlauf");
const copyfrom = document.getElementById("svplist");
const hamburgerMenu = document.getElementById("hamburger-menu");
const copyto = document.getElementById("menu-items");
copyto.innerHTML = copyfrom.innerHTML;
function toggleHamburgerMenu() {
  const rect = targetDiv.getBoundingClientRect();
  if (rect.bottom <= 0) {
    hamburgerMenu.classList.remove("hidden");
  } else {
    hamburgerMenu.classList.add("hidden");
  }
}

window.addEventListener("scroll", toggleHamburgerMenu);

// Get the query parameter "q" from the URL
const urlParams = new URLSearchParams(window.location.search);
const q = urlParams.get("q");

// Function to highlight text within text nodes and insert the span as HTML
function highlightTextInNode(node) {
    if (node.nodeType === Node.TEXT_NODE) {
        // Skip if parent already has highlight class (avoid duplicate processing)
        if (node.parentNode && node.parentNode.classList && node.parentNode.classList.contains('highlight')) {
            return;
        }

        // Escape special regex characters in the search term
        const escapedQ = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const regex = new RegExp(escapedQ, "gi");
        const text = node.textContent;

        // Check if there's a match
        if (!regex.test(text)) {
            return;
        }

        // Reset regex since test() moves the lastIndex
        regex.lastIndex = 0;

        const parentNode = node.parentNode;
        const fragment = document.createDocumentFragment();
        let lastIndex = 0;
        let match;

        // Split text and wrap matches in highlight spans
        while ((match = regex.exec(text)) !== null) {
            // Add text before match
            if (match.index > lastIndex) {
                fragment.appendChild(document.createTextNode(text.substring(lastIndex, match.index)));
            }

            // Add highlighted match
            const highlight = document.createElement('span');
            highlight.className = 'highlight';
            highlight.textContent = match[0];
            fragment.appendChild(highlight);

            lastIndex = regex.lastIndex;
        }

        // Add remaining text after last match
        if (lastIndex < text.length) {
            fragment.appendChild(document.createTextNode(text.substring(lastIndex)));
        }

        // Replace the text node with the fragment
        parentNode.replaceChild(fragment, node);
    } else if (node.nodeType === Node.ELEMENT_NODE) {
        // Skip if already processed
        if (node.classList && node.classList.contains('highlight')) {
            return;
        }
        // Recursively process child nodes of elements
        Array.from(node.childNodes).forEach(highlightTextInNode);
    }
}

// Function to recursively highlight text inside shadow DOMs
function highlightInShadowRoot(shadowRoot) {
    // Add highlight styles to shadow DOM (needed because of style encapsulation)
    let styleEl = shadowRoot.querySelector('style.highlight-styles');
    if (!styleEl) {
        styleEl = document.createElement('style');
        styleEl.className = 'highlight-styles';
        styleEl.textContent = '.highlight { background-color: rgb(246, 166, 35); }';
        shadowRoot.appendChild(styleEl);
    }

    // Process all text-containing elements in shadow DOM (not just <p> tags)
    const textContainers = shadowRoot.querySelectorAll("span, p, div, a, td, th, li");
    textContainers.forEach(el => {
        highlightTextInNode(el);  // Process the element and all its descendants recursively
    });

    // If no specific text containers found, process the shadow root's body directly
    if (textContainers.length === 0 && shadowRoot.children.length > 0) {
        Array.from(shadowRoot.children).forEach(child => {
            if (child.nodeType === Node.ELEMENT_NODE) {
                highlightTextInNode(child);
            }
        });
    }

    // Recurse into nested shadow roots
    shadowRoot.querySelectorAll("*").forEach(el => {
        if (el.shadowRoot) {
            highlightInShadowRoot(el.shadowRoot);
        }
    });
}

// Function to search and highlight in all p tags (and text nodes) in the light DOM
function highlightInLightDOM() {
    document.querySelectorAll("p").forEach(p => {
        highlightTextInNode(p);  // Process the paragraph and all its descendants recursively
    });

    document.querySelectorAll("*").forEach(el => {
        if (el.shadowRoot) {
            highlightInShadowRoot(el.shadowRoot);  // Recurse into shadow roots
        }
    });
}

// Initialize the highlighting in the light DOM only if there's a query parameter
if (q && q.trim() !== "") {
    // Wait for custom elements to be fully initialized before highlighting
    const runHighlighting = () => {
        // Use requestAnimationFrame to wait for the next render cycle
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                highlightInLightDOM();
            });
        });
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', runHighlighting);
    } else {
        runHighlighting();
    }
}



let currentMatchIndex = -1;
const matches = [];

function highlightMatches(key) {
  // Reset previous highlights and matches
  // document.querySelectorAll(".highlight").forEach((el) => {
  // el.classList.remove("highlight");
  // el.removeAttribute("tabindex");
  //});
  matches.length = 0;
  currentMatchIndex = -1;

  // Find and highlight new matches
  document.querySelectorAll(`[id="#${key}"]`).forEach((el) => {
    el.classList.add("highlight");
    el.setAttribute("tabindex", "0");
    el.setAttribute("aria-label", `Match ${matches.length + 1} for ${key}`);
    matches.push(el);
  });

  // Set focus to the first match
  if (matches.length > 0) {
    currentMatchIndex = 0;
    matches[0].focus();
  }
}

document.addEventListener("custom-checkbox-change", (e) => {
  const key = e.target.getAttribute("key");
  if (e.target.checkboxSpan.ariaChecked === "true") {
    highlightMatches(key);
  } else {
    document.querySelectorAll(`[id="#${key}"]`).forEach((el) => {
      el.classList.remove("highlight");
      el.removeAttribute("tabindex");
    });
    matches.length = 0;
    currentMatchIndex = -1;
  }
});

document.addEventListener("keydown", (e) => {
  if (e.key === "ArrowRight") {
    e.preventDefault();
    if (matches.length > 0) {
      currentMatchIndex = (currentMatchIndex + 1) % matches.length;
      matches[currentMatchIndex].focus();
    }
  } else if (e.key === "ArrowLeft") {
    e.preventDefault();
    if (matches.length > 0) {
      currentMatchIndex =
        (currentMatchIndex - 1 + matches.length) % matches.length;
      matches[currentMatchIndex].focus();
    }
  }
});
