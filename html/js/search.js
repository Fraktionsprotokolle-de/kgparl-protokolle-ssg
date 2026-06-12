/**
 * search.js — Volltextsuche für Fraktionsprotokolle
 *
 * Aufbau:
 *   1. Hilfsfunktionen   — Synonym-Lookup, Query-Parsing, Typesense-Fetches
 *   2. State-Variablen   — aktives Suchinstanz-Tracking, NOT-Filter, Snippet-Cache
 *   3. initSearch()      — Hauptfunktion: InstantSearch-Instanz aufbauen + starten
 *   4. Hit-Templates     — HTML-Rendering für Protokoll- und Einleitungstreffer
 *   5. Tab-Wechsel + Init— Event-Handler für Protokolle/Einleitungen-Tabs
 *
 * Synonym-Expansion (OR-Semantik):
 *   Typesense unterstützt kein echtes OR in der `q`-Suche. Stattdessen wird
 *   ein zweistufiger Ansatz verwendet:
 *   - Synonym-Alternativen werden per SYNONYM_MAP (aus synonymData.js) nachgeschlagen
 *   - Für jede Alternative werden die passenden Dokument-IDs + Highlight-Snippets
 *     separat von Typesense geholt (fetchSynonymResults)
 *   - Diese IDs werden über `pinned_hits` in die Ergebnisse eingefügt
 *   - Da Typesense gepinnte Treffer nicht highlightet, werden die Snippets
 *     im render-Callback client-seitig aus dem Cache injiziert
 *   - Typesense dedupliziert automatisch: ein gepinntes Dokument, das auch die
 *     Hauptquery matcht, erscheint nur einmal
 *
 * NOT-Filter:
 *   "Solar NOT Technik" → Typesense sucht "Solar", Dokumente mit "Technik"
 *   werden per `filter_by: id:!=[...]` ausgeschlossen. Gepinnte Synonym-IDs
 *   werden ebenfalls gegen die Exclude-Liste gefiltert.
 *
 * Externe Abhängigkeiten (müssen vor search.js geladen sein):
 *   - typesense-instantsearch-adapter.min.js  (TypesenseInstantSearchAdapter)
 *   - instantsearch.js                        (instantsearch, Widgets)
 *   - js/config.js                            (TYPESENSE_CONFIG, TYPESENSE_COLLECTIONS)
 *   - js-data/synonymData.js                  (SYNONYM_MAP)
 */

window.$ = jQuery;

/** Wahlperioden-Lookup für die Facetten-Anzeige (WP-Nummer → Jahreszeitraum) */
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
window.TypesenseInstantSearchAdapter = TypesenseInstantSearchAdapter;

/** Anzahl der Kontext-Tokens um einen Suchtreffer herum (für ältere Snippet-Logik) */
const contextLength = 35;

/**
 * Look up synonym alternatives for tokens in a query.
 * Returns a flat array of alternative strings, or null if no synonyms found.
 * Multi-word alternatives are returned as-is (quoting is the caller's job).
 *
 * getSynonymAlts("NATO")   → ["North Atlantic Treaty Organisation", "Nordatlantikpakt-Organisation", "Nordatlantikvertrag"]
 * getSynonymAlts("KGParl") → ["Kommission für Geschichte des Parlamentarismus und der politischen Parteien"]
 * getSynonymAlts("Bonn")   → null
 */
function getSynonymAlts(query) {
  if (typeof SYNONYM_MAP === 'undefined') return null;
  const tokens = query.match(/"[^"]*"|\S+/g) || [];
  const alts = [];
  for (const token of tokens) {
    const bare = token.replace(/^"|"$/g, '');
    const found = SYNONYM_MAP[bare.toLowerCase()];
    if (found) {
      for (const alt of found) alts.push(alt);
    }
  }
  return alts.length > 0 ? alts : null;
}

