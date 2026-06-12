window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;
// Periods = new Set 1 to 15 (1. bis 15. Wahlperiode)
$periods = new Set([
  "01",
  "02",
  "03",
  "04",
  "05",
  "06",
  "07",
  "08",
  "09",
  "10",
  "11",
  "12",
  "13",
  "14",
  "15",
]);

// Parties = new Set(["CDU/CSU", "SPD", "GRUENE", "FDP", "CSU-LG", "PDS"])
$parties = new Set(["CDU/CSU", "CSU-LG", "FDP", "Grüne", "PDS", "SPD"]);
$(document).ready(function () {
  // If Document is ready, load Typesense
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
    use_cache: true,
  };

  const additionalSearchParameters = {
    query_by: "title, party, period",
    sort_by: "year:asc, party:asc",
    exclude_fields: "vectors, full_text, persons, orgs",
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
    use_cache: true,
    // The following parameters are directly passed to Typesense's search API endpoint.
    //  So you can pass any parameters supported by the search endpoint below.
    //  query_by is required.
    additionalSearchParameters,
  });

  let searchClient = typesenseInstantsearchAdapter.searchClient;

  const search = instantsearch({
    searchClient,
    indexName: "kgparl",
    routing: true,
  });

  const renderRefinementList = (renderOptions, isFirstRender) => {
    const { items, widgetParams, createURL } = renderOptions;

    // If is first render, put all items in localStorage for further use
    if (!isFirstRender) {
      localStorage.removeItem(widgetParams.attribute);
      localStorage.setItem(widgetParams.attribute, JSON.stringify(items));
      //
      let $checker = "";

      if (widgetParams.attribute === "period") {
        $checker = $periods;
        $targetdiv = $("#search-wp");
      } else if (widgetParams.attribute === "party") {
        $checker = $parties;
        $targetdiv = $("#search-party");
      }
      // Check if there is any Item which is not in the current
      let $isSelected = "";
      // iterate over all items
      if (items.length > 0) {
        $actitem = "";
        $actitem = new Set(
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

        $diff = $checker.difference($actitem);
      } else {
        $diff = new Set();
      }
      console.log($targetdiv);
      $checker.forEach((item) => {
        if ($diff.has(item)) {
          $(
            `<div class="col"><a type="btn" class="btn btn-outline-primary w-100 rounded-pill disabled">${item}</a>`,
          ).appendTo($targetdiv);
        } else {
          $(
            `<div class="col"><a type="button" href=${createURL(item)} class="btn btn-outline-primary w-100 rounded-pill ${item == $isSelected ? "selected" : ""}">${item}</a>`,
          ).appendTo($targetdiv);
        }
      });
    }
  };
  /*
  else {
      widgetParams.container.innerHTML = `
        ${items
          .map(
            (item) => `
              <div class="col">
                <a class="btn btn-outline-primary w-100 ${item.isRefined ? "selected" : ""}" href="${createURL(item.value)}">${item.label}</a>
              </div> 
            `,
          )
          .join("")}
    `;
    
  };*/

  // 2. Create the custom widget
  const customRefinementList =
    instantsearch.connectors.connectRefinementList(renderRefinementList);

  // Widgets for the search
  search.addWidgets([
    instantsearch.widgets.stats({
      container: document.querySelector("#allFound"),
      templates: {
        text(data, { html }) {
          let statsText = "";
          statsText = `${data.nbHits.toLocaleString()}`;
          return html`${statsText} Dokumente für diese Auswahl`;
        },
      },
      cssClasses: {
        root: "",
        text: "orange",
      },
    }),
    customRefinementList({
      container: document.querySelector("#search-party"),
      attribute: "party",
      operator: "and",
      limit: 20,
    }),
    customRefinementList({
      container: document.querySelector("#search-wp"),
      attribute: "period",
      operator: "and",
      limit: 20,
    }),
  ]);
  search.start();

  $(document).ready(function () {
    $("button#allFound").click(function () {
      SubmitHandler();
    });

    $("button#search").click(function () {
      SubmitSearch();
    });
  });
});

function SubmitHandler() {
  // copy current search state to the url
  // and attach it to the forwading link
  const queryString = window.location.search;
  const url = new URL(window.location.href);
  if (url.href.includes("?")) {
    url.href = url.href.replace("?", "liste.html?");
  } else {
    url.href = url.href + "liste.html";
  }
  url.search = new URLSearchParams(queryString).toString();

  console.log(url);
  // replace index.html with liste.html

  newRef = url.toString();

  // redirect to the new url
  window.location.href = newRef.toString();
  //
}

function SubmitSearch() {
  const queryString = window.location.search;
  const url = new URL(window.location.href);
  if (url.href.includes("?")) {
    url.href = url.href.replace("?", "suche.html?");
  } else {
    url.href = url.href + "suche.html";
  }

  search = new URLSearchParams(queryString);
  search.set("kgparl[query]", $("#query").val());
  url.search = search.toString();
  console.log(url);
  // replace index.html with liste.html

  newRef = url.toString();

  // redirect to the new url
  window.location.href = newRef.toString();
}
