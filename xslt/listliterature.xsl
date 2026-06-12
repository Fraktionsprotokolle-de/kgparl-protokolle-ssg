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
            <xsl:text>Literaturverzeichnis</xsl:text>
        </xsl:variable>
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
                            <h1 data-i18n="literature.title">Literaturverzeichnis</h1>
                            <p class="register-count" id="register-total-count"></p>
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
                                                    <td><code>Adenauer NOT Erhard</code></td>
                                                    <td data-i18n="search.syntaxNotDesc">Schließt Treffer aus, die den zweiten Begriff enthalten</td>
                                                </tr>
                                                <tr>
                                                    <td><code>-</code></td>
                                                    <td><code>Adenauer -Erhard</code></td>
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
                                    <span data-i18n="literature.or">oder</span>
                                </div>
                                <p class="register-letter-hint" data-i18n="literature.letterHint">Alle Einträge anzeigen, deren Autornachname mit dem gewählten Buchstaben beginnt:</p>
                                <div id="letters" class="person-letters"></div>
                                <div id="allFound" class="search-stats"></div>
                                <div class="list-hits" id="hits"></div>
                                <div class="list-pagination" id="pagination"></div>
                            </div>

                            <aside class="list-sidebar" aria-label="Optionen">
                                <h3 data-i18n="protocols.hitsPerPage">Treffer pro Seite</h3>
                                <div id="hits-per-page"></div>
                            </aside>
                        </div>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
                <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
                <script src="js/searchUtils.js"></script>
                <script src="js/literaturregister.js"></script>
            </body>
        </html>


    </xsl:template>
</xsl:stylesheet>
