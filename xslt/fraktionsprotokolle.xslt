<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:local="http://dse-static.foo.bar"
>

  <xsl:output method="xml" indent="yes" />

  <xsl:function name="local:makeId" as="xs:string">
    <xsl:param name="currentNode" as="node()" />
    <xsl:variable name="nodeCurrNr">
      <xsl:value-of select="count($currentNode//preceding-sibling::*) + 1" />
    </xsl:variable>
    <xsl:value-of select="concat(name($currentNode), '__', $nodeCurrNr)" />
  </xsl:function>

  <xsl:function name="local:document-id-from-target" as="xs:string">
    <xsl:param name="target" as="xs:string?" />
    <xsl:variable name="id" select="replace(string($target), '^#', '')" />
    <xsl:variable name="tokens" select="tokenize($id, '_')" />
    <xsl:value-of select="if (count($tokens) ge 3) then string-join(subsequence($tokens, 1, 3), '_') else $id" />
  </xsl:function>

  <xsl:function name="local:normalize-document-id" as="xs:string">
    <xsl:param name="documentId" as="xs:string?" />
    <xsl:value-of select="replace(string($documentId), '^([^_]+_[0-9]{4}-[0-9]{2}-[0-9]{2}-t[0-9]{4})0(_[^_]+)$', '$1$2')" />
  </xsl:function>

  <xsl:function name="local:html-anchor-id-from-internal-target" as="xs:string">
    <xsl:param name="target" as="xs:string?" />
    <xsl:variable name="id" select="replace(string($target), '^#', '')" />
    <xsl:variable name="tokens" select="tokenize($id, '_')" />
    <xsl:variable name="target-document-id" select="local:document-id-from-target($id)" />
    <xsl:variable name="has-document-prefix" select="count($tokens) ge 3" />
    <xsl:choose>
      <xsl:when test="$has-document-prefix and count($tokens) = 4 and not(contains($id, 'FN'))">
        <xsl:value-of select="concat(local:normalize-document-id($target-document-id), '_div_', $tokens[4])" />
      </xsl:when>
      <xsl:when test="$has-document-prefix">
        <xsl:value-of select="concat(local:normalize-document-id($target-document-id), substring($id, string-length($target-document-id) + 1))" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$id" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="local:html-href-from-internal-target" as="xs:string">
    <xsl:param name="target" as="xs:string?" />
    <xsl:variable name="target-string" select="string($target)" />
    <xsl:choose>
      <xsl:when test="starts-with($target-string, '#')">
        <xsl:value-of select="concat('#', local:html-anchor-id-from-internal-target($target-string))" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="resource" select="if (contains($target-string, '#')) then substring-before($target-string, '#') else $target-string" />
        <xsl:variable name="fragment" select="if (contains($target-string, '#')) then substring-after($target-string, '#') else ''" />
        <xsl:variable name="html-resource" select="replace($resource, '\.xml$', '.html')" />
        <xsl:value-of select="if ($fragment != '') then concat($html-resource, '#', local:html-anchor-id-from-internal-target($fragment)) else $html-resource" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="local:trailing-note-for-quote" as="element()?">
    <xsl:param name="quote" as="element(tei:quote)" />
    <xsl:variable name="following-note"
      select="$quote/following-sibling::*[1][self::tei:seg[@type='note'] or self::tei:note]" />
    <xsl:variable name="between-text"
      select="$quote/following-sibling::text()[. &lt;&lt; $following-note]" />
    <xsl:sequence
      select="if (exists($following-note) and not(matches(string-join($between-text, ''), '[\p{L}\p{N}]'))) then $following-note else ()" />
  </xsl:function>

  <xsl:function name="local:is-attached-to-preceding-quote" as="xs:boolean">
    <xsl:param name="node" as="element()" />
    <xsl:variable name="preceding-quote"
      select="$node/preceding-sibling::*[1][self::tei:quote]" />
    <xsl:sequence
      select="exists($preceding-quote) and exists(local:trailing-note-for-quote($preceding-quote)[. is $node])" />
  </xsl:function>

  <!-- caching -->
  <xsl:key name="persons-by-id" match="tei:person" use="@xml:id" />
  <xsl:key name="org-by-id" match="tei:org" use="@xml:id" />
  <xsl:key name="orgs-by-id" match="tei:org" use="@xml:id" />
  <xsl:key name="category-by-id" match="tei:category" use="@xml:id" />

  <!-- prefetch register files -->
  <xsl:variable name="persons" select="document('../data/indices/Personen.xml')" />
  <xsl:variable name="orgs" select="document('../data/indices/Organisationen.xml')" />
  <xsl:variable name="keywords" select="document('../data/indices/tei-fpv.xml')" />

  <xsl:key name="keyword-by-id" match="tei:item" use="@xml:id" />

  <xsl:template name="translate-category">
    <!-- Input parameters: key (category key), index (optional index value) -->
    <xsl:param name="key" />
    <xsl:param name="categories" />
    <!-- Retrieve the category name from the listcategory.xml file using the provided key -->

    <xsl:variable name="name"
      select="key('category-by-id', $key, $categories)/tei:catDesc" />
    <!-- Normalize the category name -->
    <xsl:value-of select="normalize-space($name)" />
  </xsl:template>

  <!-- Template for translating a person key into the corresponding name -->
  <xsl:template name="translate-person">
    <!-- Input parameters: key (person key), index (optional index value) -->
    <xsl:param name="key" />
    <!-- Retrieve the person name from the listperson.xml file using the provided key -->

    <xsl:variable name="person" select="key('persons-by-id', $key, $persons)" />
    <xsl:variable name="namedPersName" select="$person/tei:persName[@n='1']" />
    <!-- Use persName[@type='display'] if available, otherwise forename + surname -->
    <xsl:choose>
      <xsl:when test="$person/tei:persName[@type='display']">
        <xsl:value-of select="normalize-space($person/tei:persName[@type='display']/text())" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="normalize-space(concat($namedPersName/tei:forename, ' ', $namedPersName//tei:roleName[not(@type='honorific')], ' ', $namedPersName/tei:surname))" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Template for translating a keyword (FPV) key into the preferred label -->
  <xsl:template name="translate-keyword">
    <xsl:param name="key" />
    <xsl:variable name="entry" select="key('keyword-by-id', $key, $keywords)" />
    <xsl:value-of select="normalize-space($entry/tei:term[@type='pref'])" />
  </xsl:template>

  <!-- Template for translating an organization key into the corresponding name -->
  <xsl:template name="translate-org">
    <!-- Input parameters: key (organization key), index (optional index value) -->
    <xsl:param name="key" />
    <!-- Retrieve the organization name from the listorg.xml file using the provided key -->
    <xsl:variable name="name"
      select="key('orgs-by-id', $key, $orgs)/tei:orgName[@type='full']" />
    <!-- Normalize the organization name -->
    <xsl:value-of select="normalize-space($name)" />
  </xsl:template>

  <!-- Identity transform -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="tei:TEI">
    <xsl:apply-templates />
  </xsl:template>


  <xsl:template match="tei:div[@type='SVP']">
    <div class="svp-section">
      <xsl:apply-templates />
    </div>
  </xsl:template>

  <xsl:template match="tei:div">
    <div>
      <xsl:apply-templates />
    </div>
  </xsl:template>


  <xsl:template match="tei:list">
    <ul class="tei-list">
      <xsl:apply-templates />
    </ul>
  </xsl:template>

  <!-- Item mit Label: Label übernehmen -->
  <xsl:template match="tei:item[tei:label]">
    <li class="tei-item">
      <span class="tei-label"><xsl:value-of select="tei:label" /></span>
      <span class="tei-item-content">
        <xsl:apply-templates select="*[not(self::tei:label)]|text()[not(preceding-sibling::tei:label or following-sibling::tei:label)]" />
      </span>
    </li>
  </xsl:template>

  <!-- Item ohne Label: Strich als Marker -->
  <xsl:template match="tei:item[not(tei:label)]">
    <li class="tei-item">
      <span class="tei-label">–</span>
      <span class="tei-item-content">
        <xsl:apply-templates />
      </span>
    </li>
  </xsl:template>

  <!-- Label wird über das item-Template verarbeitet, hier unterdrücken -->
  <xsl:template match="tei:label[parent::tei:item]" />

  <xsl:template match="tei:ref">


    <xsl:if test="not(@type='internal') and @target">
      <tei:target>
        <xsl:value-of select="@target" />
      </tei:target>
    </xsl:if>

    <xsl:if test="@type='internal'">
      <xsl:choose>
        <xsl:when test="starts-with(string(@target), '#')">
          <a href="{local:html-href-from-internal-target(@target)}" class="kgparl-link">
            <xsl:apply-templates />
          </a>
        </xsl:when>
        <xsl:otherwise>
          <a href="{local:html-href-from-internal-target(@target)}" class="kgparl-link" target="_blank" rel="noopener">
            <xsl:apply-templates />
          </a>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

  </xsl:template>

  <!-- tei:hi - Hervorhebungen -->
  <xsl:template match="tei:hi[@rendition='#smcap']">
    <span style="font-variant: small-caps;">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="tei:hi[@rend='bold']">
    <strong>
      <xsl:apply-templates/>
    </strong>
  </xsl:template>

  <xsl:template match="tei:hi[@rend='italic']">
    <em>
      <xsl:apply-templates/>
    </em>
  </xsl:template>

  <xsl:template match="tei:hi[@rend='underline']">
    <span style="text-decoration: underline;">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="tei:hi">
    <span>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- tei:incident und tei:desc - Zwischenrufe/Reaktionen -->
  <xsl:template match="tei:incident">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="tei:desc">
    <span class="tei-desc">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- tei:name[@type='Organisation'] - Organisationsnamen -->
  <xsl:template match="tei:name[@type='Organisation']">
    <xsl:variable name="ref" select="@ref"/>
    <xsl:variable name="id" select="if (contains($ref, '#')) then substring-after($ref, '#') else $ref"/>
    <span class="org-mention" style="color: #666666;" id="{$ref}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- tei:quote in Zwischenrufen/Incidents: keine Sonderformatierung,
       Inhalt wird als reiner Inline-Text in den Klammertext durchgereicht
       (sonst bricht das Layout des Zwischenrufs). -->
  <xsl:template match="tei:quote[ancestor::tei:incident or ancestor::tei:desc]" priority="2">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- tei:quote - Zitate: kompakt innerhalb von p (auch verschachtelt),
       sonst Block. Wichtig: niemals <blockquote> innerhalb von <p> erzeugen,
       sonst schließt der Browser das <p> auto und der Randziffer-Counter
       bekommt einen Phantom-Absatz. -->
  <xsl:template match="tei:quote[ancestor::tei:p]">
    <xsl:variable name="trailing-note" select="local:trailing-note-for-quote(.)" />
    <span class="tei-quote tei-quote-compact">
      <xsl:apply-templates/>
      <xsl:if test="exists($trailing-note)">
        <xsl:for-each select="following-sibling::text()[. &lt;&lt; $trailing-note]">
          <xsl:value-of select="." />
        </xsl:for-each>
        <xsl:apply-templates select="$trailing-note" mode="quote-trailing-note" />
      </xsl:if>
    </span>
  </xsl:template>

  <xsl:template
    match="text()[preceding-sibling::*[1][self::tei:quote] and following-sibling::*[1][self::tei:seg[@type='note'] or self::tei:note]]"
    priority="2">
    <xsl:variable name="preceding-quote" select="preceding-sibling::*[1][self::tei:quote]" />
    <xsl:variable name="following-note"
      select="following-sibling::*[1][self::tei:seg[@type='note'] or self::tei:note]" />
    <xsl:choose>
      <xsl:when test="exists(local:trailing-note-for-quote($preceding-quote)[. is $following-note])" />
      <xsl:otherwise>
        <xsl:value-of select="." />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:quote">
    <blockquote class="tei-quote">
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>


  <xsl:template match="tei:pb">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="tei:lg">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="tei:l">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="tei:figure">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="tei:graphic">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="tei:table">
    <table class="kgparl-table">
      <xsl:apply-templates />
    </table>
  </xsl:template>

  <xsl:template match="tei:row">
    <tr>
      <xsl:apply-templates />
    </tr>
  </xsl:template>

  <xsl:template match="tei:cell">
    <td>
      <xsl:apply-templates />
    </td>
  </xsl:template>

  <xsl:template match="tei:bibl">

    <xsl:choose>

      <xsl:when test="@type='bgbl'">
        <xsl:choose>
          <xsl:when test="tei:ref[@target]">
            <xsl:variable name="parts" select="tokenize(./tei:ref[1]/@target, '/')" />
            <xsl:variable name="url"
              select="concat('https://offenegesetze.de/veroeffentlichung/bgbl', $parts[2], '/', $parts[1], '/', $parts[3])" />
            <a href="{$url}" class="kgparl-link" target="_new">
              <xsl:value-of select="." />
            </a>
          </xsl:when>
          <xsl:otherwise>
            <span class="tei-bibl"><xsl:value-of select="." /></span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="@type='btp'">
        <xsl:choose>
          <xsl:when test="tei:ref[@target]">
            <xsl:variable name="parts" select="tokenize(./tei:ref[1]/@target, '/')" />
            <xsl:variable name="wp"
              select="if(string-length($parts[1]) = 1) then concat('0', $parts[1]) else $parts[1]" />
            <xsl:variable name="meeting"
              select="concat( substring('000', string-length($parts[2]) +1 ), $parts[2])" />
            <xsl:variable name="url"
              select="concat('https://dserver.bundestag.de/btp/' , $wp , '/', $wp,  $meeting ,'.pdf')" />
            <a href="{$url}" class="kgparl-link" target="_new">
              <xsl:value-of select="." />
            </a>
          </xsl:when>
          <xsl:otherwise>
            <span class="tei-bibl"><xsl:value-of select="." /></span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="@type='btd'">
        <xsl:choose>
          <xsl:when test="tei:ref[@target]">
            <xsl:variable name="parts" select="tokenize(./tei:ref[1]/@target, '/')" />
            <xsl:variable name="meeting"
              select="concat( substring('00000', string-length($parts[2]) +1 ), $parts[2])" />
            <xsl:variable name="prefix"
              select="substring($meeting, 1, 3)" />
            <xsl:variable name="url"
              select="concat('https://dserver.bundestag.de/btd/' , $parts[1], '/', $prefix, '/', $parts[1], $meeting, '.pdf')" />
            <a href="{$url}" class="kgparl-link" target="_new">
              <xsl:value-of select="." />
            </a>
          </xsl:when>
          <xsl:otherwise>
            <span class="tei-bibl"><xsl:value-of select="." /></span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="@type='dip' or (@type='kbp' and tei:ref[@target])">
        <span class="tei-bibl">
          <xsl:apply-templates />
        </span>
      </xsl:when>
      <xsl:when test="@type">
        <xsl:value-of select="." />
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="parent::tei:listBibl">
            <li class="tei-bibl">
              <xsl:apply-templates />
            </li>
          </xsl:when>
          <xsl:otherwise>
            <span class="tei-bibl">
              <xsl:apply-templates />
            </span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:bibl[@type='dip']/tei:ref[@target] | tei:bibl[@type='kbp']/tei:ref[@target]">
    <a href="{@target}" class="kgparl-link" target="_blank" rel="noopener">
      <xsl:apply-templates />
    </a>
  </xsl:template>

  <xsl:template name="render-note">
    <xsl:variable name="fn">
      <xsl:number level="any" format="1" count="tei:note" from="tei:body" />
    </xsl:variable>
    <xsl:variable name="fn_ref">
      <xsl:choose>
        <xsl:when test="@xml:id">
          <xsl:value-of select="concat('fnref_', @xml:id)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('fnref_', $fn)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="fn-id">
      <xsl:value-of select="concat('fn', $fn)" />
    </xsl:variable>
    <span class="text-decoration-none text-start seg-note fn" rel="footnote">

      <popup-info>
        <xsl:attribute name="data-html">false</xsl:attribute>

        <xsl:attribute name="data-title">
          <xsl:apply-templates />

        </xsl:attribute>

        <a href="#{$fn-id}" class="seg-note-link fn" rel="footnote" role="doc-noteref" aria-label="Fußnote {$fn}" id="{$fn_ref}">
          <xsl:value-of select="$fn" />
        </a>
      </popup-info>

    </span>
  </xsl:template>

  <xsl:template match="tei:note">
    <xsl:if test="not(local:is-attached-to-preceding-quote(.))">
      <xsl:call-template name="render-note" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:note" mode="quote-trailing-note">
    <xsl:call-template name="render-note" />
  </xsl:template>

  <xsl:template name="render-note-segment">
    <xsl:choose>
      <xsl:when test="normalize-space()">
        <xsl:variable name="segment-class">
          <xsl:text>note-segment</xsl:text>
          <xsl:if test="ancestor::tei:quote or .//tei:quote[exists(local:trailing-note-for-quote(.))]">
            <xsl:text> note-segment-quote-context</xsl:text>
          </xsl:if>
        </xsl:variable>
        <span class="{$segment-class}" onclick="">
          <xsl:apply-templates />
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tei:seg[@type='note']">
    <xsl:if test="not(local:is-attached-to-preceding-quote(.))">
      <xsl:call-template name="render-note-segment" />
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:seg[@type='note']" mode="quote-trailing-note">
    <xsl:call-template name="render-note-segment" />
  </xsl:template>

  <xsl:template match="tei:p[parent::tei:note]">
    <p>
      <xsl:apply-templates />
    </p>
  </xsl:template>

  <xsl:template match="tei:p[parent::tei:item]">
    <p class="tei-item-p">
      <xsl:apply-templates />
    </p>
  </xsl:template>

  <xsl:template match="tei:p">
    <p>
      <xsl:apply-templates />
    </p>
  </xsl:template>

  <xsl:template match="tei:name[@type='Person'][@role='Erwaehnung']">
    <span class="person-mention italic" aria-haspopup="true" id="{@ref}">
      <xsl:variable name="name">
        <xsl:call-template name="translate-person">
          <xsl:with-param name="key" select="replace(@ref, '#', '')" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="id">
        <xsl:value-of select="replace(@ref, '#', '')" />
      </xsl:variable>
      <xsl:call-template name="makePopover">
        <xsl:with-param name="title" select="$name" />
        <xsl:with-param name="content" select="$id" />
        <xsl:with-param name="html" select="true()" />
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
    </span>
  </xsl:template>
  <xsl:template match="tei:name[@type='Person'][@role='Sprecher']">
    <span class="fw-bold" id="{@ref}" aria-haspopup="true">
      <span slot="content" />
      <xsl:variable name="name">
        <xsl:call-template name="translate-person">
          <xsl:with-param name="key" select="replace(@ref, '#', '')" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="id">
        <xsl:value-of select="replace(@ref, '#', '')" />
      </xsl:variable>
      <xsl:call-template name="makePopover">
        <xsl:with-param name="title" select="$name" />
        <xsl:with-param name="content" select="$id" />
        <xsl:with-param name="html" select="true()" />
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
    </span>
  </xsl:template>
  <!-- tei:term[@ref] - Schlagwort-Referenz mit Popup und Link zur Detailseite -->
  <xsl:template match="tei:term[@ref]">
    <xsl:variable name="id" select="replace(@ref, '#', '')" />
    <xsl:variable name="prefLabel">
      <xsl:call-template name="translate-keyword">
        <xsl:with-param name="key" select="$id" />
      </xsl:call-template>
    </xsl:variable>
    <span class="keyword-ref">
      <xsl:call-template name="makePopover">
        <xsl:with-param name="title" select="$prefLabel" />
        <xsl:with-param name="content" select="$id" />
        <xsl:with-param name="html" select="true()" />
        <xsl:with-param name="text" select="." />
      </xsl:call-template>
    </span>
  </xsl:template>

  <!-- tei:lb - Zeilenumbruch -->
  <xsl:template match="tei:lb">
    <br />
  </xsl:template>

  <!-- tei:choice/tei:abbr + tei:expan - Abkürzungen mit gestrichelter Linie und Mouseover -->
  <xsl:template match="tei:choice[tei:abbr]">
    <abbr class="tei-abbr" title="{tei:expan}">
      <popup-info data-html="false" data-title="{tei:expan}">
        <xsl:value-of select="tei:abbr" />
      </popup-info>
    </abbr>
  </xsl:template>

  <xsl:template match="tei:head">
    <xsl:choose>
      <xsl:when test="parent::tei:div[@type='SVP']">
        <xsl:variable name="corresp" select="parent::tei:div/@xml:id" />
        <h2 class="text-start fw-bold" id="{$corresp}">
          <xsl:apply-templates />
        </h2>
      </xsl:when>
      <xsl:when test="parent::div[@type='Anwesenheitsliste']">
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="corresp" select="parent::tei:div/@xml:id" />
        <h2 class="text-start fw-bold" id="{$corresp}">
          <xsl:apply-templates />
        </h2>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="makePopover">
    <xsl:param name="title" />
    <xsl:param name="content" />
    <xsl:param name="html" />
    <xsl:param name="text" />
    <popup-info>
      <xsl:attribute name="data-html">true</xsl:attribute>
      <xsl:attribute name="data-title">
        <xsl:value-of select="$title" />
      </xsl:attribute>
      <xsl:attribute name="data-content">
        <xsl:text disable-output-escaping="yes">&lt;a class='kgparl-link' href='</xsl:text>
        <xsl:value-of select="$content" />
        <xsl:text disable-output-escaping="yes">.html'&gt;</xsl:text>
        <xsl:text>Weitere Daten</xsl:text>
        <xsl:text disable-output-escaping="yes">&lt;/a&gt;</xsl:text>
      </xsl:attribute>

      <xsl:value-of select="$text" />
    </popup-info>
  </xsl:template>

  <xsl:template name="facets">
    <xsl:param name="entry" />
    <xsl:variable name="facet-list"
      select="$entry//tei:name[@type='Person']" />
    <xsl:variable name="total-facets" select="count(distinct-values($facet-list/@ref))" />
    <ul class="overflow-x-hidden facet-list">
      <xsl:for-each-group select="$facet-list" group-by="@ref">
        <xsl:sort select="count(current-group())" order="descending" />
        <xsl:sort select="current-grouping-key()" />
        <xsl:variable name="facet-key">
          <xsl:value-of select="replace(@ref, '#','')" />
        </xsl:variable>
        <xsl:variable name="facet" select="key('persons-by-id', $facet-key, $persons)" />
        <xsl:variable name="facet-name">
          <xsl:choose>
            <xsl:when test="$facet/tei:persName[@n='1']/tei:addName[@type='praefix'] != ''">
              <xsl:value-of select="concat($facet/tei:persName[@n='1']/tei:surname, ', ', $facet/tei:persName[@n='1']/tei:forename, ' ', $facet/tei:persName[@n='1']/tei:addName[@type='praefix'])" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat($facet/tei:persName[@n='1']/tei:surname, ', ', $facet/tei:persName[@n='1']/tei:forename)" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <li>
          <xsl:if test="position() &gt; 10">
            <xsl:attribute name="class">facet-overflow hidden</xsl:attribute>
          </xsl:if>
          <custom-checkbox>
            <xsl:attribute name="key">
              <xsl:value-of select="$facet-key" />
            </xsl:attribute>
            <xsl:attribute name="color">
              <xsl:text>rgb(4,130,99)</xsl:text>
            </xsl:attribute>
            <xsl:value-of select="$facet-name" />
            <xsl:text> (</xsl:text>
            <xsl:value-of select="count(current-group())" />
            <xsl:text>)</xsl:text>
          </custom-checkbox>
        </li>
      </xsl:for-each-group>
    </ul>
    <xsl:if test="$total-facets &gt; 10">
      <button type="button" class="kgparl-btn-outline facet-show-more" onclick="this.previousElementSibling.querySelectorAll('.facet-overflow').forEach(function(el){{el.classList.toggle('hidden')}});this.textContent=this.textContent==='Mehr anzeigen…'?'Weniger anzeigen…':'Mehr anzeigen…';">Mehr anzeigen…</button>
    </xsl:if>
  </xsl:template>

  <xsl:template name="MakeList">
    <xsl:param name="entry" />
    <div class="info-block"
      style="background-color:  var(  --color-background-light);">
      <ul id="svplist">
        <xsl:for-each select="$entry//tei:text//tei:list[@type='SVP']/tei:item">
          <li>
            <a href="#{replace(./@corresp, '#', '')}" class="kgparl-link">
              <xsl:value-of select="string-join(.//text()[not(ancestor::tei:expan)], '')" />
            </a>
          </li>
        </xsl:for-each>
      </ul>
    </div>
  </xsl:template>
  <xsl:template name="MakeCitation">
    <xsl:param name="entry" />
    <xsl:param name="party" />
    <xsl:param name="period" />
    <xsl:param name="doc_title" />
    <xsl:variable name="header" select="root($entry)//tei:teiHeader" />
    <xsl:variable name="categories"
      select="$header//tei:taxonomy[@xml:id='FP-Dokumenttyp']" />
    <xsl:variable name="session"
      select="$header/tei:profileDesc[1]/tei:creation[1]/tei:idno[1]/tei:idno[@type='sitzungsabfolge']">
    </xsl:variable>
    <xsl:variable name="title"
      select="data($header//tei:teiHeader//tei:fileDesc/tei:titleStmt/tei:title[@level='a'])" />
    <xsl:choose>
      <xsl:when test="(data($header//tei:teiHeader//tei:taxonomy/tei:category/@xml:id) = 'EINL')">
        <h2>
          <xsl:value-of select="$title" />
        </h2>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="type"
          select="data($header/tei:profileDesc[1]/tei:textClass[1]/tei:catRef[1]/@scheme)" />
        <xsl:variable name="amount"
          select="$header/descendant-or-self::tei:fileDesc[1]/tei:sourceDesc[1]/tei:listObject[1]/tei:object[1]/tei:physDesc[1]/tei:objectDesc[1]/tei:supportDesc/tei:extent" />
        <xsl:variable name="editor_count"
          select="count($header/descendant-or-self::tei:fileDesc[1]/tei:titleStmt[1]/tei:editor[1]/tei:name)" />
        <!-- calculated date -->
        <xsl:variable name="date">
          <xsl:choose>
            <xsl:when test="$header//tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@when">
              <xsl:value-of select="$header/tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@when" />
            </xsl:when>
            <xsl:when test="$header/tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@from">
              <xsl:value-of select="$header/tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@from" />
            </xsl:when>
            <xsl:otherwise />
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="date_array" select="tokenize($date, '-')" />
        <xsl:variable name="date_final">
          <xsl:if test="$date">
            <!-- if date is available, format date from yyyy-mm-dd to dd.mm.yyyy -->
            <xsl:variable name="formated_Date">
              <xsl:call-template name="MakeDate">
                <xsl:with-param name="date" select="$date" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="$formated_Date" />
          </xsl:if>
        </xsl:variable>
        <!-- Persons listed as csv -->
        <xsl:variable name="editor">
          <xsl:for-each
            select="$header//tei:fileDesc/tei:titleStmt/tei:editor/tei:name[@type='Person']">
            <xsl:choose>
              <xsl:when test="position() > 1">
                <xsl:text>, </xsl:text>
                <xsl:call-template name="translate-person">
                  <xsl:with-param name="key"
                    select="replace(@ref, '#', '')" />
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="translate-person">
                  <xsl:with-param name="key" select="replace(@ref, '#', '')" />
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>


          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="lead">
          <xsl:for-each
            select="$header//tei:profileDesc[1]/tei:creation[1]/tei:name[@type='Person']">
            <xsl:if test="position() > 1">
              <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:call-template name="translate-person">
              <xsl:with-param name="key"
                select="replace(@ref, '#', '')" />
            </xsl:call-template>
          </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="object"
          select="$header/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listObject[1]/tei:object[1]/tei:objectIdentifier[1]/tei:objectName[1]/text()" />
        <xsl:variable name="isArticle"
          select="exists($header/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listObject[1]/tei:object[1]/tei:objectIdentifier[1]/tei:altIdentifier[1]/tei:idno[1])" />
        <xsl:variable name="altOrigin">
          <xsl:if test="$isArticle">
            <xsl:value-of
              select="$header/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listObject[1]/tei:object[1]/tei:objectIdentifier[1]/tei:altIdentifier[1]/tei:idno[1]/text()" />
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="origin">
          <xsl:choose>
            <xsl:when test="$isArticle">
              <xsl:value-of select="concat($object, ', ', $altOrigin)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of
                select="$header/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listObject[1]/tei:object[1]/tei:objectIdentifier[1]/tei:institution[1]/text()" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="origin_nr"
          select="$header/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listObject[1]/tei:object[1]/tei:objectIdentifier[1]/tei:idno[1]/text()" />
        <xsl:variable name="template">
          <xsl:if test="not($isArticle)">
            <xsl:value-of
              select="$header/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listObject[1]/tei:object[1]/tei:physDesc[1]/tei:objectDesc[1]/tei:supportDesc[1]/tei:support[1]/text()" />
          </xsl:if>
        </xsl:variable>

        <xsl:variable name="duration"
          select="$header/tei:profileDesc[1]/tei:creation[1]/tei:date[1]/time[3]/@dur" />
        <xsl:variable name="location"
          select="$header/tei:profileDesc[1]/tei:creation[1]/tei:name[@type='Ort']/text()" />

        <!-- transformed date -->
        <xsl:variable name="from"
          select="substring($header/tei:profileDesc[1]/tei:creation[1]/tei:date[1]/tei:time[@type='start']/@when, 1, 5)" />
        <xsl:variable name="to"
          select="substring($header/tei:profileDesc[1]/tei:creation[1]/tei:date[1]/tei:time[@type='end']/@when, 1, 5)" />

        <!-- Make Protocol type cache -->

        <xsl:variable name="protocol_"
          select="replace($header//tei:profileDesc[1]//tei:textClass/tei:catRef/@target, '#', '')" />


        <xsl:variable name="protocol">
          <xsl:call-template name="translate-category">
            <xsl:with-param name="key" select="$protocol_" />
            <xsl:with-param name="categories" select="$categories" />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="document" select="tokenize(base-uri($header), '/')" />
        <xsl:variable name="doc" select="replace($document[last()], '.xml$', '.html')" />

        <div class="info-block"
          style="background-color: rgb(250, 250, 250);">
          <!-- Zeile 1: Vorlage, Titel, Umfang, Protokolltyp, Ediert durch -->
          <b>Vorlage:</b><xsl:text> </xsl:text><xsl:value-of
            select="$origin" />, <xsl:value-of
            select="$origin_nr" />. <xsl:value-of select="$object" />. <xsl:if test="$amount">
            <b>Umfang:</b><xsl:text> </xsl:text><xsl:value-of select="$template" />: <xsl:value-of
              select="$amount" />. </xsl:if>
          <b>Protokolltyp:</b><xsl:text> </xsl:text><xsl:value-of
            select="$protocol" />. <b>Ediert durch:</b><xsl:text> </xsl:text><xsl:value-of
            select="$editor" />.

          <!-- Zeile 2: Sitzungsdetails -->
          <div class="info-block-row">
          <xsl:if test="$from">
            <b>Beginn der Sitzung:</b><xsl:text> </xsl:text><xsl:value-of select="$from" /> Uhr. </xsl:if>
          <xsl:if test="$to">
            <b>Ende der Sitzung:</b><xsl:text> </xsl:text><xsl:value-of select="$to" /> Uhr. </xsl:if>
          <xsl:if test="$duration">
            <b>Sitzungsdauer:</b><xsl:text> </xsl:text><xsl:value-of select="$duration" />. </xsl:if>
          <b>Sitzungsvorsitz:</b><xsl:text> </xsl:text><xsl:for-each
            select="$header//tei:profileDesc[1]/tei:creation[1]/tei:name[@type='Person']">
            <xsl:if test="position() > 1"><xsl:text>, </xsl:text></xsl:if>
            <xsl:variable name="personKey" select="replace(@ref, '#', '')" />
            <xsl:variable name="personName">
              <xsl:choose>
                <xsl:when test="@role='Sitzungsleitung' and normalize-space(.)">
                  <xsl:value-of select="normalize-space(.)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="translate-person">
                    <xsl:with-param name="key" select="$personKey" />
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <span class="person-mention" aria-haspopup="true" id="#{$personKey}">
              <xsl:call-template name="makePopover">
                <xsl:with-param name="title" select="$personName" />
                <xsl:with-param name="content" select="$personKey" />
                <xsl:with-param name="html" select="true()" />
                <xsl:with-param name="text" select="$personName" />
              </xsl:call-template>
            </span>
          </xsl:for-each>. <b>Sitzungsort:</b><xsl:text> </xsl:text><xsl:value-of
            select="$location" />.
          </div>

          <!-- Zeile 3: Zitiervorschlag -->
          <div class="info-block-row">
          <b>Zitiervorschlag:</b><xsl:text> </xsl:text><xsl:value-of
              select="$doc_title" /> am <xsl:value-of select="$date_final" /> (<xsl:value-of
              select="$party" />). In: Editionsprogramm »Fraktionen im Deutschen Bundestag
          1949–2005«, online. <xsl:value-of select="$base_url" />/<xsl:value-of select="$doc" /> (abgerufen am <xsl:value-of
              select="format-date(current-date(), '[D01].[M01].[Y0001]')" />).
          </div>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="MakeDate">
    <xsl:param name="date" />
    <xsl:choose>
      <xsl:when test="string-length($date) = 10">
        <xsl:value-of select="format-date(xs:date($date), '[D01].[M01].[Y]')" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$date" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Helper -->
  <xsl:template name="GetParty">
    <xsl:param name="protocol" />
    <xsl:value-of select="$protocol//tei:profileDesc//tei:idno[@type='Fraktion-Landesgruppe']" />
  </xsl:template>

  <xsl:template name="PureDate">
    <xsl:param name="protocol" />

    <xsl:choose>
      <xsl:when test="$protocol//tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@when">
        <xsl:value-of select="$protocol//tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@when" />
      </xsl:when>
      <xsl:when test="$protocol//tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@from">
        <xsl:value-of select="$protocol//tei:profileDesc[1]/tei:creation[1]/tei:date[1]/@from" />
      </xsl:when>
      <xsl:otherwise />
    </xsl:choose>
  </xsl:template>

  <xsl:template name="GetDate">
    <xsl:param name="protocol" />
    <xsl:variable name="date">
      <xsl:call-template name="PureDate">
        <xsl:with-param name="protocol" select="$protocol" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="date_array" select="tokenize($date, '-')" />
    <xsl:variable name="date_final">
      <xsl:if test="$date">
        <!-- if date is available, format date from yyyy-mm-dd to dd.mm.yyyy -->
        <xsl:variable name="formated_Date">
          <xsl:call-template name="MakeDate">
            <xsl:with-param name="date" select="$date" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$formated_Date" />
      </xsl:if>
    </xsl:variable>
    <xsl:value-of select="$date_final" />
  </xsl:template>

  <xsl:template name="GetPeriod">
    <xsl:param name="protocol" />
    <xsl:value-of select="$protocol//tei:profileDesc//tei:idno[@type='wp']" />
  </xsl:template>

  <!-- ========================================================================
       TEI-Element-Templates
       ======================================================================== -->

  <!-- tei:gap - Textlücke in der Vorlage, dargestellt als {…} in Grau -->
  <xsl:template match="tei:gap">
    <span class="editorial-gap">{…}</span>
  </xsl:template>

  <!-- tei:unclear - ignorieren, Textinhalt durchreichen -->
  <xsl:template match="tei:unclear">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- tei:said - wie quote (blockquote) -->
  <xsl:template match="tei:said">
    <blockquote class="tei-quote">
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <!-- tei:soCalled - ignorieren, Textinhalt durchreichen -->
  <xsl:template match="tei:soCalled">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- tei:pause - Darstellung wie Incident in Klammern mit Dauerangabe.
       Wertet @dur im ISO-8601-Format (z.B. PT01H00M00S) aus. -->
  <xsl:template match="tei:pause">
    <span class="tei-pause">
      <xsl:text>(Pause</xsl:text>
      <xsl:if test="@dur">
        <xsl:variable name="d" select="replace(@dur, '^PT', '')" />
        <xsl:variable name="hours" select="if (contains($d, 'H')) then substring-before($d, 'H') else ''" />
        <xsl:variable name="afterH" select="if (contains($d, 'H')) then substring-after($d, 'H') else $d" />
        <xsl:variable name="minutes" select="if (contains($afterH, 'M')) then substring-before($afterH, 'M') else ''" />
        <xsl:variable name="afterM" select="if (contains($afterH, 'M')) then substring-after($afterH, 'M') else $afterH" />
        <xsl:variable name="seconds" select="if (contains($afterM, 'S')) then substring-before($afterM, 'S') else ''" />
        <xsl:text> von </xsl:text>
        <xsl:if test="$hours != '' and $hours != '00' and $hours != '0'"><xsl:value-of select="$hours" />h, </xsl:if>
        <xsl:if test="$minutes != ''"><xsl:value-of select="$minutes" /> Min.</xsl:if>
        <xsl:if test="$seconds != '' and $seconds != '00' and $seconds != '0'">, <xsl:value-of select="$seconds" /> Sek.</xsl:if>
      </xsl:if>
      <xsl:text>)</xsl:text>
    </span>
  </xsl:template>

  <!-- tei:author innerhalb von bibl - Kapitälchen -->
  <xsl:template match="tei:author[ancestor::tei:bibl or ancestor::tei:listBibl]">
    <span class="tei-author-bibl">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- tei:author außerhalb von bibl - Textinhalt durchreichen -->
  <xsl:template match="tei:author">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- tei:choice/tei:abbr - Abkürzungen mit gestrichelter Linie und Mouseover -->
  <!-- (Überschreibt das vorhandene Template oben nicht, da es identisch matcht;
       das bestehende Template bei Zeile ~430 bleibt aktiv) -->

  <!-- tei:listBibl - Literaturliste in Einleitungen -->
  <xsl:template match="tei:listBibl">
    <xsl:apply-templates select="tei:head"/>
    <ul class="bibliography">
      <xsl:apply-templates select="*[not(self::tei:head)]"/>
    </ul>
  </xsl:template>

  <!-- tei:body - Textinhalt durchreichen, kein HTML-body erzeugen -->
  <xsl:template match="tei:body">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- tei:front - Textinhalt durchreichen -->
  <xsl:template match="tei:front">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Catch-all: Alle verbleibenden TEI-Elemente, die kein explizites Template haben.
       Gibt den Textinhalt weiter, ohne das TEI-Tag selbst ins HTML zu schreiben.
       Verhindert, dass rohe TEI-Tags mit xmlns im HTML-Output erscheinen. -->
  <xsl:template match="tei:*">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
