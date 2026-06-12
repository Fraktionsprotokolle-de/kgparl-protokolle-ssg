<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="http://dse-static.foo.bar" version="2.0" exclude-result-prefixes="xsl tei xs local">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes"
        omit-xml-declaration="yes" />

    <xsl:import href="partials/html_navbar.xsl" />
    <xsl:import href="partials/html_head.xsl" />
    <xsl:import href="partials/html_footer.xsl" />

    <xsl:template match="/">
        <xsl:variable name="doc_title" select="'Protokolle'" />
        <html lang="de">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>

                <script src="https://code.jquery.com/jquery-3.6.3.min.js"
                    integrity="sha256-pvPw+upLPUjgMXY0G+8O0xUf+/Im1MZjXxxgOcBQBXU="
                    crossorigin="anonymous"></script>
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
                        <!-- Page Header -->
                        <div class="page-header">
                            <h1 data-i18n="protocols.title">Protokolle</h1>
                            <p data-i18n="protocols.description">Durchsuchen Sie die digitalisierten Fraktionsprotokolle des Deutschen Bundestags</p>
                        </div>

                        <!-- Two-Column Layout -->
                        <div class="list-page-layout">
                            <!-- Main Content Area -->
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
                                                    <td><code>Solar NOT Solartechnik</code></td>
                                                    <td data-i18n="search.syntaxNotDesc">Schließt Treffer aus, die den zweiten Begriff enthalten</td>
                                                </tr>
                                                <tr>
                                                    <td><code>-</code></td>
                                                    <td><code>Solar -Solartechnik</code></td>
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
                                    </div>
                                </details>
                                <div id="year-menu"></div>
                                <div class="list-hits" id="hits"></div>
                                <div class="list-pagination" id="pagination"></div>
                            </div>

                            <!-- Sidebar -->
                            <aside class="list-sidebar" aria-label="Filter und Optionen">
                                <h2 data-i18n="protocols.factions">Fraktionen</h2>
                                <div id="party-list"></div>

                                <h2 data-i18n="protocols.periods">Wahlperioden</h2>
                                <div id="period-list"></div>

                                <h2 data-i18n="protocols.persons">Personen</h2>
                                <span data-i18n="facets.personLimit">Limit: maximal 100 Personen mit den häufigsten Vorkommen</span>
                                <div id="person-list"></div>

                                <div id="clear-refinements"></div>

                                <h2 data-i18n="protocols.hitsPerPage">Treffer pro Seite</h2>
                                <div id="hits-per-page"></div>
                            </aside>
                        </div>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />

                <script src="js/searchUtils.js"></script>
                <script src="js/toc.js"></script>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
