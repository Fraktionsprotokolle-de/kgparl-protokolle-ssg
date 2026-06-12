window.$ = jQuery;
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;

/** Format a date string, handling BCE dates (negative years like "-0428") */
function formatPersonDate(dateStr) {
  if (!dateStr) return '';
  const lang = (typeof i18next !== 'undefined' && i18next.language) || 'de';
  if (dateStr.startsWith('-')) {
    const year = parseInt(dateStr.substring(1), 10);
    return lang === 'de' ? `${year} v.\u00A0Chr.` : `${year} BCE`;
  }
  // Year-only (4 digits, no hyphens): display as plain number
  if (/^\d{1,4}$/.test(dateStr)) {
    return String(parseInt(dateStr, 10));
  }
  // Year-month only (e.g. "2022-05"): display as "Mai 2022" without day
  if (/^\d{4}-\d{2}$/.test(dateStr)) {
    const locale = lang === 'de' ? 'de-DE' : 'en-US';
    return new Date(dateStr + '-15').toLocaleDateString(locale, { month: 'long', year: 'numeric' });
  }
  const locale = lang === 'de' ? 'de-DE' : 'en-US';
  return new Date(dateStr).toLocaleDateString(locale, { day: 'numeric', month: 'long', year: 'numeric' });
}

// Create the render function for table format
const renderHits = (renderOptions, isFirstRender) => {
  const { items, widgetParams } = renderOptions;

  if (items.length === 0) {
    widgetParams.container.innerHTML = `<p class="register-no-results">${t('hits.noResultsSelection', 'Keine Treffer für diese Auswahl.')}</p>`;
    return;
  }

  widgetParams.container.innerHTML = `
      <table class="kgparl-table person-register-table">
        <thead>
          <tr>
            <th scope="col">${t('table.name', 'Name')}</th>
            <th scope="col">MdB</th>
            <th scope="col">${t('personRegister.birth', 'Geburt')}</th>
            <th scope="col">${t('personRegister.death', 'Tod')}</th>
          </tr>
        </thead>
        <tbody>
          ${items
            .map(
              (item) =>
                `<tr class="clickable-row" data-href="${item.id}.html" tabindex="0" role="link" style="cursor: pointer;">
                  <td><a href="${item.id}.html" class="kgparl-link">${item.surname && item.forename ? item.surname + ', ' + item.forename + (item.prefix ? ' ' + item.prefix : '') : (item.surname || item.reg)}</a></td>
                  <td>${item.isMDB === true ? `<span class="person-result-badge">MdB</span>` : ""}</td>
                  <td>${item.birth ? `${formatPersonDate(item.birth)}${item.birth_place ? ` in ${item.birth_place}` : ""}${item.birth_country && item.birth_country.length > 0 ? ` (${item.birth_country})` : ""}` : ""}</td>
                  <td>${item.death && item.death.length > 0 ? `${formatPersonDate(item.death)}${item.death_place && item.death_place.length > 0 ? ` in ${item.death_place}` : ""}${item.death_country && item.death_country.length > 0 ? ` (${item.death_country})` : ""}` : ""}</td>
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
  query_by: "name_combined, surname, forename, name_search",
  query_by_weights: "5,3,3,1",
  sort_by: "surname:asc",
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
      // Revert to alphabetical sort
      additionalSearchParameters.sort_by = "surname:asc";

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
// 2. Create the custom widget
const customRefinementList =
  instantsearch.connectors.connectRefinementList(renderRefinementList);

// Stand-Datum aus data-Attribut (vom XSLT aus publicationStmt/date/@when)
const standEl = document.getElementById('allFound');
const standRaw = standEl ? standEl.dataset.stand : null;

function initPersonenregister() {
  const lang = (typeof i18next !== 'undefined' && i18next.language) || 'de';
  const standDatum = standRaw
    ? new Date(standRaw).toLocaleDateString(lang === 'de' ? 'de-DE' : 'en-US', { day: 'numeric', month: 'numeric', year: 'numeric' })
    : new Date().toLocaleDateString(lang === 'de' ? 'de-DE' : 'en-US', { day: 'numeric', month: 'numeric', year: 'numeric' });

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
    indexName: TYPESENSE_COLLECTIONS.persons,
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
      placeholder: t('personRegister.searchPlaceholder', 'Personenname'),
      showLoadingIndicator: true,
      autofocus: true,
      showReset: false,
      showSubmit: false,
      cssClasses: {
        input: "form-control",
      },
      queryHook: createQueryHook(
        TYPESENSE_COLLECTIONS.persons,
        additionalSearchParameters.query_by,
        additionalSearchParameters
      ),
    }),
    instantsearch.widgets.stats({
      container: document.querySelector("#allFound"),
      templates: {
        text: ({ nbHits }) => {
          return `${nbHits.toLocaleString()} ${t('personRegister.statsText', 'Personen im Register.')} (${t('personRegister.statsDate', 'Stand')}: ${standDatum})`;
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
        { label: `30 ${t('personRegister.hitsPerPage', 'Treffer je Seite')}`, value: 30, default: true },
        { label: `50 ${t('personRegister.hitsPerPage', 'Treffer je Seite')}`, value: 50 },
        { label: `75 ${t('personRegister.hitsPerPage', 'Treffer je Seite')}`, value: 75 },
        { label: `100 ${t('personRegister.hitsPerPage', 'Treffer je Seite')}`, value: 100 },
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
        // Deselect any active letter filter when typing
        letterItems.forEach((item) => {
          if (item.isRefined) {
            letterRefine(item.value);
          }
        });
        // Also clear our own tracking
        if (currentSelectedLetter) {
          letterRefine(currentSelectedLetter);
          currentSelectedLetter = false;
        }
        // Visually disable letter bar
        document.querySelectorAll('.letter-filter').forEach(el => el.classList.add('disabled'));
        // Sort by relevance when searching
        additionalSearchParameters.sort_by = "_text_match:desc,surname:asc";
      } else if (!this.value) {
        // Re-enable letter bar when search is cleared
        document.querySelectorAll('.letter-filter').forEach(el => el.classList.remove('disabled'));
        // Revert to alphabetical sort
        additionalSearchParameters.sort_by = "surname:asc";
      }
    });
  });
}

// Warten bis i18next bereit ist, dann initialisieren
waitForI18n().then(function() {
  initPersonenregister();

  // Bei Sprachwechsel: Suche komplett neu initialisieren
  if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
    i18next.on('languageChanged', function() {
      initPersonenregister();
    });
  }
});
