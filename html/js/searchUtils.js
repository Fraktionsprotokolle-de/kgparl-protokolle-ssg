/**
 * searchUtils.js — Shared search utilities for all search pages
 *
 * Provides:
 *   - parseQuery()       — Parse NOT / - operators from search queries
 *   - fetchIDsForTerm()  — Fetch all document IDs matching a term from Typesense
 *   - fetchExcludeIDs()  — Fetch IDs to exclude for NOT operators
 *   - createQueryHook()  — Create a queryHook for InstantSearch searchBox widgets
 *
 * External dependencies (must be loaded before this file):
 *   - js/config.js (TYPESENSE_CONFIG)
 */

/** Safe i18n translation with fallback. Returns translated string or fallback if i18next not ready. */
function t(key, fallback) {
  try {
    if (typeof i18next !== 'undefined' && i18next.isInitialized) {
      var result = i18next.t(key);
      if (result && result !== key) return result;
    }
  } catch(e) {}
  return fallback !== undefined ? fallback : key;
}

/**
 * Returns a Promise that resolves when i18next is initialized.
 * If already initialized, resolves immediately.
 * Falls back after 3 seconds to avoid blocking if i18next never loads.
 */
function waitForI18n() {
  return new Promise(function(resolve) {
    if (typeof i18next !== 'undefined' && i18next.isInitialized) {
      resolve();
      return;
    }
    if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
      var resolved = false;
      i18next.on('initialized', function() {
        if (!resolved) { resolved = true; resolve(); }
      });
      // Fallback timeout in case event was already fired
      setTimeout(function() {
        if (!resolved) { resolved = true; resolve(); }
      }, 3000);
    } else {
      // i18next not available at all — resolve immediately with fallbacks
      resolve();
    }
  });
}

/**
 * Parse a search query for NOT / - operators.
 * Returns { positive: string, negatives: string[] }
 *
 * Examples:
 *   "Solar NOT Solartechnik"        → { positive: "Solar", negatives: ["Solartechnik"] }
 *   'Solar -Tech -PV'               → { positive: "Solar", negatives: ["Tech", "PV"] }
 *   '"Berliner Mauer" NOT Grenze'   → { positive: '"Berliner Mauer"', negatives: ["Grenze"] }
 *   'Solar NOT "erneuerbare Energie"'→ { positive: "Solar", negatives: ["erneuerbare Energie"] }
 */
function parseQuery(query) {
  const negatives = [];
  let working = query;

  // Extract NOT "phrase" and NOT term patterns
  working = working.replace(/\bNOT\s+"([^"]+)"/g, (_, phrase) => {
    negatives.push(phrase);
    return '';
  });
  working = working.replace(/\bNOT\s+(\S+)/g, (_, term) => {
    negatives.push(term);
    return '';
  });

  // Extract -"phrase" and -term patterns (dash prefix, no space before term)
  working = working.replace(/(?:^|\s)-"([^"]+)"/g, (_, phrase) => {
    negatives.push(phrase);
    return '';
  });
  working = working.replace(/(?:^|\s)-(\S+)/g, (match, term) => {
    negatives.push(term);
    return '';
  });

  const positive = working.replace(/\s+/g, ' ').trim();
  return { positive, negatives };
}

/**
 * Fetch all document IDs matching a single term from Typesense.
 * Paginates automatically (250 IDs per page) until all results are loaded.
 *
 * @param {string} term       — Search term (single word or "phrase in quotes")
 * @param {string} collection — Typesense collection name
 * @param {string} queryBy    — Comma-separated list of fields to search
 * @returns {Promise<string[]>} — Array of document IDs
 */
async function fetchIDsForTerm(term, collection, queryBy) {
  const baseUrl = `${TYPESENSE_CONFIG.protocol}://${TYPESENSE_CONFIG.host}:${TYPESENSE_CONFIG.port}`;
  const allIDs = [];
  let page = 1;

  while (true) {
    const params = new URLSearchParams({
      q: term,
      query_by: queryBy,
      include_fields: 'id',
      per_page: '250',
      page: String(page),
    });
    const resp = await fetch(`${baseUrl}/collections/${collection}/documents/search?${params}`, {
      headers: { 'X-TYPESENSE-API-KEY': TYPESENSE_CONFIG.apiKey },
    });
    if (!resp.ok) break;
    const data = await resp.json();
    if (!data.hits || data.hits.length === 0) break;
    for (const hit of data.hits) {
      if (hit.document?.id) allIDs.push(hit.document.id);
    }
    if (allIDs.length >= (data.found || 0)) break;
    page++;
  }
  return allIDs;
}

