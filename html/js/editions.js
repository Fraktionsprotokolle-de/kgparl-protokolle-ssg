// Get the query parameter "q" from the URL
var urlParams = new URLSearchParams(window.location.search);
var q = urlParams.get("q");

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

    // Highlight in shadow DOMs (like popup-info elements)
    document.querySelectorAll("popup-info, custom-checkbox, *").forEach(el => {
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
                // Scroll to first highlight match
                var firstHighlight = document.querySelector('.highlight');
                if (firstHighlight) {
                    firstHighlight.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
            });
        });
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', runHighlighting);
    } else {
        runHighlighting();
    }
}

// Show keyword badge when arriving from keyword detail page (?keyword=...)
var keywordParam = urlParams.get("keyword");
if (keywordParam && keywordParam.trim() !== "") {
    var badge = document.createElement('div');
    badge.className = 'keyword-context-badge';
    badge.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>' +
        '<span>Schlagwort: <strong>' + keywordParam.replace(/</g, '&lt;') + '</strong></span>';
    var header = document.querySelector('.page-header') || document.querySelector('h1');
    if (header) {
        header.parentNode.insertBefore(badge, header.nextSibling);
    }
}

// Highlight person mentions and activate facette checkbox
// Supports ?person=ID (from person detail page) and ?personName=Name (from protocol list)
var personParam = urlParams.get("person");
var personNameParam = urlParams.get("personName");

// Helper: activate a custom-checkbox by clicking its shadow DOM container
function activateCheckbox(checkbox) {
  if (!checkbox) return;
  // If checkbox is inside a hidden overflow item, show it first
  var parentLi = checkbox.closest('.facet-overflow.hidden');
  if (parentLi) parentLi.classList.remove('hidden');
  var inner = checkbox.shadowRoot && checkbox.shadowRoot.querySelector('input.checkbox');
  var isChecked = inner && inner.getAttribute('aria-checked') === 'true';
  if (!isChecked) {
    var container = checkbox.shadowRoot.querySelector('.checkbox-container');
    if (container) {
      container.click();
    } else {
      checkbox.toggle();
    }
  }
}

// Helper: highlight person mentions by ID and scroll to first
function highlightPersonById(personId) {
  var selector = '[id="#' + CSS.escape(personId) + '"]';
  var mentions = document.querySelectorAll(selector);
  if (mentions.length === 0) {
    selector = '[id="' + CSS.escape(personId) + '"]';
    mentions = document.querySelectorAll(selector);
  }
  if (mentions.length > 0) {
    for (var i = 0; i < mentions.length; i++) {
      mentions[i].classList.add('person-highlight');
    }
    mentions[0].scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
}

// Helper: find custom-checkbox by display name (text content starts with name)
function findCheckboxByName(name) {
  var checkboxes = document.querySelectorAll('custom-checkbox');
  for (var i = 0; i < checkboxes.length; i++) {
    // Text content is "Surname, Forename (count)" — match the name part
    var text = checkboxes[i].textContent.trim();
    if (text.startsWith(name + ' (') || text.startsWith(name + '(') || text === name) {
      return checkboxes[i];
    }
  }
  return null;
}

if (personParam && personParam.trim() !== "") {
  document.addEventListener('DOMContentLoaded', function() {
    highlightPersonById(personParam);

    // Activate the person facette checkbox in sidebar
    customElements.whenDefined('custom-checkbox').then(function() {
      setTimeout(function() {
        var checkbox = document.querySelector('custom-checkbox[key="' + personParam + '"]');
        activateCheckbox(checkbox);
      }, 100);
    });
  });
} else if (personNameParam && personNameParam.trim() !== "") {
  document.addEventListener('DOMContentLoaded', function() {
    // Wait for custom-checkbox to be defined and rendered
    customElements.whenDefined('custom-checkbox').then(function() {
      setTimeout(function() {
        // Find checkbox by display name to get the person ID
        var checkbox = findCheckboxByName(personNameParam);
        if (checkbox) {
          var personId = checkbox.getAttribute('key');
          // Highlight mentions using the resolved ID
          if (personId) {
            highlightPersonById(personId);
          }
          // Activate the checkbox
          activateCheckbox(checkbox);
        }
      }, 100);
    });
  });
}

var currentMatchIndex = -1;
var matches = [];

// Store original positions of list items
var listItemOriginalPositions = new Map();

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

  // Auto-open collapsed <details> if matches are inside
  matches.forEach((el) => {
    const details = el.closest("details:not([open])");
    if (details) {
      details.open = true;
    }
  });

  // Set focus to the first match
  if (matches.length > 0) {
    currentMatchIndex = 0;
    matches[0].focus();
  }
}

