window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;

// Create the render function for table format
const renderHits = (renderOptions, isFirstRender) => {
  const { items, widgetParams } = renderOptions;

  if (items.length === 0) {
    widgetParams.container.innerHTML = `<p class="register-no-results">${t('hits.noResultsSelection')}</p>`;
    return;
  }

  widgetParams.container.innerHTML = `
      <table class="kgparl-table literature-register-table">
        <thead>
          <tr>
            <th scope="col">${t('table.title')}</th>
            <th scope="col">Zotero</th>
          </tr>
        </thead>
        <tbody>
          ${items
            .map(
              (item) =>
                `<tr>
                  <td>${item.title}</td>
                  <td>
                    <a href="${item.href}" target="_blank" rel="noopener" class="zotero-link" title="${t('literature.openInZotero')}">
                      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 512 512" aria-hidden="true">
                        <rect width="512" height="512" rx="80" fill="#cc2936"/>
                        <path d="M160 144h192v40L176 336h176v40H160v-40l176-152H160z" fill="#fff"/>
                      </svg>
                    </a>
                  </td>
                </tr>`,
            )
            .join("")}
        </tbody>
      </table>
  `;
};

// Create the custom widget
const customHits = instantsearch.connectors.connectHits(renderHits);

const additionalSearchParameters = {
  query_by: "letter, authors, title",
  sort_by: "title:asc",
  exhaustive_search: true,
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
let search = null;

// Store letter refine function for cross-widget access
let letterRefine = null;
let letterItems = [];
let currentSelectedLetter = false;

const renderRefinementList = (renderOptions, isFirstRender) => {
  const { items, widgetParams, refine } = renderOptions;
  letterRefine = refine;
  letterItems = items;

  if (isFirstRender) {
    return;
  }

  $itemsFormStorage = localStorage.getItem(widgetParams.attribute);
  if ($itemsFormStorage === null) {
    localStorage.setItem(widgetParams.attribute, JSON.stringify(items));
  }

  // Detect currently selected letter from items
  let $isSelected = false;
  items.forEach((item) => {
    if (item.isRefined) {
      $isSelected = item.value;
    }
  });
  // Also check our own tracking (for letters with 0 results)
  if (!$isSelected && currentSelectedLetter) {
    $isSelected = currentSelectedLetter;
  }

  let letters = "";
  letter = new Set(
    items
      .sort(({ value: a }, { value: b }) => {
        const ai = parseInt(a, 10),
          bi = parseInt(b, 10);
        return (b == null) - (a == null) || ai - bi || (a > b) - (b > a);
      })
      .map((item) => item.value),
  );

  if (localStorage.getItem("letter") !== null) {
    jsonletters = JSON.parse(localStorage.getItem("letter"));
    letters = new Set(
      jsonletters
        .sort(({ value: a }, { value: b }) => {
          const ai = parseInt(a, 10),
            bi = parseInt(b, 10);
          return (b == null) - (a == null) || ai - bi || (a > b) - (b > a);
        })
        .map((item) => item.value),
    );
  } else {
    letters = letter;
  }

  $targetDiv = widgetParams.container;
  $targetDiv.innerHTML = "";
  letters.forEach((letterValue) => {
    const isCurrentlySelected = letterValue === $isSelected;
    const $link = $(`<div class="col">
              <span>
<a class="kgparl-link letter-filter ${isCurrentlySelected ? "selected" : ""}" href="#" data-letter="${letterValue}"> ${letterValue}</a>
              </span></div>
            `);

    $link.find("a").on("click", function(e) {
      e.preventDefault();
      const clickedLetter = $(this).data("letter");

      // Clear search box when selecting a letter
      search.helper.setQuery('').search();
      const input = document.querySelector('#searchbox .ais-SearchBox-input');
      if (input) input.value = '';

      if (clickedLetter === $isSelected) {
        // Deselect: unrefine via items if possible, otherwise direct
        currentSelectedLetter = false;
        const found = items.find(i => i.isRefined);
        if (found) {
          refine(found.value);
        } else {
          refine(clickedLetter);
        }
      } else {
        // Unrefine any currently refined items
        items.forEach((item) => {
          if (item.isRefined) {
            refine(item.value);
          }
        });
        // If we had a tracked selection not in items, unrefine it too
        if (currentSelectedLetter && !items.find(i => i.value === currentSelectedLetter && i.isRefined)) {
          refine(currentSelectedLetter);
        }
        currentSelectedLetter = clickedLetter;
        refine(clickedLetter);
      }
    });

    $link.appendTo($targetDiv);
  });
};

const customRefinementList =
  instantsearch.connectors.connectRefinementList(renderRefinementList);

const date = new Date();

function initLiteraturregister() {
  // Bei Neuinitialisierung: alte Instanz aufräumen
  if (search) {
    search.dispose();
  }

  // DOM-Container leeren
  document.querySelector('#searchbox').innerHTML = '';
  document.querySelector('#hits').innerHTML = '';
  document.querySelector('#pagination').innerHTML = '';
  document.querySelector('#hits-per-page').innerHTML = '';
  var lettersEl = document.querySelector('#letters');
  if (lettersEl) lettersEl.innerHTML = '';
  var allFoundEl = document.querySelector('#allFound');
  if (allFoundEl) allFoundEl.innerHTML = '';

  // Neue InstantSearch-Instanz erstellen
  const typesenseInstantsearchAdapter = new TypesenseInstantSearchAdapter({
    server: {
      connectionTimeoutSeconds: TYPESENSE_CONFIG.timeout * 1000,
      apiKey: TYPESENSE_CONFIG.apiKey,
      nodes: [
        {
          host: TYPESENSE_CONFIG.host,
          port: String(TYPESENSE_CONFIG.port),
          protocol: TYPESENSE_CONFIG.protocol,
        },
      ],
    },
    additionalSearchParameters,
  });

  search = instantsearch({
    searchClient: typesenseInstantsearchAdapter.searchClient,
    indexName: TYPESENSE_COLLECTIONS.literature,
    routing: true,
    use_cache: true,
  });

  search.addWidgets([
    customRefinementList({
      container: document.querySelector("#letters"),
      attribute: "letter",
      operator: "and",
      limit: 30,
    }),
    instantsearch.widgets.searchBox({
      container: document.querySelector("#searchbox"),
      placeholder: t('literature.searchPlaceholder'),
      showLoadingIndicator: true,
      autofocus: true,
      showReset: false,
      showSubmit: false,
      cssClasses: {
        input: "form-control",
      },
      queryHook: createQueryHook(
        TYPESENSE_COLLECTIONS.literature,
        additionalSearchParameters.query_by,
        additionalSearchParameters
      ),
    }),
    instantsearch.widgets.stats({
      container: document.querySelector("#allFound"),
      templates: {
        text: ({ nbHits }) => {
          // Update total count in page header on first load
          const totalEl = document.getElementById('register-total-count');
          if (totalEl && !totalEl.dataset.set) {
            totalEl.textContent = `${nbHits.toLocaleString()} ${t('literature.statsText')}`;
            totalEl.dataset.set = '1';
          }
          const lang = (typeof i18next !== 'undefined' && i18next.language) || 'de';
          return `${nbHits.toLocaleString()} ${t('literature.statsText')} (${t('literature.statsDate')}: ${date.toLocaleDateString(lang === 'de' ? 'de-DE' : 'en-US')})`;
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
        { label: `30 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 30, default: true },
        { label: `50 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 50 },
        { label: `75 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 75 },
        { label: `100 ${t('hits.hitsPerPage', 'Treffer je Seite')}`, value: 100 },
      ],
    }),
  ]);
  search.start();
  setupSearchClearButton();

  // When typing in search box, deselect any active letter filter
  var letterInputBound = false;
  search.on('render', function() {
    if (letterInputBound) return;
    const searchInput = document.querySelector('#searchbox .ais-SearchBox-input');
    if (!searchInput) return;
    letterInputBound = true;

    searchInput.addEventListener('input', function() {
      if (this.value && letterRefine) {
        letterItems.forEach((item) => {
          if (item.isRefined) {
            letterRefine(item.value);
          }
        });
      }
    });
  });
}

// Warten bis i18next bereit ist, dann initialisieren
waitForI18n().then(function() {
  initLiteraturregister();

  // Bei Sprachwechsel: Suche komplett neu initialisieren
  if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
    i18next.on('languageChanged', function() {
      initLiteraturregister();
    });
  }
});
