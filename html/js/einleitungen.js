
// Create the render function
var renderHits = (renderOptions, isFirstRender) => {
  var { items, widgetParams, results } = renderOptions;

  let currentAttribute = "year";
  let currentDirection = "asc";

  // Get current sort state - use results._state.index which is more reliable during rendering
  let currentIndex =
    results?._state?.index || results?.index || TYPESENSE_COLLECTIONS.einleitung;

  // Parse current sort from index name
  if (currentIndex.includes("/sort/")) {
    var sortPart = currentIndex.split("/sort/")[1];
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
          <th data-sort-attribute="title" scope="col" tabindex="0" role="columnheader" aria-sort="${getAriaSort("title")}" style="cursor: pointer; user-select: none;">${t('table.title')}${getSortIndicator("title")}</th>
        </tr>
      </thead>
      <tbody>
        ${items
          .map((item) =>
            // use item.reg_id and change .xml to .html
`
          <tr data-href="${item.id}.html" class="" style="cursor: pointer;" title="${t('table.openPage')}" tabindex="0" role="link">

              <td>${item.title}</td>
            </tr>`)
          .join("")}
      </tbody>
    </table>
  `;

  // Add click event listeners to sortable headers
  var headers = widgetParams.container.querySelectorAll(
    "th[data-sort-attribute]",
  );
  headers.forEach((header) => {
    header.addEventListener("click", () => {
      var attribute = header.getAttribute("data-sort-attribute");
      handleHeaderClick(attribute);
    });
  });

  // Add click and keyboard event listeners to table rows
  var rows = widgetParams.container.querySelectorAll("tr[data-href]");
  rows.forEach((row) => {
    var navigateRow = (e) => {
      if (e.target.tagName === "A" || e.target.closest("a")) {
        return;
      }
      var href = row.getAttribute("data-href");
      row.classList.add("row-visited");
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
  query_by: "title,  persons, full_text",
  sort_by: "title:asc",
  num_typos: 0,
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
  var currentSortBy = currentUiState[TYPESENSE_COLLECTIONS.einleitung]?.sortBy || TYPESENSE_COLLECTIONS.einleitung;

  let currentAttribute = "title";
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

  // Construct the index name for sorting
  var indexName = `${TYPESENSE_COLLECTIONS.einleitung}/sort/${attribute}:${newDirection}`;

  // Trigger sorting using setUiState to properly sync with InstantSearch
  search.setUiState({
    [TYPESENSE_COLLECTIONS.einleitung]: {
      ...search.getUiState()[TYPESENSE_COLLECTIONS.einleitung],
      sortBy: indexName,
    },
  });
};

function initEinleitungen() {
  // Bei Neuinitialisierung: alte Instanz aufräumen
  if (search) {
    search.dispose();
  }

  // DOM-Container leeren
  document.querySelector('#searchbox').innerHTML = '';
  document.querySelector('#hits').innerHTML = '';
  document.querySelector('#pagination').innerHTML = '';
  document.querySelector('#hits-per-page').innerHTML = '';
  var personList = document.querySelector('#person-list');
  if (personList) personList.innerHTML = '';
  var clearRef = document.querySelector('#clear-refinements');
  if (clearRef) clearRef.innerHTML = '';

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

  search = instantsearch({
    searchClient: typesenseInstantsearchAdapter.searchClient,
    indexName: TYPESENSE_COLLECTIONS.einleitung,
    routing: true,
  });

  search.addWidgets([
    instantsearch.widgets.searchBox({
      container: "#searchbox",
      placeholder: t('introductions.searchPlaceholder'),
      autofocus: true,
      showReset: false,
      showSubmit: false,
      cssClasses: {
        input: "form-control",
      },
    }),
    instantsearch.widgets.pagination({
      container: "#pagination",
      cssClasses: {
        link: "border-0 text-black fs-3",
      },
    }),
    instantsearch.widgets.sortBy({
      container: document.createElement("div"),
      items: [
        { label: t('sort.titleAZ'), value: TYPESENSE_COLLECTIONS.einleitung, default: true },
        { label: t('sort.titleZA'), value: `${TYPESENSE_COLLECTIONS.einleitung}/sort/title:desc` },
      ],
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
  initEinleitungen();

  // Bei Sprachwechsel: Suche komplett neu initialisieren
  if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
    i18next.on('languageChanged', function() {
      initEinleitungen();
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