function bubbleListItem(listItem, isChecked) {
  const ul = listItem.parentElement;
  const checkbox = listItem.querySelector('custom-checkbox');

  // Preserve the checked state before moving
  const checkboxSpan = checkbox ? checkbox.shadowRoot.querySelector("input.checkbox") : null;
  const currentCheckedState = checkboxSpan ? checkboxSpan.getAttribute("aria-checked") : "false";

  if (isChecked) {
    // Store original position if not already stored
    if (!listItemOriginalPositions.has(listItem)) {
      const siblings = Array.from(ul.children);
      const originalIndex = siblings.indexOf(listItem);
      listItemOriginalPositions.set(listItem, {
        index: originalIndex,
        nextSibling: listItem.nextSibling
      });
    }

    // Move to the top
    // Find the first unchecked item or insert at the very beginning
    let insertBefore = null;
    for (let child of ul.children) {
      const cb = child.querySelector('custom-checkbox');
      if (cb) {
        const cbSpan = cb.shadowRoot.querySelector("input.checkbox");
        if (cbSpan && cbSpan.getAttribute("aria-checked") !== "true") {
          insertBefore = child;
          break;
        }
      }
    }

    if (insertBefore) {
      ul.insertBefore(listItem, insertBefore);
    } else {
      ul.appendChild(listItem);
    }
  } else {
    // Return to original position
    const originalPos = listItemOriginalPositions.get(listItem);
    if (originalPos) {
      if (originalPos.nextSibling && originalPos.nextSibling.parentElement === ul) {
        ul.insertBefore(listItem, originalPos.nextSibling);
      } else {
        // If nextSibling doesn't exist, it was the last item
        ul.appendChild(listItem);
      }
      listItemOriginalPositions.delete(listItem);
    }
  }

  // Restore the checked state after moving (connectedCallback resets it)
  // Use requestAnimationFrame to ensure this runs after connectedCallback completes
  if (currentCheckedState === "true") {
    requestAnimationFrame(() => {
      const cbSpan = checkbox ? checkbox.shadowRoot.querySelector("input.checkbox") : null;
      if (cbSpan) {
        cbSpan.setAttribute("aria-checked", "true");
        // Update the visual style
        if (checkbox.updateStyle) {
          checkbox.updateStyle();
        }
      }
    });
  }
}

document.addEventListener("custom-checkbox-change", (e) => {
  const key = e.target.getAttribute("key");
  const checkbox = e.target;

  // Use the event detail which contains the correct checked state
  const isChecked = e.detail.checked;

  // Find the parent li element
  const listItem = checkbox.closest('li');

  if (isChecked) {
    highlightMatches(key);
    // Defer DOM manipulation to let the custom element finish its toggle
    if (listItem) {
      setTimeout(() => bubbleListItem(listItem, true), 0);
    }
  } else {
    document.querySelectorAll(`[id="#${key}"]`).forEach((el) => {
      el.classList.remove("highlight");
      el.removeAttribute("tabindex");
    });
    matches.length = 0;
    currentMatchIndex = -1;
    // Defer DOM manipulation to let the custom element finish its toggle
    if (listItem) {
      setTimeout(() => bubbleListItem(listItem, false), 0);
    }
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

// Hash navigation support for elements inside shadow DOM
function findElementById(id) {
  // First try light DOM by id
  let element = document.getElementById(id);
  if (element) return element;

  // Also try name attribute (legacy anchor support for footnotes)
  element = document.querySelector(`a[name="${CSS.escape(id)}"]`);
  if (element) return element;

  // Search inside all shadow roots
  const allElements = document.querySelectorAll('*');
  for (let el of allElements) {
    if (el.shadowRoot) {
      element = el.shadowRoot.getElementById(id);
      if (element) return element;

      const found = el.shadowRoot.querySelector(`#${CSS.escape(id)}`);
      if (found) return found;
    }
  }

  return null;
}

function scrollToHash(hash) {
  if (!hash) return;

  // Remove the # prefix
  const id = hash.substring(1);

  // Find element in light DOM or shadow DOM
  let element = findElementById(id);

  if (element) {
    // If element is inside a web component (slotted content),
    // scroll to the host element instead
    let scrollTarget = element;

    // Check if element is a child of a custom element (web component)
    const hostElement = element.closest('popup-info, custom-checkbox');
    if (hostElement) {
      // Element is slotted content inside a web component
      // Scroll to the host element instead
      scrollTarget = hostElement;
    }

    // Also check if we found it in shadow DOM - if so, use the host
    if (element.getRootNode() && element.getRootNode() !== document) {
      const shadowRoot = element.getRootNode();
      if (shadowRoot.host) {
        scrollTarget = shadowRoot.host;
      }
    }

    scrollTarget.scrollIntoView({ behavior: 'smooth', block: 'center' });

    // Try to focus if possible
    if (element.tabIndex >= 0 || element.tagName === 'A') {
      element.focus();
    }

    // Add a temporary highlight to the host element
    const originalBg = scrollTarget.style.backgroundColor;
    const originalOutline = scrollTarget.style.outline;
    scrollTarget.style.backgroundColor = 'rgba(246, 166, 35, 0.3)';
    scrollTarget.style.outline = '2px solid rgb(246, 166, 35)';
    setTimeout(() => {
      scrollTarget.style.backgroundColor = originalBg;
      scrollTarget.style.outline = originalOutline;
    }, 2000);
  }
}

// Handle hash on page load
window.addEventListener('DOMContentLoaded', () => {
  if (window.location.hash) {
    // Delay to ensure shadow DOMs are created
    setTimeout(() => scrollToHash(window.location.hash), 100);
  }
});

// Handle hash changes
window.addEventListener('hashchange', () => {
  scrollToHash(window.location.hash);
});

// Intercept clicks on hash links
document.addEventListener('click', (e) => {
  const link = e.target.closest('a[href^="#"]');
  if (link) {
    const hash = link.getAttribute('href');
    if (hash && hash !== '#') {
      e.preventDefault();
      window.location.hash = hash;
      scrollToHash(hash);
    }
  }
}, true); // Use capture phase to catch clicks in shadow DOM

// Seg-Highlight: ganzen Notenbereich hervorheben bei Hover auf Fußnotennummer
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.seg-note.fn').forEach(fnSpan => {
    const segment = fnSpan.closest('.note-segment');
    if (!segment) return;

    fnSpan.addEventListener('mouseenter', () => {
      segment.classList.add('fn-highlighted');
    });
    fnSpan.addEventListener('mouseleave', () => {
      segment.classList.remove('fn-highlighted');
    });
  });
});

