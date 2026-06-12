// ======= UncommentrchAdapter from "typesense-instantsearch-adapter";
let dictionary = {};
dictionary["01"] = "1949 - 1953";
dictionary["02"] = "1953 - 1957";
dictionary["03"] = "1957 - 1961";
dictionary["04"] = "1961 - 1965";
dictionary["05"] = "1965 - 1969";
dictionary["06"] = "1969 - 1972";
dictionary["07"] = "1972 - 1976";
dictionary["08"] = "1976 - 1980";
dictionary["09"] = "1980 - 1983";
dictionary["10"] = "1983 - 1987";
dictionary["11"] = "1987 - 1990";
dictionary["12"] = "1990 - 1994";
dictionary["13"] = "1994 - 1998";
dictionary["14"] = "1998 - 2002";
dictionary["15"] = "2002 - 2005";

// Format ISO date (YYYY-MM-DD) to German format (DD.MM.YYYY)
var formatDateDE = (isoDate) => {
  if (!isoDate) return "";
  var parts = String(isoDate).split("-");
  if (parts.length === 3) return `${parts[2]}.${parts[1]}.${parts[0]}`;
  return isoDate;
};

// Track visited rows in session storage
var VISITED_KEY = "visited_rows";

// Get visited rows from session storage
var getVisitedRows = () => {
  try {
    var visited = sessionStorage.getItem(VISITED_KEY);
    return visited ? JSON.parse(visited) : [];
  } catch (e) {
    return [];
  }
};

// Add a row to visited list
var markRowAsVisited = (href) => {
  var visited = getVisitedRows();
  if (!visited.includes(href)) {
    visited.push(href);
    sessionStorage.setItem(VISITED_KEY, JSON.stringify(visited));
  }
};

// Check if a row has been visited
var isRowVisited = (href) => {
  return getVisitedRows().includes(href);
};