/**
 * Fetch document IDs to exclude for NOT operators.
 * Searches each negative term separately in Typesense (in parallel), deduplicates IDs.
 * On error, gracefully returns [] (search works without NOT).
 *
 * @param {string[]} negatives  — Array of terms to exclude
 * @param {string}   collection — Typesense collection name
 * @param {string}   queryBy    — Comma-separated list of fields to search
 * @returns {Promise<string[]>} — Deduplicated IDs of documents to exclude
 */
async function fetchExcludeIDs(negatives, collection, queryBy) {
  if (!negatives || negatives.length === 0) return [];
  try {
    const results = await Promise.all(negatives.map(t => fetchIDsForTerm(t, collection, queryBy)));
    const seen = new Set();
    const allIDs = [];
    for (const ids of results) {
      for (const id of ids) {
        if (!seen.has(id)) {
          seen.add(id);
          allIDs.push(id);
        }
      }
    }
    return allIDs;
  } catch {
    return [];
  }
}

/**
 * Add a custom clear (X) button inside the InstantSearch search input.
 * Call this after InstantSearch has rendered (e.g. in search.on('render', ...)).
 *
 * @param {string} [containerSelector='.list-searchbox'] — CSS selector for the searchbox container
 */
function setupSearchClearButton(containerSelector) {
  var container = document.querySelector(containerSelector || '.list-searchbox');
  if (!container || container.querySelector('.search-clear-btn')) return;

  var input = container.querySelector('.ais-SearchBox-input');
  if (!input) return;

  // Wrap input in a positioning container
  var wrapper = document.createElement('div');
  wrapper.className = 'search-input-wrapper';
  input.parentNode.insertBefore(wrapper, input);
  wrapper.appendChild(input);

  // Create clear button
  var btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'search-clear-btn';
  btn.setAttribute('aria-label', 'Suche zurücksetzen');
  btn.innerHTML = '&#x2715;'; // × symbol
  wrapper.appendChild(btn);

  // Show/hide based on input value
  function toggleVisibility() {
    if (input.value.length > 0) {
      btn.classList.add('visible');
    } else {
      btn.classList.remove('visible');
    }
  }

  input.addEventListener('input', toggleVisibility);
  toggleVisibility();

  // Clear input and trigger InstantSearch refine
  btn.addEventListener('click', function() {
    // Use the native setter to trigger React/InstantSearch change detection
    var nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
    nativeInputValueSetter.call(input, '');
    input.dispatchEvent(new Event('input', { bubbles: true }));
    btn.classList.remove('visible');
    input.focus();
  });

  // Observe for InstantSearch re-renders that might change the input value
  var observer = new MutationObserver(function() {
    toggleVisibility();
  });
  observer.observe(container, { childList: true, subtree: true });
}

/**
 * Create a queryHook for InstantSearch searchBox widgets that supports NOT operators.
 *
 * @param {string} collection              — Typesense collection name
 * @param {string} queryBy                 — Comma-separated list of fields to search
 * @param {object} additionalSearchParameters — Reference to the adapter's additionalSearchParameters
 * @returns {function} queryHook function
 */
/**
 * Check if input looks like a protocol XML-ID and navigate if it exists in Typesense.
 * Returns true if navigation was attempted (caller should return early), false otherwise.
 */
function tryDirectNavigation(query, collection, refine) {
  var trimmed = query.trim();
  if (!/^[a-z]+-\d{2}_\d{4}-\d{2}-\d{2}/.test(trimmed)) return false;

  var baseUrl = TYPESENSE_CONFIG.protocol + '://' + TYPESENSE_CONFIG.host + ':' + TYPESENSE_CONFIG.port;
  fetch(baseUrl + '/collections/' + collection + '/documents/' + encodeURIComponent(trimmed), {
    headers: { 'X-TYPESENSE-API-KEY': TYPESENSE_CONFIG.apiKey }
  }).then(function(resp) {
    if (resp.ok) {
      window.location.href = trimmed + '.html';
    } else {
      // Not found — fall through to normal search
      refine(trimmed);
    }
  }).catch(function() {
    refine(trimmed);
  });
  return true;
}

function createQueryHook(collection, queryBy, additionalSearchParameters) {
  return function queryHook(query, refine) {
    if (tryDirectNavigation(query, collection, refine)) return;

    const { positive, negatives } = parseQuery(query);

    if (negatives.length === 0) {
      delete additionalSearchParameters.filter_by;
      refine(positive);
      return;
    }

    fetchExcludeIDs(negatives, collection, queryBy).then(excludeIds => {
      if (excludeIds.length > 0) {
        additionalSearchParameters.filter_by = 'id:!=[' + excludeIds.map(id => '`' + id + '`').join(',') + ']';
      } else {
        delete additionalSearchParameters.filter_by;
      }
      refine(positive);
    });
  };
}
