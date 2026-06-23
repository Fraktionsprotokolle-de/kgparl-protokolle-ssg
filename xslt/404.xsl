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
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="yes" omit-xml-declaration="yes" />

    <xsl:import href="./partials/html_head.xsl" />
    <xsl:import href="./partials/html_navbar.xsl" />
    <xsl:import href="./partials/html_footer.xsl" />
    <xsl:import href="./partials/one_time_alert.xsl" />


    <xsl:template match="/">
        <xsl:variable name="doc_title">
            <xsl:value-of select='"KGParl Protokolle - 404 Not Found"' />
        </xsl:variable>
        <html lang="de">
            <head>
                <base href="/" />
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
            </head>
            <body>
                <xsl:call-template name="nav_bar" />

                <main class="main-content" id="main-content">
                    <div class="kgparl-container">
                        <div class="error-page">
                            <div class="error-code">404</div>
                            <h1 data-i18n="error.pageNotFound">Seite nicht gefunden</h1>
                            <p data-i18n="error.pageNotFoundMessage">Die gesuchte Seite konnte nicht gefunden werden. Bitte überprüfen Sie die URL oder versuchen Sie es erneut.</p>
                            <div class="error-actions">
                                <a href="index.html" class="kgparl-btn" data-i18n="error.backToHome">Zur Startseite</a>
                                <a href="liste.html" class="kgparl-btn-outline" data-i18n="error.toProtocols">Zu den Protokollen</a>
                            </div>
                        </div>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
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
