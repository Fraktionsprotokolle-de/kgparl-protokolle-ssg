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

    <xsl:decimal-format name="de" grouping-separator="." decimal-separator=","/>

    <xsl:import href="./partials/html_head.xsl" />
    <xsl:import href="./partials/html_navbar.xsl" />
    <xsl:import href="./partials/html_footer.xsl" />
    <xsl:import href="./partials/one_time_alert.xsl" />

    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select='"KGParl Protokolle"' />
        </xsl:variable>
        <xsl:variable name="protocol_count"
            select="count(collection('../build/valid-editions/?select=*.xml;recurse=no'))" />
        <xsl:variable name="person_count"
            select="count(document('../data/indices/Personen.xml')//tei:person)" />
        <html lang="de">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@algolia/autocomplete-theme-classic" />
                <script src="https://code.jquery.com/jquery-3.6.3.min.js"
                    integrity="sha256-pvPw+upLPUjgMXY0G+8O0xUf+/Im1MZjXxxgOcBQBXU="
                    crossorigin="anonymous"></script>
                <script src="https://cdn.jsdelivr.net/npm/typesense-instantsearch-adapter@2/dist/typesense-instantsearch-adapter.min.js" />
                <script src="https://cdn.jsdelivr.net/npm/algoliasearch@4.5.1/dist/algoliasearch-lite.umd.js"
                    integrity="sha256-EXPXz4W6pQgfYY3yTpnDa3OH8/EPn16ciVsPQ/ypsjk="
                    crossorigin="anonymous" />
                <script src="https://cdn.jsdelivr.net/npm/instantsearch.js@4.74.1/dist/instantsearch.production.min.js"
                    crossorigin="anonymous" />
            </head>
            <body>
                <xsl:call-template name="nav_bar" />

                <main class="main-content" id="main-content">
                    <div class="kgparl-container">
                        <!-- Hero Section -->
                        <section class="hero-section">
                            <h1>
                                <span data-i18n="index.heroTitleLine1">Fraktionen im Deutschen Bundestag.</span>
                                <br/>
                                <span data-i18n="index.heroTitleLine2">Sitzungsprotokolle 1949–2005</span>
                            </h1>
                            <p class="lead" data-i18n="index.heroLead">
                                Historisch-digitale Quellenedition der Protokolle von Fraktionen und Gruppen
                                im Deutschen Bundestag 1949–2005
                            </p>
                        </section>

                        <!-- Feature Cards -->
                        <section class="feature-grid">
                            <!-- Protokolle Card -->
                            <a href="liste.html" class="feature-card" data-i18n="[title]index.protocolsLink">
                                <xsl:attribute name="title">Zur Listenansicht der Protokolle</xsl:attribute>
                                <div class="feature-card-icon">
                                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                                            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                                    </svg>
                                </div>
                                <h2 data-i18n="index.protocolsTitle">Protokolle</h2>
                                <p>
                                    <span data-i18n="index.protocolsDescPrefix">Die Edition umfasst derzeit</span>
                                    <xsl:text> </xsl:text>
                                    <span class="protocol-count"><xsl:value-of select="format-number($protocol_count, '#.###', 'de')"/></span>
                                    <xsl:text> </xsl:text>
                                    <span data-i18n="index.protocolsDescSuffix">Protokolle aus Fraktions- und Gruppensitzungen
                                    des Deutschen Bundestags von 1949 bis 2005.</span>
                                </p>
                                <span class="feature-card-arrow">
                                    <span data-i18n="index.explore">Erkunden</span>
                                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3"/>
                                    </svg>
                                </span>
                            </a>

                            <!-- Personenverzeichnis Card -->
                            <a href="personenregister.html" class="feature-card" data-i18n="[title]index.personRegisterLink">
                                <xsl:attribute name="title">Zur Listenansicht der Personen</xsl:attribute>
                                <div class="feature-card-icon">
                                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                                            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
                                    </svg>
                                </div>
                                <h2 data-i18n="index.personRegisterTitle">Personenverzeichnis</h2>
                                <p>
                                    <span data-i18n="index.personRegisterDescPrefix">Das Personenverzeichnis umfasst aktuell</span>
                                    <xsl:text> </xsl:text>
                                    <span class="person-count"><xsl:value-of select="format-number($person_count, '#.###', 'de')"/></span>
                                    <xsl:text> </xsl:text>
                                    <span data-i18n="index.personRegisterDescSuffix">Einträge. Es erfasst Fraktionsmitglieder und weitere Personen aus dem parlamentarisch-politischen Umfeld zur Kontextualisierung ihrer Rollen und Aktivitäten.</span>
                                </p>
                                <span class="feature-card-arrow">
                                    <span data-i18n="index.explore">Erkunden</span>
                                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3"/>
                                    </svg>
                                </span>
                            </a>

                            <!-- Einleitungen Card -->
                            <a href="einleitungen.html" class="feature-card" data-i18n="[title]index.introductionsLink">
                                <xsl:attribute name="title">Zur Listenansicht der Einleitungen</xsl:attribute>
                                <div class="feature-card-icon">
                                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"
                                            d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                                    </svg>
                                </div>
                                <h2 data-i18n="index.introductionsTitle">Einleitungen</h2>
                                <p data-i18n="index.introductionsDesc">
                                    Jeder Printband der Edition enthält eine wissenschaftliche Einführung,
                                    die hier digital bereitgestellt wird und den historischen Kontext
                                    sowie den Forschungsstand erläutert.
                                </p>
                                <span class="feature-card-arrow">
                                    <span data-i18n="index.explore">Erkunden</span>
                                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8l4 4m0 0l-4 4m4-4H3"/>
                                    </svg>
                                </span>
                            </a>
                        </section>

                        <!-- Search Section -->
                        <section class="search-section">
                            <h2 data-i18n="search.fulltext">Volltextsuche über die gesamte Edition</h2>
                            <form class="search-form" id="search-form">
                                <input type="search" id="query" data-i18n="[placeholder]search.placeholder;[aria-label]search.label" placeholder="Suchbegriff eingeben..." aria-label="Volltextsuche" />
                                <button type="submit" id="search" aria-label="Suchen">
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                                    </svg>
                                </button>
                            </form>
                        </section>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />

                <script src="./js/index.js"></script>
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
