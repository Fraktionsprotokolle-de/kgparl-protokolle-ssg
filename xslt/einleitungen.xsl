<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
    <!ENTITY copy "&#169;">
    <!ENTITY nbsp "&#160;">
    <!ENTITY ndash "&#8211;">
]>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="http://dse-static.foo.bar" version="2.0" exclude-result-prefixes="xsl tei xs local">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes"
        omit-xml-declaration="yes" />

    <xsl:import href="./partials/html_head.xsl" />
    <xsl:import href="./partials/html_navbar.xsl" />
    <xsl:import href="./partials/html_footer.xsl" />
    <xsl:import href="./partials/one_time_alert.xsl" />

    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select='"Einleitungen"' />
        </xsl:variable>
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
                            <h1 data-i18n="introductions.title">Einleitungen</h1>
                            <p data-i18n="introductions.description">Wissenschaftliche Einführungen zu den Editionsbänden der Fraktionsprotokolle</p>
                        </div>

                        <!-- Two-Column Layout -->
                        <div class="list-page-layout">
                            <!-- Main Content Area -->
                            <div class="list-main-content">
                                <div class="list-searchbox" id="searchbox"></div>
                                <div id="year-menu"></div>
                                <div class="list-hits" id="hits"></div>
                                <div class="list-pagination" id="pagination"></div>
                            </div>

                            <!-- Sidebar -->
                            <aside class="list-sidebar" aria-label="Filter und Optionen">
                                <h2 data-i18n="protocols.persons">Personen</h2>
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
                <script src="js/einleitungen.js" type="text/javascript"></script>
            </body>
        </html>
    </xsl:template>
    <xsl:template match="tei:div//tei:head">
        <h2 id="{generate-id()}">
            <xsl:apply-templates />
        </h2>
    </xsl:template>

    <xsl:template match="tei:p">
        <p id="{generate-id()}">
            <xsl:apply-templates />
        </p>
    </xsl:template>

    <xsl:template match="tei:list">
        <ul id="{generate-id()}">
            <xsl:apply-templates />
        </ul>
    </xsl:template>

    <xsl:template match="tei:item">
        <li id="{generate-id()}">
            <xsl:apply-templates />
        </li>
    </xsl:template>
    <xsl:template match="tei:ref">
        <xsl:choose>
            <xsl:when test="starts-with(data(@target), 'http')">
                <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="@target" />
                    </xsl:attribute>
                    <xsl:value-of select="." />
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