// Copy as plain text
document.addEventListener('DOMContentLoaded', () => {
  const copyBtn = document.getElementById('copy-plaintext-btn');
  if (!copyBtn) return;

  function showCopyFeedback() {
    const span = copyBtn.querySelector('span');
    const original = span ? span.textContent : copyBtn.textContent;
    if (span) {
      span.textContent = (typeof i18next !== 'undefined' && i18next.t) ? i18next.t('edition.copied') : 'Kopiert!';
    } else {
      copyBtn.textContent = (typeof i18next !== 'undefined' && i18next.t) ? i18next.t('edition.copied') : 'Kopiert!';
    }
    copyBtn.classList.add('copy-success');
    setTimeout(() => {
      if (span) span.textContent = original;
      else copyBtn.textContent = original;
      copyBtn.classList.remove('copy-success');
    }, 2000);
  }

  function copyToClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).then(showCopyFeedback);
    }
    var textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand('copy');
      showCopyFeedback();
    } finally {
      document.body.removeChild(textarea);
    }
  }

  // Extract text from a node, resolving Shadow DOM (popup-info) to get person names
  function extractText(node) {
    if (node.nodeType === Node.TEXT_NODE) return node.textContent;
    if (node.nodeType !== Node.ELEMENT_NODE) return '';

    // popup-info: get text from light DOM (the visible person name)
    if (node.tagName && node.tagName.toLowerCase() === 'popup-info') {
      // Light DOM children contain the original person name text
      var text = '';
      for (var i = 0; i < node.childNodes.length; i++) {
        text += extractText(node.childNodes[i]);
      }
      return text;
    }

    var result = '';
    var tag = node.tagName ? node.tagName.toLowerCase() : '';
    var isBlock = /^(p|div|h[1-6]|li|br|hr|tr|details|summary|dt|dd|blockquote|pre|section|article)$/.test(tag);

    for (var i = 0; i < node.childNodes.length; i++) {
      result += extractText(node.childNodes[i]);
    }

    if (tag === 'br') return '\n';
    if (isBlock && result.length > 0) return '\n' + result + '\n';
    return result;
  }

  // Clean up whitespace: collapse tabs/spaces, limit blank lines
  function normalizeWhitespace(text) {
    return text.replace(/[\t ]+/g, ' ').replace(/ *\n */g, '\n').replace(/\n{3,}/g, '\n\n').trim();
  }

  copyBtn.addEventListener('click', () => {
    var content = document.getElementById('content-container');
    if (!content) return;

    var parts = [];
    var sitzungsInfo = document.getElementById('sitzungs-info');

    if (sitzungsInfo) {
      // Titel (h2): z.B. "CDU/CSU (7. WP)"
      var h2 = sitzungsInfo.querySelector('h2');
      if (h2) parts.push(h2.innerText.trim());

      // Datum + Dokumenttitel aus erstem details > summary
      var firstDetails = sitzungsInfo.querySelector('details');
      if (firstDetails) {
        var summary = firstDetails.querySelector('summary');
        if (summary) parts.push(summary.innerText.trim());
        // Zitierempfehlungen / Info-Block (details may be closed)
        var infoBlock = firstDetails.querySelector('.info-block');
        if (infoBlock) parts.push(normalizeWhitespace(infoBlock.textContent));
      }

      parts.push('');

      // Sitzungsverlauf (details may be closed, so use textContent)
      var svDetail = document.getElementById('sitzungsverlauf');
      if (svDetail) {
        var svSummary = svDetail.querySelector('summary');
        if (svSummary) parts.push(svSummary.textContent.trim());
        var svList = svDetail.querySelector('ol, ul');
        if (svList) {
          var items = svList.querySelectorAll('li');
          for (var i = 0; i < items.length; i++) {
            parts.push((i + 1) + '. ' + items[i].textContent.trim());
          }
        }
        parts.push('');
      }

      // Anwesenheitsliste (details may be closed)
      var alDetail = document.getElementById('anwesenheitsliste');
      if (alDetail) {
        var alSummary = alDetail.querySelector('summary');
        if (alSummary) parts.push(alSummary.textContent.trim());
        var alBlock = alDetail.querySelector('.info-block');
        if (alBlock) parts.push(normalizeWhitespace(alBlock.textContent));
        parts.push('');
      }
    }

    // Protokolltext inkl. Personen aus Shadow DOM
    parts.push(normalizeWhitespace(extractText(content)));

    copyToClipboard(parts.join('\n'));
  });
});