// parseQuery and fetchExcludeIDs are provided by searchUtils.js (loaded before this file).
// search.js wraps fetchIDsForTerm/fetchExcludeIDs to inject collection-specific queryBy fields.

/**
 * Fetch all document IDs matching a single term from Typesense (search.js wrapper).
 * Injects the correct queryBy fields based on the collection.
 */
async function searchFetchIDsForTerm(term, collection) {
  const queryBy = collection === TYPESENSE_COLLECTIONS.einleitung
    ? 'title,persons,full_text'
    : 'title,party,period,persons,full_text';
  return fetchIDsForTerm(term, collection, queryBy);
}

/**
 * Fetch document IDs to exclude (search.js wrapper).
 */
async function searchFetchExcludeIDs(negatives, collection) {
  const queryBy = collection === TYPESENSE_COLLECTIONS.einleitung
    ? 'title,persons,full_text'
    : 'title,party,period,persons,full_text';
  return fetchExcludeIDs(negatives, collection, queryBy);
}

/**
 * Fetch synonym hits with highlight snippets for each alternative term.
 *
 * Hintergrund: Typesense's `pinned_hits` erzeugt kein Highlighting für gepinnte
 * Dokumente — auch nicht mit `highlight_query`. Deshalb werden die Synonym-
 * Alternativen hier separat gesucht, wobei Typesense die Highlight-Snippets
 * liefert. Diese werden im synonymSnippetCache gespeichert und nach dem
 * InstantSearch-Render per DOM-Injection in die Hit-Cards eingefügt.
 *
 * Jede Alternative wird einzeln gesucht (parallel, paginiert), um:
 *   1. Alle passenden Dokument-IDs für pinned_hits zu erhalten
 *   2. Die <mark>-Highlighted Snippets für die Snippet-Injection zu sammeln
 *
 * @param {string[]} alts       — Synonym-Alternativen (z.B. ["Nordatlantikvertrag", "North Atlantic Treaty Organisation"])
 * @param {string}   collection — Typesense-Collection-Name
 * @returns {Promise<{ids: string[], snippets: Record<string, string>}>}
 *   ids:      Deduplizierte Dokument-IDs (für pinned_hits)
 *   snippets: Map von docId → HTML-Snippet mit <mark>-Tags (für Render-Injection)
 */
async function fetchSynonymResults(alts, collection) {
  const queryBy = collection === TYPESENSE_COLLECTIONS.einleitung
    ? 'title,persons,full_text'
    : 'title,party,period,persons,full_text';
  const baseUrl = `${TYPESENSE_CONFIG.protocol}://${TYPESENSE_CONFIG.host}:${TYPESENSE_CONFIG.port}`;
  // Multi-Wort-Alternativen in Anführungszeichen setzen → Phrasensuche in Typesense
  const altTerms = alts.map(a => a.includes(' ') ? `"${a}"` : a);

  // Alle Alternativen parallel suchen, jeweils mit Highlight-Snippets
  const results = await Promise.all(altTerms.map(async (term) => {
    const allHits = [];
    let page = 1;
    while (true) {
      const params = new URLSearchParams({
        q: term,
        query_by: queryBy,
        highlight_fields: 'full_text',
        highlight_affix_num_tokens: '12',
        per_page: '250',
        page: String(page),
      });
      const resp = await fetch(`${baseUrl}/collections/${collection}/documents/search?${params}`, {
        headers: { 'X-TYPESENSE-API-KEY': TYPESENSE_CONFIG.apiKey },
      });
      if (!resp.ok) break;
      const data = await resp.json();
      if (!data.hits || data.hits.length === 0) break;
      for (const hit of data.hits) allHits.push(hit);
      if (allHits.length >= (data.found || 0)) break;
      page++;
    }
    return allHits;
  }));

  // Deduplizieren und Snippets extrahieren
  const seen = new Set();
  const ids = [];
  const snippets = {};
  for (const hitList of results) {
    for (const hit of hitList) {
      const id = hit.document?.id;
      if (id && !seen.has(id)) {
        seen.add(id);
        ids.push(id);
        // Highlight-Snippet aus dem full_text-Feld extrahieren
        const ftHighlight = hit.highlights?.find(h => h.field === 'full_text');
        if (ftHighlight?.snippet) {
          snippets[id] = ftHighlight.snippet;
        }
      }
    }
  }
  return { ids, snippets };
}

