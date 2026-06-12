<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY copy "&#169;">
    <!ENTITY nbsp "&#160;">
    <!ENTITY ndash "&#8211;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0" exclude-result-prefixes="xsl tei xs">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes"
        omit-xml-declaration="yes" />

    <xsl:import href="./partials/html_navbar.xsl" />
    <xsl:import href="./partials/html_head.xsl" />
    <xsl:import href="./partials/html_footer.xsl" />
    <xsl:import href="./fraktionsprotokolle.xslt" />

    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:text>Schlagwortregister</xsl:text>
        </xsl:variable>
        <xsl:variable name="col" select="collection('../build/valid-editions/?select=*.xml;recurse=no')" />
        <xsl:variable name="standDatum"
            select=".//tei:publicationStmt/tei:date/@when" />
        <xsl:variable name="countItems"
            select="count(.//tei:standOff/tei:list[@type='fpv']/tei:item)" />
        <html lang="de" class="h-100">

            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
                <script
                    src="https://cdn.jsdelivr.net/npm/typesense-instantsearch-adapter@2/dist/typesense-instantsearch-adapter.min.js" />
                <script
                    src="https://cdn.jsdelivr.net/npm/algoliasearch@4.5.1/dist/algoliasearch-lite.umd.js"
                    integrity="sha256-EXPXz4W6pQgfYY3yTpnDa3OH8/EPn16ciVsPQ/ypsjk="
                    crossorigin="anonymous" />
                <script
                    src="https://cdn.jsdelivr.net/npm/instantsearch.js@4.74.1/dist/instantsearch.production.min.js"
                    crossorigin="anonymous" />
            </head>

            <body>
                <xsl:call-template name="nav_bar" />

                <main class="main-content" id="main-content">
                    <div class="kgparl-container">
                        <div class="page-header">
                            <h1 data-i18n="keywordRegister.title">Schlagwortregister</h1>
                            <p class="register-count" id="register-total-count">
                                <xsl:value-of select="$countItems" />
                                <xsl:text> </xsl:text>
                                <span data-i18n="keywordRegister.description">Schlagwörter im Register</span>
                            </p>
                        </div>

                        <div class="list-page-layout">
                            <div class="list-main-content">
                                <div class="list-searchbox" id="searchbox"></div>
                                <details class="search-syntax-help">
                                    <summary data-i18n="search.syntaxHelpTitle">Suchsyntax</summary>
                                    <div class="details-content">
                                        <table class="search-syntax-table">
                                            <thead>
                                                <tr>
                                                    <th scope="col" data-i18n="search.syntaxOperator">Operator</th>
                                                    <th scope="col" data-i18n="search.syntaxExample">Beispiel</th>
                                                    <th scope="col" data-i18n="search.syntaxDescription">Beschreibung</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr>
                                                    <td><code>NOT</code></td>
                                                    <td><code>Außenpolitik NOT NATO</code></td>
                                                    <td data-i18n="search.syntaxNotDesc">Schließt Treffer aus, die den zweiten Begriff enthalten</td>
                                                </tr>
                                                <tr>
                                                    <td><code>-</code></td>
                                                    <td><code>Außenpolitik -NATO</code></td>
                                                    <td data-i18n="search.syntaxMinusDesc">Kurzform für NOT (ohne Leerzeichen vor dem Begriff)</td>
                                                </tr>
                                                <tr>
                                                    <td><code>"..."</code></td>
                                                    <td><code>"Berliner Mauer"</code></td>
                                                    <td data-i18n="search.syntaxPhraseDesc">Sucht nach der exakten Wortfolge</td>
                                                </tr>
                                                <tr>
                                                    <td><code>NOT</code> + <code>"..."</code></td>
                                                    <td><code>"Berliner Mauer" NOT Grenze</code></td>
                                                    <td data-i18n="search.syntaxCombinedDesc">Kombinierte Suche: Phrase ohne bestimmte Begriffe</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                        <p class="search-syntax-note">
                                            <strong data-i18n="search.letterHintLabel">Hinweis:</strong>&#160;<span data-i18n="search.letterHintText">Die Buchstabennavigation und die Texteingabe schließen sich gegenseitig aus. Bei Eingabe eines Suchbegriffs wird ein aktiver Buchstabenfilter zurückgesetzt und umgekehrt.</span>
                                        </p>
                                    </div>
                                </details>
                                <div class="register-separator">
                                    <span data-i18n="keywordRegister.or">oder</span>
                                </div>
                                <p class="register-letter-hint" data-i18n="keywordRegister.letterHint">Alle Schlagwörter anzeigen, die mit dem gewählten Buchstaben beginnen:</p>
                                <div id="letters" class="person-letters"></div>
                                <div id="allFound" class="search-stats" data-stand="{$standDatum}"></div>
                                <div class="list-hits" id="hits"></div>
                                <div class="list-pagination" id="pagination"></div>
                            </div>

                            <aside class="list-sidebar" aria-label="Optionen">
                                <h2 data-i18n="keywordRegister.entityType">Kategorie</h2>
                                <div id="entityType"></div>
                                <h2 data-i18n="protocols.hitsPerPage">Treffer pro Seite</h2>
                                <div id="hits-per-page"></div>
                            </aside>
                        </div>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
                <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
                <script src="js/searchUtils.js"></script>
                <script src="js/schlagwortregister.js"></script>
            </body>
        </html>

        <!-- Detail pages for each keyword item -->
        <xsl:for-each select=".//tei:standOff/tei:list[@type='fpv']/tei:item">
            <xsl:variable name="item_id" select="data(@xml:id)" />
            <xsl:variable name="filename" select="concat(./@xml:id, '.html')" />
            <xsl:variable name="prefLabel" select="tei:term[@type='pref']/text()" />
            <xsl:variable name="hashedid" select="concat('#', $item_id)" />
            <xsl:variable name="hits" select="$col//tei:term[@ref=$hashedid]" />
            <xsl:variable name="distinct" select="distinct-values($hits/base-uri(.))" />
            <xsl:variable name="entityType" select="tei:note[@type='entityType']/text()" />

            <xsl:result-document href="{$filename}">
                <html lang="de">
                    <head>
                        <xsl:call-template name="html_head">
                            <xsl:with-param name="html_title" select="$prefLabel"></xsl:with-param>
                        </xsl:call-template>
                        <link
                            rel="stylesheet"
                            href="https://cdn.datatables.net/1.12.1/css/jquery.dataTables.css"
                        />
                        <link rel="stylesheet" href="css/kgparl.css" />
                        <script src="https://cdn.datatables.net/1.12.1/js/jquery.dataTables.js"></script>
                        <script
                            src="//cdn.datatables.net/plug-ins/1.12.1/pagination/ellipses.js"></script>
                    </head>

                    <body>
                        <xsl:call-template name="nav_bar" />

                        <main class="main-content" id="main-content">
                            <div class="kgparl-container">
                                <div class="page-header">
                                    <h1>
                                        <xsl:value-of select="$prefLabel" />
                                    </h1>
                                    <p class="keyword-entity-type">
                                        <span class="entity-type-badge entity-type-{$entityType}">
                                            <xsl:choose>
                                                <xsl:when test="$entityType = 'pol'" >Politik</xsl:when>
                                                <xsl:when test="$entityType = 'news'">Medien</xsl:when>
                                                <xsl:when test="$entityType = 'com'" >Unternehmen</xsl:when>
                                                <xsl:when test="$entityType = 'org'" >Organisationen</xsl:when>
                                                <xsl:when test="$entityType = 'topic'">Themen</xsl:when>
                                                <xsl:otherwise><xsl:value-of select="$entityType" /></xsl:otherwise>
                                            </xsl:choose>
                                        </span>
                                    </p>
                                    <a class="kgparl-btn-outline keyword-search-link"
                                        href="liste.html?keyword={encode-for-uri($prefLabel)}"
                                        data-i18n="keywordRegister.searchInProtocols">
                                        Begriff in den Protokollen suchen
                                    </a>
                                </div>

                                <div class="keyword-detail-layout">
                                    <div class="keyword-info-section">
                                        <!-- Definition -->
                                        <xsl:if test="tei:note[@type='definition'] and string-length(tei:note[@type='definition']) > 0">
                                            <h2 data-i18n="keywordRegister.definition">Erläuterung</h2>
                                            <div class="detail-card">
                                                <div class="detail-card-body">
                                                    <p><xsl:value-of select="tei:note[@type='definition']" /></p>
                                                    <p class="keyword-internal-id">Interne ID: <span class="keyword-id-badge"><xsl:value-of select="$item_id" /></span></p>
                                                </div>
                                            </div>
                                        </xsl:if>

                                        <!-- Alternative Labels -->
                                        <xsl:if test="tei:term[@type='alt']">
                                            <h2 data-i18n="keywordRegister.altLabels">Alternative Bezeichnungen</h2>
                                            <div class="detail-card">
                                                <div class="detail-card-body">
                                                    <div class="keyword-alt-labels" style="display: flex; flex-wrap: wrap; gap: 0.5rem;">
                                                        <xsl:for-each select="tei:term[@type='alt']">
                                                            <span class="keyword-alt-badge">
                                                                <xsl:value-of select="." />
                                                            </span>
                                                        </xsl:for-each>
                                                    </div>
                                                </div>
                                            </div>
                                        </xsl:if>

                                        <!-- Verwandte Schlagwörter -->
                                        <xsl:if test="tei:list[@type='related']/tei:item">
                                            <h2 data-i18n="keywordRegister.relatedKeywords">Verwandte Schlagwörter</h2>
                                            <div class="detail-card">
                                                <div class="detail-card-body">
                                                    <div class="keyword-alt-labels" style="display: flex; flex-wrap: wrap; gap: 0.5rem;">
                                                        <xsl:for-each select="tei:list[@type='related']/tei:item">
                                                            <xsl:variable name="relId" select="replace(@corresp, '#', '')" />
                                                            <xsl:variable name="relLabel">
                                                                <xsl:call-template name="translate-keyword">
                                                                    <xsl:with-param name="key" select="$relId" />
                                                                </xsl:call-template>
                                                            </xsl:variable>
                                                            <a href="{$relId}.html" class="keyword-related-badge">
                                                                <xsl:choose>
                                                                    <xsl:when test="string-length($relLabel) > 0">
                                                                        <xsl:value-of select="$relLabel" />
                                                                    </xsl:when>
                                                                    <xsl:otherwise>
                                                                        <xsl:value-of select="$relId" />
                                                                    </xsl:otherwise>
                                                                </xsl:choose>
                                                            </a>
                                                        </xsl:for-each>
                                                    </div>
                                                </div>
                                            </div>
                                        </xsl:if>

                                        <!-- Vernetzte Angebote / Linked Data -->
                                        <xsl:if test="tei:ref[@type='exactMatch'][string-length(@target) > 0] or tei:ref[@type='closeMatch'][string-length(@target) > 0]">
                                            <h3 class="section-heading" data-i18n="personRegister.linkedOffers">Vernetzte Angebote</h3>
                                            <div class="detail-card">
                                                <div class="detail-card-body">
                                                    <xsl:if test="tei:ref[@type='exactMatch'][string-length(@target) > 0]">
                                                        <p class="linked-offers-label">Normdaten:</p>
                                                        <ul class="linked-offers-list">
                                                            <xsl:for-each select="tei:ref[@type='exactMatch'][string-length(@target) > 0]">
                                                                <li>
                                                                    <a href="{@target}" target="_blank" rel="noopener">
                                                                        <xsl:value-of select="@target" />
                                                                    </a>
                                                                </li>
                                                            </xsl:for-each>
                                                        </ul>
                                                    </xsl:if>
                                                    <xsl:if test="tei:ref[@type='closeMatch'][string-length(@target) > 0]">
                                                        <p class="linked-offers-label">Weiterführende Links:</p>
                                                        <ul class="linked-offers-list">
                                                            <xsl:for-each select="tei:ref[@type='closeMatch'][string-length(@target) > 0]">
                                                                <li>
                                                                    <a href="{@target}" target="_blank" rel="noopener">
                                                                        <xsl:value-of select="@target" />
                                                                    </a>
                                                                </li>
                                                            </xsl:for-each>
                                                        </ul>
                                                    </xsl:if>
                                                </div>
                                            </div>
                                        </xsl:if>
                                    </div>

                                    <!-- Protocol references grouped by WP -->
                                    <xsl:if test="count($distinct) > 0">
                                        <div class="keyword-protocols-section">
                                            <h2 data-i18n="keywordRegister.references">Erwähnung in Fraktionsprotokollen</h2>
                                            <ul class="protocol-list">
                                                <!-- Group hits by Wahlperiode -->
                                                <xsl:for-each-group select="$hits" group-by="root(.)//tei:creation//tei:idno[@type='wp']">
                                                    <xsl:sort select="current-grouping-key()" data-type="number" />
                                                    <xsl:variable name="wp" select="current-grouping-key()" />
                                                    <xsl:variable name="wpHits" select="current-group()" />
                                                    <xsl:variable name="wpDistinct" select="distinct-values($wpHits/base-uri(.))" />

                                                    <xsl:if test="count($wpDistinct) > 0">
                                                        <li class="protocol-list-item">
                                                            <details class="protocol-details">
                                                                <summary class="protocol-summary">
                                                                    <span class="wp-label"><xsl:value-of select="$wp" />. <span data-i18n="personRegister.electoralPeriods">Wahlperiode</span></span>
                                                                    <span class="wp-count">
                                                                        <xsl:value-of select="count($wpDistinct)" />
                                                                    </span>
                                                                </summary>
                                                                <table id="protocol-table-{$wp}" class="kgparl-table keyword-protocol-table display" style="width: 100%;">
                                                                    <thead>
                                                                        <tr>
                                                                            <th scope="col" data-i18n="personRegister.faction">Fraktion</th>
                                                                            <th scope="col" data-i18n="personRegister.date">Datum</th>
                                                                            <th scope="col" data-i18n="personRegister.titleColumn">Titel</th>
                                                                        </tr>
                                                                    </thead>
                                                                    <tbody>
                                                                        <xsl:for-each-group select="$wpHits" group-by="base-uri(.)">
                                                                            <xsl:sort select="root(.)//tei:creation//tei:date[1]" order="descending" />
                                                                            <xsl:variable name="url" select="replace(tokenize(base-uri(.), '/')[last()], 'xml', 'html')" />
                                                                            <xsl:variable name="date">
                                                                                <xsl:call-template name="PureDate">
                                                                                    <xsl:with-param name="protocol" select="root(.)" />
                                                                                </xsl:call-template>
                                                                            </xsl:variable>

                                                                            <tr data-href="{$url}?q={encode-for-uri($prefLabel)}&amp;keyword={encode-for-uri($prefLabel)}">
                                                                                <td>
                                                                                    <xsl:call-template name="GetParty">
                                                                                        <xsl:with-param name="protocol" select="root(.)" />
                                                                                    </xsl:call-template>
                                                                                </td>
                                                                                <td data-sort="{$date}">
                                                                                    <xsl:call-template name="GetDate">
                                                                                        <xsl:with-param name="protocol" select="root(.)" />
                                                                                    </xsl:call-template>
                                                                                </td>
                                                                                <td>
                                                                                    <a href="{$url}?q={encode-for-uri($prefLabel)}&amp;keyword={encode-for-uri($prefLabel)}" class="kgparl-link">
                                                                                        <xsl:value-of select="root(.)//tei:titleStmt/tei:title[@level='a']" />
                                                                                    </a>
                                                                                </td>
                                                                            </tr>
                                                                        </xsl:for-each-group>
                                                                    </tbody>
                                                                </table>
                                                            </details>
                                                        </li>
                                                    </xsl:if>
                                                </xsl:for-each-group>
                                            </ul>
                                        </div>
                                    </xsl:if>
                                </div>

                            </div>
                        </main>
                        <script>
                            $(document).ready(function () {
                            // Initialize DataTables
                            $("table.kgparl-table").each(function () {
                            $(this).DataTable({
                            pageLength: 25,
                            responsive: true,
                            autoWidth: false,
                            order: [[1, "asc"]],
                            language: {
                            url: "js/de-DE.json",
                            },
                            });
                            });

                            // Add click event listeners to table rows
                            $("table.kgparl-table tbody").on("click", "tr", function (e) {
                            if (e.target.tagName === "A" || $(e.target).closest("a").length) {
        return;
                            }
                            var href = $(this).attr("data-href");
                            if (href) {
                              if (e.ctrlKey || e.metaKey || e.button === 1) {
                                window.open(href, '_blank');
                              } else {
                                window.location.href = href;
                              }
                            }
                            });
                            });
                        </script>
                        <xsl:call-template name="html_footer" />

                    </body>
                </html>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
