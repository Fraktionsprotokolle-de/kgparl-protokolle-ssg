window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;

// Create the render function
const renderHits = (renderOptions, isFirstRender) => {
  const { items, widgetParams } = renderOptions;

  widgetParams.container.innerHTML = `
      <div class="container">

        ${items
          .map(
            (item) =>
              `<div class="row mb-4">
          <a  class="kgparl-link" href="${item.id}.html" alt="${instantsearch.highlight({ attribute: "reg", hit: item })}" title="${instantsearch.highlight({ attribute: "reg", hit: item })}" target="_self">
              <div class="col" onclick="window.location.href='${item.id}.html'"><div class="card">
              <div class="card-header no-wrap"> ${item.isMDB === true ? `<img width="32px" src="../images/Deutscher_Bundestag_logo.svg" />` : ""}<h5 class="card-title">${instantsearch.highlight({ attribute: "reg", hit: item })}</h5></div>

              <div class="card-body">${instantsearch.highlight({ attribute: "birth", hit: item })} ${instantsearch.highlight({ attribute: "death", hit: item })}</div>
            </div></div></a></div>`,
          )
          .join("")}
      </div>
  `;
};

// Create the custom widget
const customHits = instantsearch.connectors.connectHits(renderHits);
// const $TSClient = await $searchClient.collections("kgparl").documents().search({q: "*"});
//  $allFound.innerHTML = ;
//
let TypesenseSearchClientConfig = {
  nodes: [
    {
      host: "typesense.testserver.stephan-makowski.de",
      port: "8108",
      protocol: "https",
    },
  ],
  apiKey: "Hu52dwsas2AdxdE", // Be sure to use an API key that only has search permissions, since this is exposed in the browser
  numRetries: 3,
  connectionTimeoutSeconds: 10,
};

const additionalSearchParameters = {
  query_by: "letter,  reg, gnd",
  sort_by: "surname:asc",
  exhaustive_search: true,
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

let searchClient = typesenseInstantsearchAdapter.searchClient;

const search = instantsearch({
  searchClient,
  indexName: "kgparl_persons",
  routing: true,
  use_cache: true,
});

const renderRefinementList = (renderOptions, isFirstRender) => {
  const { items, widgetParams, createURL } = renderOptions;

  // If is first render, exit
  if (isFirstRender) {
    return;
  }

  // If is not first render, put all items in localStorage for further use
  $itemsFormStorage = localStorage.getItem(widgetParams.attribute);
  if ($itemsFormStorage === null) {
    localStorage.setItem(widgetParams.attribute, JSON.stringify(items));
  }
  let $isSelected = false;
  let letters = "";

  // iterate over all items
  letter = new Set(
    items
      .sort(({ value: a }, { value: b }) => {
        const ai = parseInt(a, 10),
          bi = parseInt(b, 10);
        return (b == null) - (a == null) || ai - bi || (a > b) - (b > a);
      })
      .map((item) => {
        if (item.isRefined) {
          $isSelected = item.value;
        }
        return item.value;
      }),
  );

  // check if items are in localStorage
  // if not, put them there sorted by name
  if (localStorage.getItem("letter") !== null) {
    jsonletters = JSON.parse(localStorage.getItem("letter"));
    letters = new Set(
      jsonletters
        .sort(({ value: a }, { value: b }) => {
          const ai = parseInt(a, 10),
            bi = parseInt(b, 10);
          return (b == null) - (a == null) || ai - bi || (a > b) - (b > a);
        })
        .map((item) => {
          return item.value;
        }),
    );
  } else {
    letters = letter;
  }

  $targetDiv = widgetParams.container;
  $targetDiv.innerHTML = "";
  letters.forEach((item) => {
    $(`<div class="col">
              <span>
<a class="kgparl-link ${item === $isSelected ? "selected" : ""} " href="${createURL(item)}"> ${item}</a>

              </span></div>
            `).appendTo($targetDiv);
  });
};
// 2. Create the custom widget
const customRefinementList =
  instantsearch.connectors.connectRefinementList(renderRefinementList);

search.addWidgets([
  customRefinementList({
    container: document.querySelector("#letters"),
    attribute: "letter",
    operator: "and",
    limit: 30,
  }),
  instantsearch.widgets.searchBox({
    container: document.querySelector("#searchbox"),
    placeholder: "Personenname oder GND",
    showLoadingIndicator: true,
  }),
  instantsearch.widgets.stats({
    container: document.querySelector("#allFound"),
    templates: {
      text: ({ nbHits }) => {
        let statsText = "";
        statsText = `${nbHits.toLocaleString()}`;
        return `${statsText}`;
      },
    },
  }),
  instantsearch.widgets.pagination({
    container: "#pagination",
  }),
  customHits({
    container: document.querySelector("#hits"),
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
