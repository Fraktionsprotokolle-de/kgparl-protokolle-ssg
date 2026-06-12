<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:local="http://dse-static.foo.bar"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    version="2.0" exclude-result-prefixes="xsl tei xs local">
    <xsl:output encoding="UTF-8" media-type="text/html" method="html" version="5.0" indent="no"
        omit-xml-declaration="yes" />

    <xsl:import href="./partials/shared.xsl" />
    <xsl:import href="./partials/html_navbar.xsl" />
    <xsl:import href="./partials/html_head.xsl" />
    <xsl:import href="./partials/html_footer.xsl" />
    <xsl:import href="./partials/aot-options.xsl" />
    <xsl:import href="./fraktionsprotokolle.xslt" />
    <xsl:variable name="prev">
        <xsl:value-of select="replace(tokenize(data(tei:TEI/@prev), '/')[last()], '.xml', '.html')" />
    </xsl:variable>
    <xsl:variable name="next">
        <xsl:value-of select="replace(tokenize(data(tei:TEI/@next), '/')[last()], '.xml', '.html')" />
    </xsl:variable>
    <xsl:variable name="teiSource">
        <xsl:value-of select="data(tei:TEI/@xml:id)" />
    </xsl:variable>
    <xsl:variable name="link">
        <xsl:value-of select="replace($teiSource, '.xml', '.html')" />
    </xsl:variable>
    <xsl:variable name="party">
        <xsl:value-of select=".//tei:profileDesc//tei:idno[@type='Fraktion-Landesgruppe']" />
    </xsl:variable>
    <xsl:variable name="period">
        <xsl:value-of select=".//tei:profileDesc//tei:idno[@type='wp']" />
    </xsl:variable>
    <xsl:variable name="date-formatted">
        <xsl:call-template name="GetDate">
            <xsl:with-param name="protocol" select=".//tei:TEI" />
        </xsl:call-template>
    </xsl:variable>
    <!-- format date from yyyy-mm-dd to dd.mm.yyyy -->
    <!--    <xsl:variable name="date-formatted">
        <xsl:call-template name="MakeDate">
            <xsl:with-param name="date" select="$date" />
        </xsl:call-template>
    </xsl:variable>-->
    <xsl:variable name="doc_title">
        <xsl:value-of select=".//tei:titleStmt/tei:title[1]/text()" />
    </xsl:variable>

    <xsl:variable name="isEINL" select="boolean(//tei:teiHeader//tei:category[@xml:id='EINL'])" />
    <xsl:template match="/">
        <html lang="de" class="h-100" data-date="{current-date()}">
            <head>
                <xsl:call-template name="html_head">
                    <xsl:with-param name="html_title" select="$doc_title"></xsl:with-param>
                </xsl:call-template>
                <style>
                    .navBarNavDropdown ul li:nth-child(2) {
                    display: none !important;
                    }
                    .highlight {
                    background-color: rgb(246, 166, 35);
                    }
                    body {
                    overflow:hidden;
                    overflow-y:scroll;
                    }
                    main {
                    text-align: justify;
                    }
                    /* Details/Summary styling - keep marker and text on same line */
                    details summary {
                    display: flex;
                    align-items: center;
                    list-style: none;
                    }

                    details summary::marker,
                    details summary::-webkit-details-marker {
                    display: none;
                    }

                    details summary::before {
                    content: '▶';
                    display: inline-block;
                    margin-right: 0.5em;
                    transition: transform 0.2s;
                    }

                    details[open] summary::before {
                    transform: rotate(90deg);
                    }
                </style>
                <style>
                /* Hamburger Button */
        .menu-toggle {
            position: fixed;
            left: 20px;
            top: 20px;
            z-index: 1001;
            background-color: #white;
            border: none;
            padding: 10px;
            cursor: pointer;
            border-radius: 5px;
            width: 45px;
            height: 45px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            gap: 5px;
            transition: all 0.3s ease;
        }

        .menu-toggle:hover {
            background-color: #888;
        }

        .menu-toggle span {
            display: block;
            width: 25px;
            height: 3px;
            background-color: black;
            transition: all 0.3s ease;
            border-radius: 2px;
        }

        /* Arrow pointing left when menu is open */
        .menu-toggle.active span:nth-child(1) {
            transform: translateX(3px) rotate(-45deg) scaleX(0.6);
            transform-origin: left center;
        }

        .menu-toggle.active span:nth-child(2) {
            transform: scaleX(1);
        }

        .menu-toggle.active span:nth-child(3) {
            transform: translateX(3px) rotate(45deg) scaleX(0.6);
            transform-origin: left center;
        }

        /* Sidebar Menu */
        .sidebar-menu {
            position: fixed;
            left: -320px;
            top: 0;
            width: 300px;
            height: 100vh;
            overflow-y: auto;
            background-color: #f5f5f5;
            padding: 80px 20px 20px 20px;
            border-right: 1px solid #ddd;
            z-index: 1000;
            transition: left 0.3s ease;
            box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
            text-align: left;
        }

        /* Einleitungs-spezifische Overrides sind in kgparl.css (.is-einleitung) */

        .sidebar-menu.active {
            left: 0;
        }

        /* Menu Items */
        .menu-item {
            margin: 8px 0;
        }

        .menu-item a {
            display: block;
            padding: 8px 12px;
            text-decoration: none;
            color: #333;
            border-radius: 4px;
            transition: all 0.2s ease;
            font-size: 14px;
            line-height: 1.4;
            text-align: left;
        }

        .menu-item a:hover {
            background-color: #e0e0e0;
            color: #0066cc;
            transform: translateX(5px);
        }

        /* Einrückung für verschachtelte Elemente */
        .menu-item[style*="margin-left"] a {
            border-left: 2px solid #ddd;
        }

        /* Content Bereich */
        .content {
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }

        /* Scrollbar Styling */
        .sidebar-menu::-webkit-scrollbar {
            width: 8px;
        }

        .sidebar-menu::-webkit-scrollbar-track {
            background: #f1f1f1;
        }

        .sidebar-menu::-webkit-scrollbar-thumb {
            background: #888;
            border-radius: 4px;
        }

        .sidebar-menu::-webkit-scrollbar-thumb:hover {
            background: #555;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .sidebar-menu {
                width: 280px;
                left: -300px;
            }

            .content {
                padding: 15px;
            }
        }
        </style>
                <script type="module" src="js/popupinfo.js"></script>
                <script type="module" src="js/customcheckbox.js"></script>
            </head>
            <body>
                <xsl:if test="$isEINL">
                    <xsl:attribute name="class">is-einleitung</xsl:attribute>
                </xsl:if>
                <xsl:call-template name="nav_bar" />

                <main class="main-content" id="main-content">
                    <div class="kgparl-container">

                    <nav class="breadcrumb-bar mt-2" aria-label="Breadcrumb">
                        <div class="breadcrumbs">
                            <xsl:if test="not($isEINL)">
                                <a class="kgparl-link breadcrumb-party" target="_self"
                                    data-party="{$party}">
                                    <xsl:value-of select="$party" />
                                </a>
                                <xsl:text> &gt; </xsl:text>
                                <a class="kgparl-link breadcrumb-period" target="_self"
                                    data-party="{$party}" data-period="{$period}">
                                    <xsl:value-of select="$period" />
                                </a>
                                <xsl:text> &gt; </xsl:text>
                                <xsl:value-of select="$date-formatted" />
                                <xsl:text> : </xsl:text>
                            </xsl:if>
                            <xsl:value-of select="data(.//tei:titleStmt/tei:title[1])" />
                        </div>
                        <div class="breadcrumb-actions">
                        <button class="kgparl-btn-download" id="copy-plaintext-btn" type="button"
                                data-i18n="[title]edition.copyTooltip"
                                title="Protokolltext inkl. Metadaten als Klartext in die Zwischenablage kopieren">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                            </svg>
                            <span data-i18n="edition.copyPlaintext">In die Zwischenablage</span>
                        </button>
                        <div class="download-dropdown">
                            <button class="kgparl-btn-download download-toggle" aria-expanded="false" aria-haspopup="true">
                                <span data-i18n="edition.downloads">Downloads</span>
                                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="6 9 12 15 18 9"></polyline>
                                </svg>
                            </button>
                            <div class="download-menu" role="menu">
                                <a class="download-item" href="./downloads/{replace($teiSource, '.xml', '')}.pdf" target="_blank" rel="noopener" role="menuitem">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                        <polyline points="14 2 14 8 20 8"></polyline>
                                        <line x1="16" y1="13" x2="8" y2="13"></line>
                                        <line x1="16" y1="17" x2="8" y2="17"></line>
                                        <polyline points="10 9 9 9 8 9"></polyline>
                                    </svg>
                                    <span data-i18n="edition.pdf">PDF</span>
                                </a>
                                <xsl:if test="not($isEINL)">
                                <a class="download-item" href="./downloads/{$teiSource}.xml" target="_blank" rel="noopener" role="menuitem">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="16 18 22 12 16 6"></polyline>
                                        <polyline points="8 6 2 12 8 18"></polyline>
                                    </svg>
                                    <span data-i18n="edition.xmlTei">XML (TEI)</span>
                                </a>
                                </xsl:if>
                            </div>
                        </div>
                        </div>
                    </nav>

                    <div id="sitzungs-info" class="sitzungs-info">
                        <xsl:if test="not($isEINL)">
                            <h2><xsl:value-of select="$party" /> (<xsl:value-of select="$period" />.<span data-i18n="edition.wp"> WP</span>)</h2>
                            <details>
                                <summary>
                                    <span class="fs-2 fw-normal"><xsl:value-of
                                            select="$date-formatted" />: <xsl:value-of
                                            select="$doc_title" /><sup
                                            data-i18n="[title]edition.infoAndCitation"
                                            title="Informationen und Zitierempfehlungen ein-/ausklappen">
                                        </sup></span>
                                </summary>
                                <xsl:call-template name="MakeCitation">
                                    <xsl:with-param name="entry" select="." />
                                    <xsl:with-param name="party" select="$party" />
                                    <xsl:with-param name="period" select="$period" />
                                    <xsl:with-param name="doc_title" select="$doc_title" />
                                </xsl:call-template>
                            </details>
                            <details id="sitzungsverlauf">
                                <summary>
                                    <span class="fs-2 fw-normal"> <span data-i18n="edition.sessionAgenda">Sitzungsverlauf:</span><sup
                                            data-i18n="[title]edition.toggleSessionAgenda"
                                            title="Sitzungsverlauf ein-/ausklappen">
                                        </sup></span>
                                </summary>
                                <xsl:call-template name="MakeList">
                                    <xsl:with-param name="entry" select="." />
                                </xsl:call-template>
                            </details>
                            <xsl:if test=".//tei:front/tei:div[@type='Anwesenheitsliste']">
                                <details id="anwesenheitsliste">
                                    <summary>
                                        <span class="fs-2 fw-normal">
                                            <span data-i18n="edition.attendanceList">Anwesenheitsliste</span>
                                            <sup data-i18n="[title]edition.toggleAttendanceList"
                                                 title="Anwesenheitsliste ein-/ausklappen">
                                            </sup>
                                        </span>
                                    </summary>
                                    <div class="info-block" style="background-color: var(--color-background-light); overflow: visible;">
                                        <xsl:for-each select=".//tei:front/tei:div[@type='Anwesenheitsliste']">
                                            <div class="attendance-list-section">
                                                <strong><xsl:value-of select="tei:head"/></strong>
                                                <xsl:apply-templates select="*[not(self::tei:head)]"/>
                                            </div>
                                        </xsl:for-each>
                                    </div>
                                </details>
                            </xsl:if>
                            <div id="hamburger-menu" class="hidden">
                                <div class="hamburger-icon">
                                    <span></span>
                                    <span></span>
                                    <span></span>
                                </div>
                                <nav id="menu-items" class="menu-items">
                                </nav>
                            </div>
                        </xsl:if>
                        <xsl:if test="$isEINL">
                            <details>
                                <summary>
                                    <span class="fs-2 fw-normal" data-i18n="edition.introductionNote">
                                    Hinweis zum Gebrauch der digitalen Einleitung
                                    </span>
                                </summary>
                                <div class="info-block" style="background-color: var(  --color-background-light);">
                                    <xsl:apply-templates select=".//tei:front"/>
                                </div>
                            </details>
                        </xsl:if>
                    </div>
                    <!-- Sidebar menu for Sitzungsverlauf (populated for protocols) -->
                    <nav id="sidebar-menu" class="sidebar-menu" aria-label="Sitzungsverlauf">
                        <xsl:if test="not($isEINL)">
                            <div class="sidebar-menu-header" data-i18n="edition.sessionAgenda">Sitzungsverlauf</div>
                            <xsl:for-each select=".//tei:text//tei:list[@type='SVP']/tei:item">
                                <div class="menu-item">
                                    <a href="#{replace(./@corresp, '#', '')}" class="kgparl-link">
                                        <xsl:value-of select="string-join(.//text()[not(ancestor::tei:expan)], '')" />
                                    </a>
                                </div>
                            </xsl:for-each>
                        </xsl:if>
                    </nav>

                    <!-- Two-column layout: content left, facets right -->
                    <div class="edition-layout">
                        <article class="edition-content">

                            <div class="lh-lg content" id="content-container">
                                <xsl:apply-templates select=".//tei:body"></xsl:apply-templates>
                                <div class="container">
                                <div id="footnotes-container">

                                    <xsl:for-each select=".//tei:body//tei:note">
                                        <div class="footnotes" id="{local:makeId(.)}">
                                            <xsl:variable name="fn_id">
                                                <xsl:choose>
                                                    <xsl:when test="@xml:id">
                                                        <xsl:value-of select="@xml:id" />
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <xsl:number level="any" format="1" count="tei:body//tei:note" />
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:variable>
                                            <xsl:variable name="fn_number">
                                                <xsl:number level="any" format="1"
                                                    count="tei:body//tei:note" />
                                            </xsl:variable>
                                            <span id="fn{$fn_number}">
                                                <a href="#fnref_{$fn_id}" class="fn-number-link" title="Zurück zur Textstelle">
                                                    <span class="fn">
                                                        <xsl:if test="@xml:id">
                                                            <xsl:attribute name="id">
                                                                <xsl:value-of select="@xml:id" />
                                                            </xsl:attribute>
                                                        </xsl:if>
                                                        <xsl:value-of select="$fn_number" />
                                                    </span>
                                                </a>
                                                <span class="fn-text">
                                                    <xsl:apply-templates />
                                                </span>
                                                <a href="#fnref_{$fn_id}" class="fn-back" title="Zurück zur Textstelle" aria-label="Zurück zur Textstelle">↑</a>
                                            </span>
                                        </div>
                                    </xsl:for-each>
                                </div>
                                </div>
                            </div>
                            <xsl:for-each select="//tei:back">
                                <div class="tei-back">
                                    <xsl:apply-templates />
                                </div>
                            </xsl:for-each>
                        </article>

                        <!-- Sticky sidebar with facets -->
                        <aside class="edition-sidebar" aria-label="Personen">
                                <div class="facets-panel">
                                    <h2 data-i18n="keywordRegister.title">Schlagwörter</h2>
                                    <div class="keyword-toggle-wrapper">
                                        <xsl:choose>
                                            <xsl:when test="//tei:body//tei:term[@ref]">
                                                <input type="checkbox" id="keyword-toggle" class="keyword-toggle" checked="checked" />
                                                <label for="keyword-toggle" data-i18n="keywordRegister.showHighlights">Hervorhebungen anzeigen</label>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <input type="checkbox" id="keyword-toggle" class="keyword-toggle" disabled="disabled" />
                                                <label for="keyword-toggle" class="keyword-toggle-disabled" data-i18n="keywordRegister.noKeywords">Keine Schlagwörter vorhanden</label>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </div>
                                </div>
                            <xsl:if test="//tei:body//tei:name[@type='Person']">
                                <div class="facets-panel">
                                    <h2>Personen</h2>
                                    <xsl:call-template name="facets">
                                        <xsl:with-param name="entry" select="//tei:text" />
                                    </xsl:call-template>
                                </div>
                            </xsl:if>
                        </aside>
                    </div>
                    </div>
                </main>

                <xsl:call-template name="html_footer" />
                <script src="js/editions.js"></script>
            </body>
             <script>
              <xsl:text disable-output-escaping="yes"><![CDATA[
    var toggleMenu;
    function initMenu() {
            // Erstelle Hamburger Button
            const toggleButton = document.createElement('button');
            toggleButton.className = 'menu-toggle';
            toggleButton.setAttribute('aria-label', i18next?.t('edition.toggleMenu') || 'Sitzungsverlauf');
            toggleButton.setAttribute('title', i18next?.t('edition.contents') || 'Inhalt');
            toggleButton.innerHTML = '<span></span><span></span><span></span>';
            document.body.insertBefore(toggleButton, document.body.firstChild);

            const menuContainer = document.getElementById('sidebar-menu');
            if (!menuContainer) return;

            // Toggle Funktion
            toggleMenu = function() {
                toggleButton.classList.toggle('active');
                menuContainer.classList.toggle('active');
            };

            // Event Listeners
            toggleButton.addEventListener('click', toggleMenu);

            // Generiere Menü-Inhalt nur für Einleitungen (wenn leer)
            if (menuContainer.children.length === 0) {
                generateMenu();
            }

            // Schließe Menü bei Klick auf Link
            menuContainer.addEventListener('click', function(e) {
                if (e.target.tagName === 'A') {
                    toggleMenu();
                }
            });

            // Einleitungen: Button und Sidebar-Padding gleiten beim Scrollen nach oben
            if (document.body.classList.contains('is-einleitung')) {
                var startTop = 200, minTop = 20;
                var paddingOffset = 60; // Abstand zwischen Button und Sidebar-Inhalt
                window.addEventListener('scroll', function() {
                    var y = Math.max(minTop, startTop - window.scrollY);
                    toggleButton.style.top = y + 'px';
                    menuContainer.style.paddingTop = (y + paddingOffset) + 'px';
                }, { passive: true });
            }

            // ESC-Taste zum Schließen
            document.addEventListener('keydown', function(e) {
                if (e.key === 'Escape' && menuContainer.classList.contains('active')) {
                    toggleMenu();
                }
            });
        }

        function generateMenu() {
            const menuContainer = document.getElementById('sidebar-menu');
            if (!menuContainer) return;

            menuContainer.innerHTML = '';

            const contentRoot = document.getElementById('content-container') || document;
            const headingSelector = ':scope > h1[id], :scope > h2[id], :scope > h3[id], :scope > h4[id], :scope > h5[id], :scope > h6[id]';
            const getDirectHeading = div => {
                const heading = div.querySelector(headingSelector);
                return heading && heading.id ? heading : null;
            };

            function createMenuItem(div, depth) {
                const heading = getDirectHeading(div);
                if (!heading) return null;

                const menuItem = document.createElement('div');
                menuItem.className = 'menu-item';
                menuItem.style.marginLeft = (depth * 20) + 'px';

                const link = document.createElement('a');
                link.href = '#' + heading.id;
                link.textContent = heading.textContent.trim();

                menuItem.appendChild(link);
                return menuItem;
            }

            function processDiv(parentDiv, depth, menuParent) {
                Array.from(parentDiv.children).forEach(child => {
                    if (child.tagName !== 'DIV') return;

                    const menuItem = createMenuItem(child, depth);
                    if (menuItem) {
                        menuParent.appendChild(menuItem);
                        processDiv(child, depth + 1, menuParent);
                    } else {
                        processDiv(child, depth, menuParent);
                    }
                });
            }

            processDiv(contentRoot, 0, menuContainer);
        }

        // Smooth Scrolling (nur für reine Hash-Links auf der gleichen Seite)
        document.addEventListener('click', function(e) {
            var link = e.target.closest('a');
            if (link && link.hash && link.getAttribute('href').startsWith('#')) {
                e.preventDefault();
                var targetId = link.hash.substring(1);
                var targetElement = document.getElementById(targetId);
                if (targetElement) {
                    toggleMenu && document.querySelector('.menu-toggle.active') && toggleMenu();
                    targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            }
        });

        // Initialisiere alles
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initMenu);
        } else {
            initMenu();
        }
        ]]>
    </xsl:text>
    </script>
        </html>
    </xsl:template>
</xsl:stylesheet>