// Download Dropdown
document.addEventListener('DOMContentLoaded', () => {
  const dropdowns = document.querySelectorAll('.download-dropdown');

  dropdowns.forEach(dropdown => {
    const toggle = dropdown.querySelector('.download-toggle');

    if (toggle) {
      toggle.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();

        // Close other dropdowns
        dropdowns.forEach(d => {
          if (d !== dropdown) {
            d.classList.remove('open');
            d.querySelector('.download-toggle')?.setAttribute('aria-expanded', 'false');
          }
        });

        // Toggle this dropdown
        const isOpen = dropdown.classList.toggle('open');
        toggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      });
    }
  });

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.download-dropdown')) {
      dropdowns.forEach(dropdown => {
        dropdown.classList.remove('open');
        dropdown.querySelector('.download-toggle')?.setAttribute('aria-expanded', 'false');
      });
    }
  });

  // Close dropdown on Escape
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      dropdowns.forEach(dropdown => {
        dropdown.classList.remove('open');
        dropdown.querySelector('.download-toggle')?.setAttribute('aria-expanded', 'false');
      });
    }
  });
});

// Breadcrumb links: set href dynamically using collection name from config
document.querySelectorAll('a.breadcrumb-party').forEach(function(el) {
  var col = typeof TYPESENSE_COLLECTIONS !== 'undefined' ? TYPESENSE_COLLECTIONS.protocols : 'kgparl';
  el.href = 'liste.html?' + col + '[refinementList][party][0]=' + encodeURIComponent(el.dataset.party);
});
document.querySelectorAll('a.breadcrumb-period').forEach(function(el) {
  var col = typeof TYPESENSE_COLLECTIONS !== 'undefined' ? TYPESENSE_COLLECTIONS.protocols : 'kgparl';
  el.href = 'liste.html?' + col + '[refinementList][party][0]=' + encodeURIComponent(el.dataset.party)
    + '&' + col + '[refinementList][period][0]=' + encodeURIComponent(el.dataset.period);
});

// ============ Keyword highlight toggle ============
(function() {
  var toggle = document.getElementById('keyword-toggle');
  if (!toggle) return;

  var STORAGE_KEY = 'keyword-highlights';
  // Restore saved preference
  var saved = localStorage.getItem(STORAGE_KEY);
  if (saved === 'off') {
    toggle.checked = false;
    document.querySelectorAll('.keyword-ref').forEach(function(el) {
      el.classList.add('keyword-hidden');
    });
  }

  toggle.addEventListener('change', function() {
    var refs = document.querySelectorAll('.keyword-ref');
    if (this.checked) {
      refs.forEach(function(el) { el.classList.remove('keyword-hidden'); });
      localStorage.setItem(STORAGE_KEY, 'on');
    } else {
      refs.forEach(function(el) { el.classList.add('keyword-hidden'); });
      localStorage.setItem(STORAGE_KEY, 'off');
    }
  });
})();
