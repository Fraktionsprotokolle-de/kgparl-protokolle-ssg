window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;

// const $TSClient = await $searchClient.collections("kgparl").documents().search({q: "*"});
//  $allFound.innerHTML = ;
//
$(document).ready(function () {
  let TypesenseSearchClientConfig = {
    nodes: [
      {
        host: "75.119.133.118",
        port: "8108",
        protocol: "http",
      },
    ],
    apiKey: "Hu52dwsas2AdxdE", // Be sure to use an API key that only has search permissions, since this is exposed in the browser
    numRetries: 3,
    connectionTimeoutSeconds: 10,
  };

  const additionalSearchParameters = {
    query_by: "title, party, period",
    sort_by: "year:asc, party:asc",
    exclude_fields: "vectors",
    exhaustive_search: true,
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

  let searchClient = typesenseInstantsearchAdapter.searchClient;

  const search = instantsearch({
    searchClient,
    indexName: "kgparl",
    routing: true,
  });

  const renderRefinementList = (renderOptions, isFirstRender) => {
    const { items, widgetParams, createURL } = renderOptions;

    // If is first render, put all items in localStorage for further use
    //if (isFirstRender) {
    localStorage.removeItem(widgetParams.attribute);
    localStorage.setItem(widgetParams.attribute, JSON.stringify(items));
    //}

    console.log(JSON.stringify(items));
    widgetParams.container.innerHTML = `
      <div class="container">
<table id="findings">
<thead>
<tr>
<th></th>
</tr>
</thead>
<tbody>
        ${items
          .sort(({ value: a }, { value: b }) => {
            const ai = parseInt(a, 10),
              bi = parseInt(b, 10);
            return (b == null) - (a == null) || ai - bi || (a > b) - (b > a);
          })
          .map(
            (item) => `
            <tr>
<td>
              <span>
                <a class="kgparl-link" href="${createURL(item.rec_id)}"> ${item.date} &gt; ${item.title} (${item.party})</a>
              </span>
</td>
</tr>
            `,
          )
          .join("")}
</tbody>
</table>
      </div>
    `;
  };
  // 2. Create the custom widget
  const customRefinementList =
    instantsearch.connectors.connectRefinementList(renderRefinementList);

  search.addWidgets([
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
    ,
    ,
  ]);
  search.start();
});