// Create the render function
var renderHits = (renderOptions, isFirstRender) => {
  var { items, widgetParams, results } = renderOptions;

  if (items.length === 0) {
    widgetParams.container.innerHTML = `
      <div class="search-empty" style="text-align: center; padding: 2rem;">
        <h3>${t('hits.noResults')}</h3>
        <p>${t('hits.noResultsHintFilters')}</p>
      </div>`;
    return;
  }

  let currentAttribute = "year";
  let currentDirection = "asc";

  // Get current sort state from the search instance UI state
  var currentUiState = search.getUiState();
  var currentSortBy = currentUiState[TYPESENSE_COLLECTIONS.protocols]?.sortBy || TYPESENSE_COLLECTIONS.protocols;

  // Parse current sort from index name
  if (currentSortBy.includes("/sort/")) {
    var sortPart = currentSortBy.split("/sort/")[1];
    var [attribute, direction] = sortPart.split(":");
    currentAttribute = attribute;
    currentDirection = direction;
  }

  // Helper function to render sort indicator
  var getSortIndicator = (attribute) => {
    if (currentAttribute === attribute) {
      var directionClass =
        currentDirection === "asc"
          ? "sort-indicator-asc"
          : "sort-indicator-desc";
      var srText = currentDirection === "asc" ? t('sort.sortedAsc') : t('sort.sortedDesc');
      return ` <span class="sort-indicator ${directionClass}" aria-hidden="true"></span><span class="sr-only">, ${srText}</span>`;
    }
    return ' <span class="sort-indicator-neutral" aria-hidden="true"><span class="sort-arrow sort-arrow-up"></span><span class="sort-arrow sort-arrow-down"></span></span>';
  };

  // Helper for aria-sort attribute
  var getAriaSort = (attribute) => {
    if (currentAttribute === attribute) {
      return currentDirection === "asc" ? "ascending" : "descending";
    }
    return "none";
  };

  widgetParams.container.innerHTML = `
    <table class="table table-striped table-hover" id="toc-table">
      <thead>
        <tr>
          <th data-sort-attribute="party" scope="col" tabindex="0" role="columnheader" aria-sort="${getAriaSort("party")}" style="cursor: pointer; user-select: none;">${t('table.faction')}${getSortIndicator("party")}</th>
          <th data-sort-attribute="period" scope="col" tabindex="0" role="columnheader" aria-sort="${getAriaSort("period")}" class="hide-on-mobile" style="cursor: pointer; user-select: none;">${t('table.period')}${getSortIndicator("period")}</th>
          <th scope="col" style="cursor: default;">${t('table.title')}</th>
          <th data-sort-attribute="date" scope="col" tabindex="0" role="columnheader" aria-sort="${getAriaSort("date")}" class="hide-on-small" style="cursor: pointer; user-select: none;">${t('table.date')}${getSortIndicator("date")}</th>
        </tr>
      </thead>
      <tbody>
        ${items
          .map((item) => {
            var href = `${item.id}.html`;
            var visitedClass = isRowVisited(href) ? "row-visited" : "";
            return `
          <tr data-href="${href}" class="${visitedClass}" style="cursor: pointer;" title="${t('table.openPage')}" tabindex="0" role="link">
              <td>${instantsearch.highlight({ attribute: "party", hit: item })}</td>
              <td class="hide-on-mobile">${instantsearch.highlight({ attribute: "period", hit: item })}</td>
              <td><a href="${href}" class="toc-row-link">${instantsearch.highlight({ attribute: "title", hit: item })}</a></td>
              <td class="hide-on-small">${formatDateDE(item.date)}</td>
            </tr>`;
          })
          .join("")}
      </tbody>
    </table>
  `;

  // Add click and keyboard event listeners to sortable headers
  var headers = widgetParams.container.querySelectorAll(
    "th[data-sort-attribute]",
  );
  headers.forEach((header) => {
    var sortHandler = () => {
      var attribute = header.getAttribute("data-sort-attribute");
      handleHeaderClick(attribute);
    };
    header.addEventListener("click", sortHandler);
    header.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); sortHandler(); }
    });
  });

  // Add click and keyboard event listeners to table rows
  var rows = widgetParams.container.querySelectorAll("tr[data-href]");
  rows.forEach((row) => {
    var navigateRow = (e) => {
      // Don't navigate if clicking on a link or other interactive element
      if (e.target.tagName === "A" || e.target.closest("a")) {
        return;
      }
      var href = row.getAttribute("data-href");
      markRowAsVisited(href);
      row.classList.add("row-visited");
      // Append person query parameter if a single person facet is selected
      var uiState = search.getUiState();
      var refinements = uiState[TYPESENSE_COLLECTIONS.protocols]?.refinementList?.persons;
      if (refinements && refinements.length === 1) {
        href += '?personName=' + encodeURIComponent(refinements[0]);
      }
      window.location.href = href;
    };
    row.addEventListener("click", navigateRow);
    row.addEventListener("keydown", (e) => {
      if (e.key === "Enter") { navigateRow(e); }
    });
  });
};

// Create the custom widget
var customHits = instantsearch.connectors.connectHits(renderHits);

window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;
var additionalSearchParameters = {
  query_by: "title, party, period, persons, full_text",
  sort_by: "date:asc, sitzungsabfolge:asc",
  num_typos: 0,
  // group_by: "categories",
  // group_limit: 1
  // pinned_hits: "23:2"
};

// Allow search params to be specified in the URL, for the test suite
var urlParams = new URLSearchParams(window.location.search);
["groupBy", "groupLimit", "pinnedHits", "sortBy"].forEach((attr) => {
  if (urlParams.has(attr)) {
    additionalSearchParameters[attr] = urlParams.get(attr);
  }
});

// Aktive Instanz (wird bei Sprachwechsel ersetzt)
var search = null;

// ============ Begin Widget Configuration
// Function to handle header click and trigger sorting
var handleHeaderClick = (attribute) => {
  // Get current sort state from the search instance
  var currentUiState = search.getUiState();
  var currentSortBy = currentUiState[TYPESENSE_COLLECTIONS.protocols]?.sortBy || TYPESENSE_COLLECTIONS.protocols;

  let currentAttribute = "year";
  let currentDirection = "asc";

  // Parse current sort
  if (currentSortBy.includes("/sort/")) {
    var sortPart = currentSortBy.split("/sort/")[1];
    var [attr, dir] = sortPart.split(":");
    currentAttribute = attr;
    currentDirection = dir;
  }

  // Determine new direction
  let newDirection = "asc";
  if (currentAttribute === attribute) {
    // Toggle direction if clicking the same column
    newDirection = currentDirection === "asc" ? "desc" : "asc";
  }

  // varruct the index name for sorting
  var indexName = `${TYPESENSE_COLLECTIONS.protocols}/sort/${attribute}:${newDirection}`;

  console.log(
    "Sorting:",
    attribute,
    newDirection,
    "Current:",
    currentAttribute,
    currentDirection,
  );

  // Trigger sorting using setUiState to properly sync with InstantSearch
  search.setUiState({
    [TYPESENSE_COLLECTIONS.protocols]: {
      ...search.getUiState()[TYPESENSE_COLLECTIONS.protocols],
      sortBy: indexName,
    },
  });
};

