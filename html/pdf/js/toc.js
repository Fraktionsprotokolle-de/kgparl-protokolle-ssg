// ======= UncommentrchAdapter from "typesense-instantsearch-adapter";

// Create the render function
const renderHits = (renderOptions, isFirstRender) => {
  const { items, widgetParams } = renderOptions;

  widgetParams.container.innerHTML = `
    <table class="table table-striped table-hover" id="toc-table">
      <thead>
        <tr>
          <th>Fraktion</th>
          <th>Wahlperiode</th>
          <th>Titel</th>
          <th>Jahr</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        ${items
          .map(
            (item) =>
              `<tr>
              <td>${instantsearch.highlight({ attribute: "party", hit: item })}</td>
              <td>${instantsearch.highlight({ attribute: "period", hit: item })}</td>
              <td>${instantsearch.highlight({ attribute: "title", hit: item })}</td>
              <td>${instantsearch.highlight({ attribute: "year", hit: item })}</td>
              <td><a href="${item.id}.html" class="btn-detail-view" title="Seite aufrufen" target="_self">&nbsp;</a></td>
            </tr>`,
          )
          .join("")}
      </tbody>
    </table>
  `;
};

// Create the custom widget
const customHits = instantsearch.connectors.connectHits(renderHits);

window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;
const additionalSearchParameters = {
  query_by: "title, party, period, persons, full_text",
  sort_by: "year:asc, party:asc",
  // group_by: "categories",
  // group_limit: 1
  // pinned_hits: "23:2"
};

// Allow search params to be specified in the URL, for the test suite
const urlParams = new URLSearchParams(window.location.search);
["groupBy", "groupLimit", "pinnedHits", "sortBy"].forEach((attr) => {
  if (urlParams.has(attr)) {
    additionalSearchParameters[attr] = urlParams.get(attr);
  }
});

const typesenseInstantsearchAdapter = new TypesenseInstantSearchAdapter({
  server: {
    connectionTimeoutSeconds: 10000,
    apiKey: "Hu52dwsas2AdxdE", // Be sure to use an API key that only has search permissions, since this is exposed in the browser
    nodes: [
      {
        host: "typesense.testserver.stephan-makowski.de",
        port: "8108",
        protocol: "https",
      },
    ],
  },
  // The following parameters are directly passed to Typesense's search API endpoint.
  //  So you can pass any parameters supported by the search endpoint below.
  //  query_by is required.
  additionalSearchParameters,
});

const searchClient = typesenseInstantsearchAdapter.searchClient;
const search = instantsearch({
  searchClient,
  indexName: "kgparl",
  routing: true,
});

// ============ Begin Widget Configuration
search.addWidgets([
  instantsearch.widgets.searchBox({
    container: "#searchbox",
    placeholder: "Durchsuche die Protokolle",
    autofocus: true,
    showReset: true,
    showSubmit: false,
    cssClasses: {
      input: "form-control",
    },
  }),
  instantsearch.widgets.pagination({
    container: "#pagination",
  }),
  instantsearch.widgets.sortBy({
    container: "#sort-by",
    items: [
      { label: "Jahr", value: "kgparl", default: true },
      { label: "Jahr absteigend", value: "kgparl/sort/year:desc" },
      { label: "Wahlperiode", value: "kgparl/sort/period:asc" },
      { label: "Wahlperiode absteigend", value: "kgparl/sort/period:desc" },
      { label: "Fraktion", value: "kgparl/sort/party:asc" },
      { label: "Fraktion absteigend", value: "kgparl/sort/party:desc" },
    ],
  }),
  instantsearch.widgets.refinementList({
    container: document.querySelector("#period-list"),
    attribute: "period",
    operator: "and",
    transformItems: (items) => {
      return items.map(item => ({
        ...item,
        label: String(parseInt(item.label, 10))
      }));
    },
    cssClasses: {
      searchableInput: "form-control form-control-sm mb-2",
      searchableSubmit: "d-none",
      searchableReset: "d-none",
      showMore: "btn btn-secondary btn-sm",
      list: "list-unstyled",
      count: "badge counter ms-auto",
      label: "d-flex align-items-center text-black mb-1 ms-2",
      checkbox: "mr-2",
    },
    /*templates: {
      header: "<h3>Wahlperiode</h3>",
      item: `
        <div class="refinement-list-item">
          <span class="badge rounded-pill m-1 bg-kgparl">{{label}}</span>
        </div>
      `,
    },*/
  }),
  instantsearch.widgets.clearRefinements({
    container: "#clear-refinements",
    templates: {
      resetLabel: "Filter zurücksetzen",
    },
    cssClasses: {
      button: "btn",
    },
  }),
  instantsearch.widgets.currentRefinements({
    container: "#current-refinements",
    cssClasses: {
      delete: "btn",
      label: "badge",
    },
  }),
  instantsearch.widgets.refinementList({
    container: "#person-list",
    attribute: "persons",
    searchable: true,
    searchablePlaceholder: "Suche nach Personen",
    searchableIsAlwaysActive: true,
    operator: "and",
    cssClasses: {
      searchableInput: "form-control form-control-sm mb-2",
      searchableSubmit: "d-none",
      searchableReset: "d-none",
      showMore: "btn btn-secondary btn-sm",
      list: "list-unstyled",
      count: "badge d-block  ms-4 counter",
      label: "d-flex px-2 align-items-center mb-1 me-4 text-black",
      checkbox: "mr-2",
    },
  }),
  instantsearch.widgets.refinementList({
    container: "#party-list",
    attribute: "party",
    limit: 10,
    operator: "and",
    cssClasses: {
      searchableInput: "form-control form-control-sm mb-2",
      searchableSubmit: "d-none",
      searchableReset: "d-none",
      showMore: "btn btn-secondary btn-sm",
      list: "list-unstyled",
      count: "badge d-block  ms-4 counter",
      label: "d-flex px-2 align-items-center mb-1 me-4 text-black",
      checkbox: "mr-2",
    },
  }),
  instantsearch.widgets.rangeSlider({
    container: "#year-menu",
    attribute: "year",
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
      { label: "10 Treffer je Seite", value: 10, default: true },
      { label: "30 Treffer je Seite", value: 30 },
      { label: "50 Treffer je Seite", value: 50 },
      { label: "100 Treffer je Seite", value: 100 },
    ],
  }),
]);

search.start();

// ======== Autocomplete

// Helper for the render function
const renderIndexListItem = ({ hits }) => `
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
