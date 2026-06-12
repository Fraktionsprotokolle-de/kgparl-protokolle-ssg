window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;

// entityType label mapping
function entityTypeLabel(type) {
  const map = {
    pol: t('entityTypes.pol', 'Politik'),
    news: t('entityTypes.news', 'Medien'),
    com: t('entityTypes.com', 'Unternehmen'),
    org: t('entityTypes.org', 'Organisationen'),
    topic: t('entityTypes.topic', 'Themen'),
  };
  return map[type] || type;
}

// Create the render function for table format
const renderHits = (renderOptions, isFirstRender) => {
  const { items, widgetParams } = renderOptions;

  if (items.length === 0) {
    widgetParams.container.innerHTML = `<p class="register-no-results">${t('hits.noResultsSelection', 'Keine Treffer für diese Auswahl.')}</p>`;
    return;
  }

  widgetParams.container.innerHTML = `
      <table class="kgparl-table keyword-register-table">
        <thead>
          <tr>
            <th scope="col">${t('keywordRegister.keyword', 'Schlagwort')}</th>
            <th scope="col">${t('keywordRegister.entityType', 'Kategorie')}</th>
          </tr>
        </thead>
        <tbody>
          ${items
            .map(
              (item) =>
                `<tr class="clickable-row" data-href="${item.id}.html" tabindex="0" role="link" style="cursor: pointer;">
                  <td><a href="${item.id}.html" class="kgparl-link">${item.prefLabel}</a></td>
                  <td><span class="entity-type-badge entity-type-${item.entityType}">${entityTypeLabel(item.entityType)}</span></td>
                </tr>`,
            )
            .join("")}
        </tbody>
      </table>
  `;

  // Add click and keyboard handler for rows
  $(widgetParams.container).find("tr.clickable-row").on("click keydown", function (e) {
    if (e.type === "keydown" && e.key !== "Enter") return;
    if (e.target.tagName === "A" || $(e.target).closest("a").length) return;
    var href = $(this).attr("data-href");
    if (href) window.location.href = href;
  });
};

// Create the custom widget
var customHits = instantsearch.connectors.connectHits(renderHits);

const additionalSearchParameters = {
  query_by: "prefLabel, altLabels, definition",
  sort_by: "prefLabel:asc",
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
      if (input) {
        var nativeSet = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
        nativeSet.call(input, '');
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
      // Re-enable letter bar visually
      document.querySelectorAll('.letter-filter').forEach(el => el.classList.remove('disabled'));

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

function initSchlagwortregister() {
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
  var entityTypeEl = document.querySelector('#entityType');
  if (entityTypeEl) entityTypeEl.innerHTML = '';

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
    indexName: TYPESENSE_COLLECTIONS.keywords,
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
      placeholder: t('keywordRegister.searchPlaceholder', 'Schlagwort suchen'),
      showLoadingIndicator: true,
      autofocus: true,
      showReset: false,
      showSubmit: false,
      cssClasses: {
        input: "form-control",
      },
      queryHook: createQueryHook(
        TYPESENSE_COLLECTIONS.keywords,
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
            totalEl.textContent = `${nbHits.toLocaleString()} ${t('keywordRegister.statsText', 'Schlagwörter im Register')}`;
            totalEl.dataset.set = '1';
          }
          const lang = (typeof i18next !== 'undefined' && i18next.language) || 'de';
          return `${nbHits.toLocaleString()} ${t('keywordRegister.statsText', 'Schlagwörter im Register')} (${t('keywordRegister.statsDate', 'Stand')}: ${date.toLocaleDateString(lang === 'de' ? 'de-DE' : 'en-US')})`;
        },
      },
    }),
    instantsearch.widgets.refinementList({
      container: document.querySelector("#entityType"),
      attribute: "entityType",
      transformItems: function(items) {
        return items.map(function(item) {
          return Object.assign({}, item, {
            highlighted: entityTypeLabel(item.label),
            label: entityTypeLabel(item.label),
          });
        });
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
        if (currentSelectedLetter) {
          letterRefine(currentSelectedLetter);
          currentSelectedLetter = false;
        }
        document.querySelectorAll('.letter-filter').forEach(el => el.classList.add('disabled'));
      } else if (!this.value) {
        document.querySelectorAll('.letter-filter').forEach(el => el.classList.remove('disabled'));
      }
    });
  });
}

// Warten bis i18next bereit ist, dann initialisieren
waitForI18n().then(function() {
  initSchlagwortregister();

  // Bei Sprachwechsel: Suche komplett neu initialisieren
  if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
    i18next.on('languageChanged', function() {
      initSchlagwortregister();
    });
  }
});