/* ═══════════════════════════════════════════════════════════════════════════
 *  State-Variablen
 * ═══════════════════════════════════════════════════════════════════════════ */

/** URL-Parameter (z.B. ?q=Solar&type=einleitung) */
var urlParams = new URLSearchParams(window.location.search);

/** Aktive InstantSearch-Instanz (wird bei Tab-Wechsel via dispose() ersetzt) */
let currentSearch = null;
/** Aktiver Collection-Typ: 'protocols' (Standard) oder 'einleitung' */
let currentCollectionType = urlParams.get('type') === 'einleitung' ? 'einleitung' : 'protocols';

/**
 * Aktiver NOT-Filter (filter_by-Wert), der an Typesense gesendet wird.
 * Format: "id:!=[`doc1`,`doc2`,...]" — wird bei jeder neuen Suche zurückgesetzt.
 */
let activeExcludeFilter = null;
/**
 * Anzeige-Query mit NOT-Termen (z.B. "Solar NOT Technik").
 * InstantSearch kennt nur den positiven Teil — der volle Query wird nach jedem
 * Render im Suchfeld wiederhergestellt (siehe search.on('render')).
 */
let activeDisplayQuery = null;
/**
 * Cache für Synonym-Highlight-Snippets: { docId → HTML-String mit <mark>-Tags }.
 * Wird von fetchSynonymResults() befüllt und im render-Callback in die Hit-Cards
 * injiziert, da Typesense pinned_hits nicht selbst highlightet.
 */
let synonymSnippetCache = {};
/**
 * Aktive Synonym-Suchbegriffe: [originalQuery, ...synonym-Alternativen].
 * Wird genutzt, um im Render-Callback die Typesense-Token-Highlights durch
 * korrekte Phrase-Highlights zu ersetzen.
 */
let activeSynonymTerms = null;

/* ═══════════════════════════════════════════════════════════════════════════
 *  initSearch() — Hauptfunktion
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * Erzeugt eine neue InstantSearch-Instanz für die gewählte Collection
 * (Protokolle oder Einleitungen). Wird beim Seitenaufruf und bei jedem
 * Tab-Wechsel aufgerufen.
 *
 * Ablauf:
 *   1. Alte Instanz verwerfen + DOM bereinigen
 *   2. Typesense-Adapter mit Collection-spezifischen Parametern konfigurieren
 *   3. Widgets registrieren (Suchbox, Hits, Pagination, Facetten)
 *   4. search.start() — InstantSearch startet, ggf. mit Query aus URL-Routing
 *   5. render-Callback registrieren (Snippet-Injection, NOT-Query-Anzeige)
 *   6. Initiale Query behandeln (?q= oder URL-Routing)
 *
 * @param {'protocols'|'einleitung'} collectionType
 */