// Keyword filter from URL (?keyword=...)
var keywordParam = new URLSearchParams(window.location.search).get('keyword');

function initToc() {
  // Bei Neuinitialisierung: alte Instanz aufräumen
  if (search) {
    search.dispose();
  }

  // DOM-Container leeren
  document.querySelector('#searchbox').innerHTML = '';
  document.querySelector('#hits').innerHTML = '';
  document.querySelector('#pagination').innerHTML = '';
  document.querySelector('#hits-per-page').innerHTML = '';
  var periodList = document.querySelector('#period-list');
  if (periodList) periodList.innerHTML = '';
  var personList = document.querySelector('#person-list');
  if (personList) personList.innerHTML = '';
  var partyList = document.querySelector('#party-list');
  if (partyList) partyList.innerHTML = '';
  var clearRef = document.querySelector('#clear-refinements');
  if (clearRef) clearRef.innerHTML = '';
  var yearMenu = document.querySelector('#year-menu');
  if (yearMenu) yearMenu.innerHTML = '';

  // Neue InstantSearch-Instanz erstellen
  var typesenseInstantsearchAdapter = new TypesenseInstantSearchAdapter({
    server: {
      connectionTimeoutSeconds: 10000,
      apiKey: TYPESENSE_CONFIG.apiKey,
      nodes: [
        {
          host: TYPESENSE_CONFIG.host,
          port: TYPESENSE_CONFIG.port,
          protocol: TYPESENSE_CONFIG.protocol,
        },
      ],
    },
    additionalSearchParameters,
  });

  var instantSearchOpts = {
    searchClient: typesenseInstantsearchAdapter.searchClient,
    indexName: TYPESENSE_COLLECTIONS.protocols,
    routing: !keywordParam,
  };
  if (keywordParam) {
    // Filter by keyword tag (exact facet match), not full-text search
    additionalSearchParameters.filter_by = 'keywords:=`' + keywordParam.replace(/`/g, '') + '`';
  }
  search = instantsearch(instantSearchOpts);

  // If keyword filter is active: show badge instead of search box, hide syntax help
  if (keywordParam) {
    var searchboxEl = document.querySelector('#searchbox');
    searchboxEl.innerHTML = '<div class="keyword-filter-badge">' +
      '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex-shrink:0;"><path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>' +
      '<span class="keyword-filter-label">' + t('keywordRegister.keyword', 'Schlagwort') + ':</span> ' +
      '<span>' + keywordParam.replace(/</g, '&lt;') + '</span>' +
      '<button type="button" class="keyword-filter-remove" aria-label="Filter entfernen" title="Filter entfernen">&#x2715;</button>' +
      '</div>';
    searchboxEl.querySelector('.keyword-filter-remove').addEventListener('click', function() {
      keywordParam = null;
      delete additionalSearchParameters.filter_by;
      var url = new URL(window.location);
      url.searchParams.delete('keyword');
      window.history.replaceState({}, '', url);
      initToc();
      // Show syntax help again
      var syntaxHelp = document.querySelector('.search-syntax-help');
      if (syntaxHelp) syntaxHelp.style.display = '';
    });
    var syntaxHelp = document.querySelector('.search-syntax-help');
    if (syntaxHelp) syntaxHelp.style.display = 'none';
  }

  search.addWidgets([
  // Search box: hidden when keyword filter is active (query set via configure widget)
  instantsearch.widgets.searchBox({
    container: keywordParam ? document.createElement('div') : "#searchbox",
    placeholder: t('search.placeholderProtocols'),
    autofocus: true,
    showReset: false,
    showSubmit: false,
    cssClasses: {
      input: "form-control",
    },
    queryHook: createQueryHook(
      TYPESENSE_COLLECTIONS.protocols,
      additionalSearchParameters.query_by,
      additionalSearchParameters
    ),
  }),
  instantsearch.widgets.pagination({
    container: "#pagination",
    cssClasses: {
      link: "border-0 text-black fs-3",
    },
  }),

  // Hidden sortBy widget - needed for programmatic sorting via setUiState
  instantsearch.widgets.sortBy({
    container: document.createElement('div'), // Hidden container
    items: [
      { label: t('sort.year'), value: TYPESENSE_COLLECTIONS.protocols },
      { label: t('sort.yearDesc'), value: `${TYPESENSE_COLLECTIONS.protocols}/sort/year:desc` },
      { label: t('sort.period'), value: `${TYPESENSE_COLLECTIONS.protocols}/sort/period:asc` },
      { label: t('sort.periodDesc'), value: `${TYPESENSE_COLLECTIONS.protocols}/sort/period:desc` },
      { label: t('sort.faction'), value: `${TYPESENSE_COLLECTIONS.protocols}/sort/party:asc` },
      { label: t('sort.factionDesc'), value: `${TYPESENSE_COLLECTIONS.protocols}/sort/party:desc` },
      { label: t('sort.date'), value: `${TYPESENSE_COLLECTIONS.protocols}/sort/date:asc` },
      { label: t('sort.dateDesc'), value: `${TYPESENSE_COLLECTIONS.protocols}/sort/date:desc` },
    ],
  }),

  instantsearch.widgets.refinementList({
    container: document.querySelector("#period-list"),
    attribute: "period",
    operator: "or",
    showMore: false,
    limit: 15,
    showMoreLimit: 20,
    sortBy: function (a, b) {
      return parseInt(a.name, 10) - parseInt(b.name, 10);
    },
    transformItems(items) {
      // Ensure all 15 WP are always shown, even with 0 hits
      var allPeriods = Object.keys(dictionary);
      var existing = new Map(items.map(function(item) { return [item.value, item]; }));
      var result = allPeriods.map(function(period) {
        if (existing.has(period)) return existing.get(period);
        return { label: period, value: period, count: 0, isRefined: false, highlighted: period };
      });
      return result.sort(function(a, b) {
        return parseInt(a.value, 10) - parseInt(b.value, 10);
      });
    },
    templates: {
      item(data) {
        var { label, value, count, isRefined, cssClasses } = data;
        var displayLabel = `${label}. WP (${dictionary[label] || ""})`;
        var isDisabled = count === 0 && !isRefined;
        return `
          <label class="${cssClasses.label}${isDisabled ? ' facet-disabled' : ''}">
            <input type="checkbox"
                   class="${cssClasses.checkbox}"
                   value="${value}"
                   ${isRefined ? "checked" : ""}
                   ${isDisabled ? "disabled" : ""} />
            <span class="d-flex px-2 align-items-center text-black">${displayLabel}</span>
            <span class="${cssClasses.count}">${count}</span>
          </label>
        `;
      },
      showMoreText: ({ isShowingMore }, { html }) => {
        return isShowingMore ? html`${t('facets.showLess')}` : html`${t('facets.showMore')}`;
      },
    },

    cssClasses: {
      searchableInput: "form-control form-control-sm mb-2",
      searchableSubmit: "d-none",
      searchableReset: "",
      showMore: "kgparl-btn-outline",
      list: "list-unstyled",
      count: "badge counter ms-auto",
      label: "d-flex px-2 align-items-center text-black mb-1 me-4",
      checkbox: "mr-2",
    },
  }),
  instantsearch.widgets.clearRefinements({
    container: "#clear-refinements",
    templates: {
      resetLabel: t('facets.resetFilters'),
    },
    cssClasses: {
      button: "kgparl-btn-outline",
    },
  }),
  /*instantsearch.widgets.currentRefinements({
    container: "#current-refinements",
    cssClasses: {
      delete: "btn",
      label: "badge",
    },
  }),*/
  instantsearch.widgets.refinementList({
    container: "#person-list",
    attribute: "persons",
    searchable: true,
    searchablePlaceholder: t('facets.searchPersons', 'Suche nach Personen'),
    searchableIsAlwaysActive: true,
    operator: "and",
    showMore: true,
    showMoreLimit: 100,
    cssClasses: {
      searchableInput: "form-control form-control-sm mb-2",
      searchableSubmit: "d-none",
      searchableReset: "",
      showMore: "kgparl-btn-outline",
      list: "list-unstyled",
      count: "badge counter ms-auto",
      label: "d-flex px-2 align-items-center mb-1 me-4 text-black",
      checkbox: "mr-2",
    },
    templates: {
      showMoreText: ({ isShowingMore }, { html }) => {
        return isShowingMore ? html`${t('facets.showLess')}` : html`${t('facets.showMore')}`;
      },
    },
  }),
  instantsearch.widgets.refinementList({
    container: "#party-list",
    attribute: "party",
    limit: 10,
    operator: "or",
    searchableIsAlwaysActive: true,
    transformItems(items) {
      var allParties = ["CDU/CSU", "CSU-LG", "FDP", "Grüne", "PDS", "SPD"];
      var existing = new Map(items.map(function(item) { return [item.value, item]; }));
      var result = allParties.map(function(party) {
        if (existing.has(party)) return existing.get(party);
        return { label: party, value: party, count: 0, isRefined: false, highlighted: party };
      });
      return result;
    },
    cssClasses: {
      searchableInput: "form-control form-control-sm mb-2",
      searchableSubmit: "d-none",
      searchableReset: "",
      showMore: "kgparl-btn-outline",
      list: "list-unstyled",
      count: "badge counter ms-auto",
      label: "d-flex px-2 align-items-center mb-1 me-4 text-black",
      checkbox: "mr-2",
    },
    templates: {
      item(data) {
        var { label, value, count, isRefined, cssClasses } = data;
        var isDisabled = count === 0 && !isRefined;
        return `
          <label class="${cssClasses.label}${isDisabled ? ' facet-disabled' : ''}">
            <input type="checkbox"
                   class="${cssClasses.checkbox}"
                   value="${value}"
                   ${isRefined ? "checked" : ""}
                   ${isDisabled ? "disabled" : ""} />
            <span class="d-flex px-2 align-items-center text-black">${label}</span>
            <span class="${cssClasses.count}">${count}</span>
          </label>
        `;
      },
      showMoreText: ({ isShowingMore }, { html }) => {
        return isShowingMore ? html`${t('facets.showLess')}` : html`${t('facets.showMore')}`;
      },
    },
  }),
  instantsearch.widgets.rangeSlider({
    container: "#year-menu",
    attribute: "year",
    step: 1,
    pips: false,
  }),
  /* instantsearch.widgets.hits({
    container: "#hits",
    templates: {
      empty:
        "<tr><td class='text-center mt-5'><h3>Keine Treffer gefunden</h3></td></tr>",
      item: `
          <tr>
          <td>
            <div class="hit-description">
              <p><a href="{{id}}.html" class="kgparl-link">{{title}}</a></p>
            </div>
            <div class="hit-breadcrumb">
              <span class="badge rounded-pill m-1 bg-success"
                >{{period}}</span
              >
              <span class="badge rounded-pill m-1 bg-info"
                >{{party}}</span
              >
              <span class="badge rounded-pill m-1 bg-warning"
                >{{date}}</span
              >
            </div>
            </td>
          </tr>
        `,
    },
  }),*/
  customHits({
    container: document.querySelector("#hits"),
  }),
  instantsearch.widgets.configure({
    attributesToSnippet: ["title"],
  }),
  instantsearch.widgets.hitsPerPage({
    container: "#hits-per-page",
    items: [
      { label: `30 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 30, default: true },
      { label: `50 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 50 },
      { label: `75 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 75 },
      { label: `100 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 100 },
    ],
  }),
]);

  search.start();
  setupSearchClearButton();
}

// Warten bis i18next bereit ist, dann initialisieren
waitForI18n().then(function() {
  initToc();

  // Bei Sprachwechsel: Suche komplett neu initialisieren
  if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
    i18next.on('languageChanged', function() {
      initToc();
    });
  }
});

// ======== Autocomplete

// Helper for the render function
var renderIndexListItem = ({ hits }) => `
          <table class="autocomplete-list" >
            ${hits
              .map(
                (hit) =>
                  `<tr class="autocomplete-list-item">${instantsearch.highlight(
                    {
                      attribute: "title",
                      hit,
                    },
                  )}</tr>`,
              )
              .join("")}
  </ol >
          `;
