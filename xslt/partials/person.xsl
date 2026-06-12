<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    version="2.0" exclude-result-prefixes="xsl tei xs">

    <xsl:template match="tei:person" name="person_detail">
        <table class="kgparl-table entity-table">
            <tbody>
                <xsl:if test="./tei:birth/tei:date">
                    <tr>
                        <th>
                            Geburtsdatum
                        </th>
                        <td>
                            <xsl:value-of select="./tei:birth/tei:date" />
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="./tei:death/tei:date">
                    <tr>
                        <th>
                            Sterbedatum
                        </th>
                        <td>
                            <xsl:value-of select="./tei:death/tei:date" />
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="./tei:idno[@type='GND']/text()">
                    <tr>
                        <th>
                            GND ID
                        </th>
                        <td>
                            <a href="{./tei:idno[@type='GND']}" target="_blank">
                                <xsl:value-of
                                    select="tokenize(./tei:idno[@type='GND'][1], '/')[last()]" />
                            </a>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="./tei:idno[@type='WIKIDATA']/text()">
                    <tr>
                        <th>
                            Wikidata ID
                        </th>
                        <td>
                            <a href="{./tei:idno[@type='WIKIDATA']}" target="_blank">
                                <xsl:value-of
                                    select="tokenize(./tei:idno[@type='WIKIDATA'], '/')[last()]" />
                            </a>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="./tei:idno[@type='GEONAMES']/text()">
                    <tr>
                        <th>
                            Geonames ID
                        </th>
                        <td>
                            <a href="{./tei:idno[@type='GEONAMES']}" target="_blank">
                                <xsl:value-of
                                    select="tokenize(./tei:idno[@type='GEONAMES'], '/')[4]" />
                            </a>
                        </td>
                    </tr>
                </xsl:if>
            </tbody>
        </table>
    </xsl:template>
    <xsl:template name="GetMentions">
        <xsl:param name="hits" />
        <xsl:for-each-group select="$hits" group-by="base-uri(.)">
            <xsl:variable name="hit" select="." />
            <xsl:variable name="filename"
                select="replace(tokenize(current-grouping-key(), '/')[last()], '.xml', '')" />
            <xsl:variable name="root" select="root($hit)" />
            <xsl:variable name="date">
                <xsl:call-template name="GetDate">
                    <xsl:with-param name="protocol" select="$root" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="title" select="$root//tei:titleStmt/tei:title[@level='a']" />
            <xsl:variable name="party">
                <xsl:call-template name="GetParty">
                    <xsl:with-param name="protocol" select="root(.)" />
                </xsl:call-template>
            </xsl:variable>
            <tr>
                <td>
                    <li>
                        <a href="{$filename}.html" target="_self" alt="Zum Protokoll"><xsl:value-of
                                select="$date" /><xsl:text>&gt;</xsl:text><xsl:value-of select="$title" /><xsl:text>&gt;</xsl:text>
                            (<xsl:value-of select="$party" />)</a>
                    </li>
                </td>
            </tr>
        </xsl:for-each-group>
    </xsl:template>
    <xsl:template name="linkedDocuments">
        <xsl:param name="id" />
        <xsl:param name="count" />
        <xsl:message select="$id" />
        <xsl:message select="$count" />
        <!--<xsl:message
        select="$count" />-->
        <xsl:variable name="textpart">
            <xsl:choose>
                <xsl:when test="$count > 1 or $count = 0">
                    <!-- a class="kgparl-link" data-toggle="collapse" href="#counter"
                        role="button" aria-expanded="false" aria-controls="counter"
                    style="text-center">-->
                    <span class="kgparl-link">
                        <xsl:value-of select="$count" />
                    </span>
                    <br />
                    <!--                    </a>-->
                    <xsl:text>verbundene Dokumente</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <!-- <a class="kgparl-link" data-toggle="collapse" href="#counter"
                        role="button" aria-expanded="false" aria-controls="counter"
                    style="text-center">-->
                    <span class="kgparl-link">
                        <xsl:value-of select="$count" />
                    </span>
                    <br />
                    <!-- </a>-->
                    <xsl:text>verbundenes Dokument</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div class="linked-docs-card">
            <div class="linked-docs-body">
                <div class="linked-docs-header">
                    <xsl:copy-of select="$textpart" />
                </div>
            </div>
        </div>
    </xsl:template>


</xsl:stylesheet>