function initSearch(collectionType) {
  if (currentSearch) {
    currentSearch.dispose();
  }

  // State zurücksetzen (vorherige Suche / Tab)
  activeExcludeFilter = null;
  activeDisplayQuery = null;
  synonymSnippetCache = {};

  // DOM-Container leeren
  document.querySelector('#searchbox').innerHTML = '';
  document.querySelector('#hits').innerHTML = '';
  document.querySelector('#pagination').innerHTML = '';
  document.querySelector('#person-list').innerHTML = '';
  document.querySelector('#hits-per-page').innerHTML = '';

  // Clear protocol-only containers
  const partyList = document.querySelector('#party-list');
  const periodList = document.querySelector('#period-list');
  const sortBy = document.querySelector('#sort-by');
  if (partyList) partyList.innerHTML = '';
  if (periodList) periodList.innerHTML = '';
  if (sortBy) sortBy.innerHTML = '';

  // Show/hide protocol-only facets
  document.querySelectorAll('.protocol-only-facets').forEach(el => {
    el.style.display = collectionType === 'protocols' ? '' : 'none';
  });

  // Configure search parameters per collection type
  const isProtocols = collectionType === 'protocols';
  const collectionName = isProtocols ? TYPESENSE_COLLECTIONS.protocols : TYPESENSE_COLLECTIONS.einleitung;

  const additionalSearchParameters = isProtocols
    ? {
        query_by: "title, party, period, persons, full_text",
        sort_by: "date:asc, sitzungsabfolge:asc, party:asc",
        highlight_fields: "full_text",
        highlight_affix_num_tokens: 12,
        snippet_threshold: 30,
        num_typos: 0,
        split_join_tokens: "off",
      }
    : {
        query_by: "title, persons, full_text",
        highlight_fields: "full_text",
        highlight_affix_num_tokens: 12,
        snippet_threshold: 30,
        num_typos: 0,
        split_join_tokens: "off",
      };

  // Apply URL overrides
  ["groupBy", "groupLimit", "pinnedHits"].forEach((attr) => {
    if (urlParams.has(attr)) {
      additionalSearchParameters[attr] = urlParams.get(attr);
    }
  });

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

  const searchClient = typesenseInstantsearchAdapter.searchClient;
  const search = instantsearch({
    searchClient,
    indexName: collectionName,
    routing: true,
  });

  // Build widget list
  const widgets = [
    instantsearch.widgets.searchBox({
      container: "#searchbox",
      placeholder: isProtocols ? t('search.placeholderProtocols') : t('search.placeholderIntroductions'),
      autofocus: true,
      showReset: false,
      showSubmit: false,
      cssClasses: {
        input: "form-control",
      },
      /**
       * queryHook — Abfangpunkt für jede Sucheingabe (vor dem Absenden an Typesense).
       *
       * Ablauf:
       *   1. Query wird in positiven Teil und NOT-Terme zerlegt (parseQuery)
       *   2. Positiver Teil wird auf Synonym-Alternativen geprüft (getSynonymAlts)
       *   3. Synonym-IDs + Snippets werden parallel geholt (fetchSynonymResults)
       *   4. Bei NOT-Termen: Exclude-IDs parallel holen (fetchExcludeIDs)
       *   5. pinned_hits setzen (Synonyme), filter_by setzen (NOT-Ausschlüsse)
       *   6. refine() aufrufen → Typesense-Suche wird ausgelöst
       *
       * Wichtig: queryHook wird NUR bei Benutzerinteraktion aufgerufen,
       * NICHT beim initialen Laden via URL-Routing (das übernehmen die
       * Handler nach search.start()).
       */
      queryHook(query, refine) {
        if (tryDirectNavigation(query, collectionName, refine)) return;

        const { positive, negatives } = parseQuery(query);
        const synonymAlts = getSynonymAlts(positive);

        /** Synonym-IDs + Highlight-Snippets holen (oder leeres Ergebnis, wenn keine Synonyme) */
        function fetchSynonyms() {
          if (!synonymAlts) return Promise.resolve({ ids: [], snippets: {} });
          return fetchSynonymResults(synonymAlts, collectionName);
        }

        /**
         * Gepinnte Treffer setzen: Synonym-IDs werden als pinned_hits an Typesense übergeben.
         * Dokumente, die in der Exclude-Liste stehen (NOT-Filter), werden vorher entfernt,
         * da pinned_hits den filter_by umgeht (Typesense zeigt sie sonst trotzdem an).
         */
        function setPinnedHits(synIds, excludeSet) {
          const filtered = excludeSet ? synIds.filter(id => !excludeSet.has(id)) : synIds;
          if (filtered.length > 0) {
            // Format: "docid1:1,docid2:2,..." — die Zahl ist die Position (ab 1)
            additionalSearchParameters.pinned_hits = filtered.map((id, i) => `${id}:${i + 1}`).join(',');
          } else {
            delete additionalSearchParameters.pinned_hits;
          }
        }

        // ── Pfad A: Einfache Suche (kein NOT) ──
        if (negatives.length === 0) {
          activeExcludeFilter = null;
          activeDisplayQuery = null;
          delete additionalSearchParameters.filter_by;

          fetchSynonyms().then(({ ids, snippets }) => {
            setPinnedHits(ids, null);
            synonymSnippetCache = snippets;
            if (synonymAlts) {
              activeSynonymTerms = [positive, ...synonymAlts];
            } else {
              activeSynonymTerms = null;
            }
            refine(positive);
          });
          return;
        }

        // ── Pfad B: Suche mit NOT-Termen ──
        // Anzeige-Query zusammenbauen: "-term" wird zu "NOT term" normalisiert
        const displayParts = [positive];
        for (const neg of negatives) {
          displayParts.push('NOT ' + (neg.includes(' ') ? '"' + neg + '"' : neg));
        }
        activeDisplayQuery = displayParts.join(' ');

        // Exclude-IDs und Synonym-Ergebnisse parallel holen
        Promise.all([
          searchFetchExcludeIDs(negatives, collectionName),
          fetchSynonyms(),
        ]).then(([excludeIds, { ids: synIds, snippets }]) => {
          // NOT-Filter: Dokumente per ID ausschließen
          if (excludeIds.length > 0) {
            const filterValue = 'id:!=[' + excludeIds.map(id => '`' + id + '`').join(',') + ']';
            additionalSearchParameters.filter_by = filterValue;
            activeExcludeFilter = filterValue;
          } else {
            delete additionalSearchParameters.filter_by;
            activeExcludeFilter = null;
          }
          // Synonym-Pins setzen (ohne die per NOT ausgeschlossenen Dokumente)
          setPinnedHits(synIds, new Set(excludeIds));
          synonymSnippetCache = snippets;
          if (synonymAlts) {
            activeSynonymTerms = [positive, ...synonymAlts];
          } else {
            activeSynonymTerms = null;
          }
          refine(positive);
        });
      },
    }),
    instantsearch.widgets.hits({
      container: "#hits",
      templates: {
        empty: `<div class="search-empty">
          <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="48" height="48">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
          </svg>
          <h3>${t('hits.noResults')}</h3>
          <p>${t('hits.noResultsHint')}</p>
        </div>`,
        item: isProtocols ? protocolHitTemplate : einleitungHitTemplate,
      },
      transformItems(items) {
        return items;
      }
    }),
    instantsearch.widgets.pagination({
      container: "#pagination",
    }),
    instantsearch.widgets.configure({
      attributesToSnippet: ["title:30", "full_text:50"],
      snippetEllipsisText: "…",
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
  ];

  // Protocol-only widgets
  if (isProtocols) {
    widgets.push(
      instantsearch.widgets.sortBy({
        container: "#sort-by",
        items: [
          { label: t('sort.year'), value: collectionName, default: true },
          { label: t('sort.yearDesc'), value: `${collectionName}/sort/year:desc` },
          { label: t('sort.period'), value: `${collectionName}/sort/period:asc` },
          { label: t('sort.periodDesc'), value: `${collectionName}/sort/period:desc` },
          { label: t('sort.faction'), value: `${collectionName}/sort/party:asc` },
          { label: t('sort.factionDesc'), value: `${collectionName}/sort/party:desc` },
          { label: t('sort.date'), value: `${collectionName}/sort/date:asc` },
          { label: t('sort.dateDesc'), value: `${collectionName}/sort/date:desc` },
        ],
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
          return allParties.map(function(party) {
            if (existing.has(party)) return existing.get(party);
            return { label: party, value: party, count: 0, isRefined: false, highlighted: party };
          });
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
          var allPeriods = Object.keys(dictionary);
          var existing = new Map(items.map(function(item) { return [item.value, item]; }));
          return allPeriods.map(function(period) {
            if (existing.has(period)) return existing.get(period);
            return { label: period, value: period, count: 0, isRefined: false, highlighted: period };
          }).sort(function(a, b) {
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
      })
    );
  }

  // Person refinement list (shared by both types)
  widgets.push(
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
    })
  );

  search.addWidgets(widgets);

  // Bei URL-Routing: activeSynonymTerms VOR search.start() setzen, damit der
  // Render-Callback die Token-Highlights korrigieren kann.
  const preStartQuery = urlParams.get(collectionName + '[query]') || urlParams.get('q');
  if (preStartQuery) {
    const { positive: prePositive } = parseQuery(preStartQuery);
    const preAlts = getSynonymAlts(prePositive);
    if (preAlts) {
      activeSynonymTerms = [prePositive, ...preAlts];
    }
  }

  search.start();
  setupSearchClearButton();

  /* ── Render-Callback: Nach jedem InstantSearch-Render ──────────────────
   *  Zwei Aufgaben:
   *  1. NOT-Anzeige-Query im Suchfeld wiederherstellen (InstantSearch kennt
   *     nur den positiven Teil, zeigt z.B. "Solar" statt "Solar NOT Technik")
   *  2. Synonym-Snippets in gepinnte Hit-Cards injizieren, die kein eigenes
   *     Highlighting haben (weil Typesense pinned_hits nicht highlightet)
   */
  search.on('render', () => {
    // (1) NOT-Query im Suchfeld wiederherstellen
    if (activeDisplayQuery) {
      const input = document.querySelector('#searchbox .ais-SearchBox-input');
      if (input) input.value = activeDisplayQuery;
    }
    // (2) Synonym-Highlighting korrigieren
    // Zwei Probleme werden hier gelöst:
    //   a) Gepinnte Synonym-Treffer haben keinen relevanten Snippet (Typesense highlightet
    //      pinned_hits nicht) → Snippet aus synonymSnippetCache einsetzen
    //   b) Typesense markiert bei Synonym-Expansion einzelne Tokens ("für", "der" etc.)
    //      → Alle <mark>-Tags entfernen, nur Suchbegriff + volle Synonym-Phrase markieren
    if (activeSynonymTerms && activeSynonymTerms.length > 0) {
      const hitCards = document.querySelectorAll('.search-result-card');
      for (const card of hitCards) {
        const link = card.querySelector('.search-result-link');
        const snippet = card.querySelector('.hit-snippet');
        if (!link || !snippet) continue;
        // (a) Gecachtes Synonym-Snippet einsetzen (für gepinnte Treffer ohne Highlight)
        var href = link.getAttribute('href') || '';
        var docId = href.split('.html')[0];
        if (synonymSnippetCache[docId]) {
          snippet.innerHTML = synonymSnippetCache[docId];
        }
        // (b) Alle <mark>-Tags entfernen → Klartext
        var text = snippet.innerHTML.replace(/<\/?mark>/g, '');
        // Suchbegriff + Synonym-Phrasen case-insensitive markieren
        for (var i = 0; i < activeSynonymTerms.length; i++) {
          var escaped = activeSynonymTerms[i].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
          var re = new RegExp('(' + escaped + ')', 'gi');
          text = text.replace(re, '<mark>$1</mark>');
        }
        snippet.innerHTML = text;
      }
    }
  });

  /* ── Initiale Query-Behandlung (nach search.start()) ────────────────────
   *
   * Es gibt drei Wege, wie eine Suche beim Seitenaufruf ausgelöst wird:
   *
   *   A) ?q=Solar+NOT+Technik  — von der Header-Suche oder Startseite
   *      → Query wird manuell geparst, NOT-Filter gesetzt, setUiState() aufgerufen
   *      → queryHook wird NICHT aufgerufen (setUiState umgeht ihn)
   *
   *   B) ?kgparl_test[query]=KGParl  — InstantSearch URL-Routing (z.B. nach Paginierung)
   *      → InstantSearch lädt die Query direkt aus der URL
   *      → queryHook wird NICHT aufgerufen (initiales Laden umgeht ihn)
   *      → Synonym-Pins müssen manuell nachgeholt + search.refresh() getriggert werden
   *
   *   C) Benutzer tippt ins Suchfeld und drückt Enter
   *      → queryHook wird aufgerufen (oben), Synonyme + NOT dort behandelt
   */
  const headerQueryParam = urlParams.get('q');
  if (headerQueryParam) {
    // ── Pfad A: ?q= Parameter von Header-Suche / Startseite ──
    const { positive, negatives } = parseQuery(headerQueryParam);

    if (negatives.length > 0) {
      // NOT-Suche: Anzeige-Query zusammenbauen + Exclude-IDs holen
      const displayParts = [positive];
      for (const neg of negatives) {
        displayParts.push('NOT ' + (neg.includes(' ') ? '"' + neg + '"' : neg));
      }
      activeDisplayQuery = displayParts.join(' ');

      searchFetchExcludeIDs(negatives, collectionName).then(ids => {
        if (ids.length > 0) {
          const filterValue = 'id:!=[' + ids.map(id => '`' + id + '`').join(',') + ']';
          additionalSearchParameters.filter_by = filterValue;
          activeExcludeFilter = filterValue;
        }
        // Nur den positiven Teil an InstantSearch übergeben
        search.setUiState({
          [collectionName]: {
            query: positive,
          },
        });
      });
    } else {
      // Einfache Suche: Synonym-Pins prüfen und setzen
      const alts = getSynonymAlts(headerQueryParam);
      if (alts) {
        fetchSynonymResults(alts, collectionName).then(({ ids, snippets }) => {
          if (ids.length > 0) {
            additionalSearchParameters.pinned_hits = ids.map((id, i) => `${id}:${i + 1}`).join(',');
          }

          synonymSnippetCache = snippets;
          search.setUiState({
            [collectionName]: {
              query: headerQueryParam,
            },
          });
        });
      } else {
        search.setUiState({
          [collectionName]: {
            query: headerQueryParam,
          },
        });
      }
    }
  } else {
    // ── Pfad B: InstantSearch URL-Routing (z.B. ?kgparl_test[query]=KGParl) ──
    // queryHook wird beim initialen Laden NICHT aufgerufen, daher müssen
    // Synonym-Pins hier manuell gesetzt und per search.refresh() nachgeladen werden.
    const routingQuery = urlParams.get(collectionName + '[query]');
    if (routingQuery) {
      const { positive } = parseQuery(routingQuery);
      const alts = getSynonymAlts(positive);
      if (alts) {
        fetchSynonymResults(alts, collectionName).then(({ ids, snippets }) => {
          if (ids.length > 0) {
            additionalSearchParameters.pinned_hits = ids.map((id, i) => `${id}:${i + 1}`).join(',');
          }

          synonymSnippetCache = snippets;
          // refresh() triggert eine neue Suche mit den jetzt gesetzten pinned_hits
          search.refresh();
        });
      }
    }
  }

  currentSearch = search;
}

/**
 * Hit-Template für Protokoll-Treffer.
 * Rendert Titel (verlinkt auf Protokollseite), Metadaten-Badges (WP, Fraktion, Datum)
 * und den Textausschnitt mit Highlighting.
 * Die ?q=-Parameter im Link ermöglicht Suchbegriff-Highlighting auf der Zielseite.
 */
function formatDateDE(isoDate) {
  if (!isoDate) return '';
  const parts = String(isoDate).split('-');
  if (parts.length === 3) return `${parts[2]}.${parts[1]}.${parts[0]}`;
  return isoDate;
}

function protocolHitTemplate(hit, { html, components }) {
  const query = currentSearch?.helper?.state?.query || '';
  const periodDisplay = hit.period ? `${hit.period}. WP` : '';
  const dateDisplay = hit.date ? formatDateDE(hit.date) : '';
  const partyClassMap = {
    'SPD': 'hit-badge-party-spd',
    'CDU/CSU': 'hit-badge-party-cducsu',
    'FDP': 'hit-badge-party-fdp',
    'Grüne': 'hit-badge-party-gruene',
    'PDS': 'hit-badge-party-pds',
    'CSU-LG': 'hit-badge-party-csu'
  };
  const partyClass = partyClassMap[hit.party] || 'hit-badge-party-other';
  return `
    <article class="search-result-card">
      <a href="${hit.id}.html?q=${encodeURIComponent(query)}" class="search-result-link">
        <h3 class="hit-title">
          <span class="kgparl-link">${hit.title}</span>${dateDisplay ? `, ${dateDisplay}` : ''}
        </h3>
        <div class="hit-meta">
          ${periodDisplay ? `<span class="hit-badge hit-badge-period">${periodDisplay}</span>` : ''}
          ${hit.party ? `<span class="hit-badge hit-badge-party ${partyClass}">${hit.party}</span>` : ''}
        </div>
        <div class="hit-snippet">
          ${hit._snippetResult?.full_text?.value || ''}
        </div>
      </a>
    </article>`;
}

/** Hit-Template für Einleitungen (ohne Metadaten-Badges, nur Titel + Snippet) */
function einleitungHitTemplate(hit, { html, components }) {
  const query = currentSearch?.helper?.state?.query || '';
  return `
    <article class="search-result-card">
      <a href="${hit.id}.html?q=${encodeURIComponent(query)}" class="search-result-link">
        <h3 class="hit-title">
          <span class="kgparl-link">${hit.title}</span>
        </h3>
        <div class="hit-snippet">
          ${hit._snippetResult?.full_text?.value || ''}
        </div>
      </a>
    </article>`;
}

/* ═══════════════════════════════════════════════════════════════════════════
 *  Tab-Wechsel (Protokolle / Einleitungen)
 *  Jeder Tab hat data-collection="protocols" bzw. "einleitung".
 *  Beim Klick wird die aktuelle InstantSearch-Instanz verworfen und eine
 *  neue mit der gewählten Collection initialisiert.
 * ═══════════════════════════════════════════════════════════════════════════ */
document.querySelectorAll('.search-type-tab').forEach(tab => {
  tab.addEventListener('click', function () {
    const newType = this.dataset.collection;
    if (newType === currentCollectionType) return;

    document.querySelectorAll('.search-type-tab').forEach(t => t.classList.remove('active'));
    this.classList.add('active');

    // URL aktualisieren, ohne die Seite neu zu laden
    const newUrl = new URL(window.location);
    newUrl.searchParams.set('type', newType);
    newUrl.searchParams.delete('q');
    history.pushState({}, '', newUrl);

    currentCollectionType = newType;
    initSearch(newType);
  });
});

// Aktiven Tab beim Seitenaufruf setzen (aus URL-Parameter)
document.querySelectorAll('.search-type-tab').forEach(tab => {
  tab.classList.toggle('active', tab.dataset.collection === currentCollectionType);
});

// Suche starten — warten bis i18next bereit ist, damit alle t()-Aufrufe korrekte Übersetzungen liefern
waitForI18n().then(function() {
  initSearch(currentCollectionType);

  // Bei Sprachwechsel: Suche komplett neu initialisieren (Widgets mit neuen Übersetzungen)
  if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
    i18next.on('languageChanged', function() {
      initSearch(currentCollectionType);
    });
  }
});
