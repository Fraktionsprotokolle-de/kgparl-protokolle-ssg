<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output media-type="text" encoding="UTF-8" omit-xml-declaration="yes"/>
    <xsl:import href="./partials/params.xsl"/>
    <xsl:template match="/">#FORMAT: BEACON<xsl:text>&#xa;</xsl:text>#PREFIX: https://d-nb.info/gnd//#NAME:<xsl:text>&#xa;</xsl:text>#FEED: https://www.fraktionsprotokolle.de/beacon_kgparl_gnd.txt<xsl:text>&#xa;</xsl:text>#TARGET: https://www.fraktionsprotokolle.de/person.html?id={ID}<xsl:text>&#xa;</xsl:text>#MESSAGE: Verzeichnis aller IDs mit GND in den Fraktionsprotokollen<xsl:text>&#xa;</xsl:text>#INSTITUTION: KGParl (juengerkes@kgparl.de)<xsl:text>&#xa;</xsl:text>#DESCRIPTION: Verzeichnis aller internen Personen-IDs für die eine GND-Nummer besteht. Zugriff auf Personen in der Edition mit GND-Nummer ist auch über https://www.fraktionsprotokolle.de/gnd/{GND-ID} möglich, bspw. https://www.fraktionsprotokolle.de/gnd/116005009<xsl:text>&#xa;</xsl:text>#TIMESTAMP:2024-10-07+02:00<xsl:text>&#xa;</xsl:text>#EXAMPLE: 11850066X||AdenauerKonrad_1949-09-07<xsl:text>&#xa;</xsl:text><xsl:for-each select=".//tei:person[.//tei:idno[@type='GND']/text() != '']"><xsl:value-of select="tokenize(.//tei:idno[@type='GND'][1], '/')[last()]"/>|<xsl:value-of select="[@xml:id]"/><xsl:text>&#xa;</xsl:text></xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
