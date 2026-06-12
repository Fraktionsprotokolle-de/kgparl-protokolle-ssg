<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
   <!ENTITY copy "&#169;">
   <!ENTITY nbsp "&#160;">
   <!ENTITY ndash "&#8211;">
]>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">

   <!-- Sprachmanifest wird zur Build-Zeit von scripts/generate_languages_manifest.py
        erzeugt. Nur Sprachen mit complete="true" landen im Switcher. -->
   <xsl:variable name="languages" select="document('../../data/meta/languages.xml')/languages/language[@complete='true']"/>

   <xsl:template match="/" name="nav_bar">
      <!-- Skip Link for Accessibility (WCAG 2.4.1) -->
      <a href="#main-content" class="skip-link" data-i18n="nav.skipToContent">Zum Hauptinhalt springen</a>
      <header class="kgparl-header" role="banner">
         <!-- Service Menu Bar (Top) -->
         <div class="service-bar">
            <div class="kgparl-container">
               <div class="flex justify-between items-center py-2">
                  <!-- Left: Accessibility -->
                  <div class="flex items-center gap-4">
                     <a href="barrierefreiheit.html" class="hidden md:inline" data-i18n="nav.accessibility">Barrierefreiheit</a>
                  </div>
                  <!-- Right: Service Links + Language Switcher -->
                  <nav class="flex items-center gap-4" aria-label="Service-Links">
                     <a href="kontakt.html" data-i18n="nav.contact">Kontakt</a>
                     <a href="hilfe.html" data-i18n="nav.help">Hilfe</a>
                     <!-- Language Switcher -->
                     <div class="language-switcher">
                        <button type="button" class="language-toggle" aria-expanded="false" aria-haspopup="true" aria-label="Sprache wählen" data-i18n="[aria-label]language.select">
                           <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                              <circle cx="12" cy="12" r="10"></circle>
                              <line x1="2" y1="12" x2="22" y2="12"></line>
                              <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"></path>
                           </svg>
                           <span class="current-lang">DE</span>
                        </button>
                        <div class="language-menu" role="menu">
                           <xsl:for-each select="$languages">
                              <button type="button" class="language-option" role="menuitem">
                                 <xsl:attribute name="data-lang"><xsl:value-of select="@code"/></xsl:attribute>
                                 <span><xsl:value-of select="@nativeName"/></span>
                              </button>
                           </xsl:for-each>
                        </div>
                     </div>
                  </nav>
               </div>
            </div>
         </div>

         <!-- Main Header Area -->
         <div class="header-main">
            <div class="kgparl-container">
               <div class="flex items-center justify-between gap-6">
                  <!-- Logo &amp; Title -->
                  <div class="flex items-center gap-4">
                     <!-- Logo -->
                     <a href="index.html" class="header-logo-fallback" data-i18n="[aria-label]nav.home;[title]nav.home">
                        <xsl:attribute name="aria-label">Startseite</xsl:attribute>
                        <xsl:attribute name="title">Startseite</xsl:attribute>
                        <img src="images/KGParl.svg" alt="KGParl Logo" class="header-logo" />
                     </a>
                  </div>

               </div>
            </div>
         </div>

         <!-- Main Navigation -->
         <nav class="main-nav" aria-label="Hauptnavigation">
            <div class="kgparl-container">
               <!-- Desktop Navigation -->
               <ul class="main-nav-list">
                  <li class="main-nav-item">
                     <a href="index.html" class="main-nav-link" data-i18n="nav.home">Startseite</a>
                  </li>
                  <li class="main-nav-item">
                     <a href="liste.html" class="main-nav-link" data-i18n="nav.protocols">Protokolle</a>
                  </li>
                  <li class="main-nav-item">
                     <a href="kalender.html" class="main-nav-link" data-i18n="nav.calendar">Kalender</a>
                  </li>
                  <li class="main-nav-item">
                     <button type="button" class="main-nav-link nav-dropdown-trigger" aria-expanded="false" aria-haspopup="true">
                        <span data-i18n="nav.directories">Verzeichnisse</span>
                        <svg class="nav-dropdown-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                        </svg>
                     </button>
                     <div class="nav-dropdown" role="menu">
                        <a href="personenregister.html" role="menuitem" data-i18n="nav.personRegister">Personenregister</a>
                        <a href="literaturverzeichnis.html" role="menuitem" data-i18n="nav.literatureList">Literaturverzeichnis</a>
                        <a href="schlagwortregister.html" role="menuitem" data-i18n="nav.keywordRegister">Schlagwortregister</a>
                     </div>
                  </li>
                  <li class="main-nav-item">
                     <a href="einleitungen.html" class="main-nav-link" data-i18n="nav.introductions">Einleitungen</a>
                  </li>
                  <li class="main-nav-item">
                     <a href="suche.html" class="main-nav-link" data-i18n="nav.search">Volltextsuche</a>
                  </li>
                  <li class="main-nav-item">
                     <button type="button" class="main-nav-link nav-dropdown-trigger" aria-expanded="false" aria-haspopup="true">
                        <span data-i18n="nav.aboutEdition">Zur Edition</span>
                        <svg class="nav-dropdown-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                        </svg>
                     </button>
                     <div class="nav-dropdown" role="menu">
                        <a href="projekt.html" role="menuitem" data-i18n="nav.project">Projekt</a>
                        <a href="aktuelles.html" role="menuitem" data-i18n="nav.news">Aktuelles</a>
                        <a href="editionshinweise.html" role="menuitem" data-i18n="nav.editorialNotes">Editionshinweise</a>
                        <a href="forschung.html" role="menuitem" data-i18n="nav.researchRelevance">Forschungsrelevanz</a>
                        <a href="mitarbeiter.html" role="menuitem" data-i18n="nav.staff">Mitarbeiterinnen und Mitarbeiter</a>
                        <a href="editionsbeirat.html" role="menuitem" data-i18n="nav.advisoryBoard">Editionsbeirat</a>
                        <a href="https://github.com/Fraktionsprotokolle-de/fraktionsprotokolle_web" target="_blank" rel="noopener noreferrer" role="menuitem">
                           <span data-i18n="nav.githubRepo">GitHub Repositorium</span>
                           <span class="sr-only" data-i18n="nav.opensInNewTab"> (öffnet in neuem Tab)</span>
                        </a>
                     </div>
                  </li>
                  <li class="main-nav-item">
                     <a href="hilfe.html" class="main-nav-link" data-i18n="nav.help">Hilfe</a>
                  </li>
               </ul>

               <!-- Mobile Menu Button -->
               <div class="py-2 md:hidden">
                  <button id="mobile-menu-btn" class="mobile-menu-toggle" data-i18n="[aria-label]nav.openMenu" aria-label="Menü öffnen">
                     <svg class="menu-open-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                     </svg>
                     <svg class="menu-close-icon hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                     </svg>
                  </button>
               </div>
            </div>
         </nav>

         <!-- Mobile Navigation -->
         <nav id="mobile-nav" class="mobile-nav" aria-label="Mobile Navigation">
            <div class="kgparl-container">
               <!-- Mobile Nav Links -->
               <a href="index.html" class="mobile-nav-link" data-i18n="nav.home">Startseite</a>
               <a href="liste.html" class="mobile-nav-link" data-i18n="nav.protocols">Protokolle</a>
               <a href="kalender.html" class="mobile-nav-link" data-i18n="nav.calendar">Kalender</a>

               <!-- Verzeichnisse mit Untermenü -->
               <div class="mobile-nav-group">
                  <button class="mobile-nav-toggle" aria-expanded="false">
                     <span data-i18n="nav.directories">Verzeichnisse</span>
                     <svg class="mobile-nav-chevron" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                     </svg>
                  </button>
                  <div class="mobile-nav-submenu">
                     <a href="personenregister.html" data-i18n="nav.personRegister">Personenregister</a>
                     <a href="literaturverzeichnis.html" data-i18n="nav.literatureList">Literaturverzeichnis</a>
                     <a href="schlagwortregister.html" data-i18n="nav.keywordRegister">Schlagwortregister</a>
                  </div>
               </div>

               <a href="einleitungen.html" class="mobile-nav-link" data-i18n="nav.introductions">Einleitungen</a>
               <a href="suche.html" class="mobile-nav-link" data-i18n="nav.search">Volltextsuche</a>

               <!-- Zur Edition mit Untermenü -->
               <div class="mobile-nav-group">
                  <button class="mobile-nav-toggle" aria-expanded="false">
                     <span data-i18n="nav.aboutEdition">Zur Edition</span>
                     <svg class="mobile-nav-chevron" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                     </svg>
                  </button>
                  <div class="mobile-nav-submenu">
                     <a href="projekt.html" data-i18n="nav.project">Projekt</a>
                     <a href="aktuelles.html" data-i18n="nav.news">Aktuelles</a>
                     <a href="editionshinweise.html" data-i18n="nav.editorialNotes">Editionshinweise</a>
                     <a href="forschung.html" data-i18n="nav.researchRelevance">Forschungsrelevanz</a>
                     <a href="mitarbeiter.html" data-i18n="nav.staff">Mitarbeiterinnen und Mitarbeiter</a>
                     <a href="editionsbeirat.html" data-i18n="nav.advisoryBoard">Editionsbeirat</a>
                     <a href="https://github.com/Fraktionsprotokolle-de/fraktionsprotokolle_web" target="_blank" rel="noopener noreferrer" data-i18n="nav.githubRepo">GitHub Repositorium</a>
                  </div>
               </div>

               <a href="hilfe.html" class="mobile-nav-link" data-i18n="nav.help">Hilfe</a>

               <!-- Mobile Language Switcher -->
               <div class="mobile-language-switcher">
                  <xsl:for-each select="$languages">
                     <button type="button" class="language-option">
                        <xsl:attribute name="data-lang"><xsl:value-of select="@code"/></xsl:attribute>
                        <xsl:value-of select="@nativeName"/>
                     </button>
                  </xsl:for-each>
               </div>
            </div>
         </nav>
      </header>
   </xsl:template>
</xsl:stylesheet>
