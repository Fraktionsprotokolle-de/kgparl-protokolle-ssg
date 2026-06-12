<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
   <!ENTITY copy "&#169;">
]>
<xsl:stylesheet
   xmlns="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="#all"
   version="2.0">

   <xsl:template match="/" name="html_footer">
      <!-- Partner Section -->
      <section class="partner-section">
         <div class="kgparl-container">
            <p class="partner-section-title" role="heading" aria-level="2" data-i18n="footer.partners">Kooperationspartner</p>
            <div class="partner-logos">
               <a href="http://www.kas.de/wf/de/42.7/" target="_blank" rel="noopener noreferrer" title="Archiv für Christlich-Demokratische Politik (ACDP)">
                  <img src="images/adenauer_Footer_activ.jpg" alt="Konrad-Adenauer-Stiftung" />
               </a>
               <a href="https://www.fes.de/archiv/adsd_neu/index.htm" target="_blank" rel="noopener noreferrer" title="Archiv der sozialen Demokratie (AdsD)">
                  <img src="images/ebert_Footer_activ.jpg" alt="Friedrich-Ebert-Stiftung" />
               </a>
               <a href="https://www.freiheit.org/content/archiv-des-liberalismus" target="_blank" rel="noopener noreferrer" title="Archiv des Liberalismus (AdL)">
                  <img src="images/FNF_Logo_D.svg" alt="Friedrich-Naumann-Stiftung" />
               </a>
               <a href="http://www.boell.de/de/stiftung/archiv-gruenes-gedaechtnis" target="_blank" rel="noopener noreferrer" title="Archiv Grünes Gedächtnis (AGG)">
                  <img src="images/boell_Footer_activ.jpg" alt="Heinrich-Böll-Stiftung" />
               </a>
               <a href="https://www.hss.de/archiv/" target="_blank" rel="noopener noreferrer" title="Archiv für Christlich-Soziale Politik (ACSP)">
                  <img src="images/seidel_Footer_activ.jpg" alt="Hanns-Seidel-Stiftung" />
               </a>
            </div>
         </div>
      </section>

      <!-- Main Footer -->
      <footer class="kgparl-footer">
         <div class="footer-main">
            <div class="kgparl-container">
               <div class="grid md:grid-cols-12 gap-8">
                  <!-- Institution Info -->
                  <div class="md:col-span-5">
                     <p class="footer-subtitle" data-i18n="site.subtitle">Kommission für Geschichte des Parlamentarismus und der politischen Parteien e.V.</p>
                     <p class="footer-title" role="heading" aria-level="2" data-i18n="index.heroTitle">Fraktionsprotokolle</p>
                     <p class="footer-description" data-i18n="site.description">
                        Historisch-digitale Quellenedition der Protokolle von Fraktionen und Gruppen im Deutschen Bundestag 1949–2005
                     </p>

                     <!-- Contact Information -->
                     <address class="footer-contact">
                        <div class="mb-4">
                           Schiffbauerdamm 40<br/>
                           10117 Berlin
                        </div>
                        <div class="footer-contact-item">
                           <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                           </svg>
                           <span>+49 (0)30 206 33 94-0</span>
                        </div>
                        <div class="footer-contact-item">
                           <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                           </svg>
                           <a href="mailto:info@kgparl.de">info@kgparl.de</a>
                        </div>
                     </address>
                  </div>

                  <!-- Quick Links -->
                  <div class="md:col-span-3">
                     <p class="footer-nav-title" role="heading" aria-level="2" data-i18n="footer.navigation">Navigation</p>
                     <ul class="footer-nav-list">
                        <li><a href="liste.html" data-i18n="nav.protocols">Protokolle</a></li>
                        <li><a href="personenregister.html" data-i18n="nav.personRegister">Personenregister</a></li>
                        <li><a href="literaturverzeichnis.html" data-i18n="nav.literatureList">Literaturverzeichnis</a></li>
                        <li><a href="einleitungen.html" data-i18n="nav.introductions">Einleitungen</a></li>
                        <li><a href="kalender.html" data-i18n="nav.calendar">Kalender</a></li>
                     </ul>
                  </div>

                  <!-- Legal Links -->
                  <div class="md:col-span-4">
                     <p class="footer-nav-title" role="heading" aria-level="2" data-i18n="footer.legal">Rechtliches</p>
                     <ul class="footer-nav-list">
                        <li><a href="https://kgparl.de/impressum/" data-i18n="footer.imprint">Impressum</a></li>
                        <li><a href="https://kgparl.de/datenschutz/" data-i18n="footer.privacy">Datenschutz</a></li>
                        <li><a href="kontakt.html" data-i18n="nav.contact">Kontakt</a></li>
                        <li><a href="barrierefreiheit.html" data-i18n="nav.accessibility">Barrierefreiheit</a></li>
                        <li><a href="#" onclick="openConsentSettings(); return false;" data-i18n="footer.cookieSettings">Cookie-Einstellungen</a></li>
                     </ul>
                  </div>
               </div>
            </div>
         </div>

         <!-- Footer Bottom Bar -->
         <div class="footer-bottom">
            <div class="kgparl-container">
               <div class="flex flex-col md:flex-row justify-between items-center">
                  <p class="mb-0">&copy; KGParl <xsl:value-of select="year-from-date(current-date())"/></p>

                  <!-- External Links -->
                  <div class="footer-social mt-4 md:mt-0">
                     <span id="data-version" class="data-version-badge"></span>
                     <a href="https://www.kgparl.de" target="_blank" rel="noopener noreferrer" title="KGParl Website">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                           <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"/>
                        </svg>
                     </a>
                     <a href="https://github.com/Fraktionsprotokolle-de/fraktionsprotokolle_web" target="_blank" rel="noopener noreferrer" title="GitHub">
                        <svg fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                           <path fill-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clip-rule="evenodd"/>
                        </svg>
                     </a>
                  </div>
               </div>
            </div>
         </div>
      </footer>

      <!-- Scripts -->
      <script src="js-data/dataVersion.js"></script>
      <script src="js/main.js"></script>
      <script src="js/i18n.js"></script>
      <script src="js/consent.js"></script>
   </xsl:template>

   <!-- Scriptless Footer variant -->
   <xsl:template name="html_footer_scriptless">
      <!-- Partner Section -->
      <section class="partner-section">
         <div class="kgparl-container">
            <p class="partner-section-title" role="heading" aria-level="2" data-i18n="footer.partners">Kooperationspartner</p>
            <div class="partner-logos">
               <a href="http://www.kas.de/wf/de/42.7/" target="_blank" rel="noopener noreferrer" title="Archiv für Christlich-Demokratische Politik (ACDP)">
                  <img src="images/adenauer_Footer_activ.jpg" alt="Konrad-Adenauer-Stiftung" />
               </a>
               <a href="https://www.fes.de/archiv/adsd_neu/index.htm" target="_blank" rel="noopener noreferrer" title="Archiv der sozialen Demokratie (AdsD)">
                  <img src="images/ebert_Footer_activ.jpg" alt="Friedrich-Ebert-Stiftung" />
               </a>
               <a href="https://www.freiheit.org/content/archiv-des-liberalismus" target="_blank" rel="noopener noreferrer" title="Archiv des Liberalismus (AdL)">
                  <img src="images/FNF_Logo_D.svg" alt="Friedrich-Naumann-Stiftung" />
               </a>
               <a href="http://www.boell.de/de/stiftung/archiv-gruenes-gedaechtnis" target="_blank" rel="noopener noreferrer" title="Archiv Grünes Gedächtnis (AGG)">
                  <img src="images/boell_Footer_activ.jpg" alt="Heinrich-Böll-Stiftung" />
               </a>
               <a href="https://www.hss.de/archiv/" target="_blank" rel="noopener noreferrer" title="Archiv für Christlich-Soziale Politik (ACSP)">
                  <img src="images/seidel_Footer_activ.jpg" alt="Hanns-Seidel-Stiftung" />
               </a>
            </div>
         </div>
      </section>

      <!-- Main Footer -->
      <footer class="kgparl-footer">
         <div class="footer-main">
            <div class="kgparl-container">
               <div class="grid md:grid-cols-12 gap-8">
                  <!-- Institution Info -->
                  <div class="md:col-span-5">
                     <p class="footer-subtitle" data-i18n="site.subtitle">Kommission für Geschichte des Parlamentarismus und der politischen Parteien e.V.</p>
                     <p class="footer-title" role="heading" aria-level="2" data-i18n="index.heroTitle">Fraktionsprotokolle</p>
                     <p class="footer-description" data-i18n="site.description">
                        Historisch-digitale Quellenedition der Protokolle von Fraktionen und Gruppen im Deutschen Bundestag 1949–2005
                     </p>
                  </div>

                  <!-- Quick Links -->
                  <div class="md:col-span-3">
                     <p class="footer-nav-title" role="heading" aria-level="2" data-i18n="footer.navigation">Navigation</p>
                     <ul class="footer-nav-list">
                        <li><a href="liste.html" data-i18n="nav.protocols">Protokolle</a></li>
                        <li><a href="personenregister.html" data-i18n="nav.personRegister">Personenregister</a></li>
                        <li><a href="einleitungen.html" data-i18n="nav.introductions">Einleitungen</a></li>
                     </ul>
                  </div>

                  <!-- Legal Links -->
                  <div class="md:col-span-4">
                     <p class="footer-nav-title" role="heading" aria-level="2" data-i18n="footer.legal">Rechtliches</p>
                     <ul class="footer-nav-list">
                        <li><a href="https://kgparl.de/impressum/" data-i18n="footer.imprint">Impressum</a></li>
                        <li><a href="https://kgparl.de/datenschutz/" data-i18n="footer.privacy">Datenschutz</a></li>
                        <li><a href="kontakt.html" data-i18n="nav.contact">Kontakt</a></li>
                     </ul>
                  </div>
               </div>
            </div>
         </div>

         <!-- Footer Bottom Bar -->
         <div class="footer-bottom">
            <div class="kgparl-container">
               <div class="flex flex-col md:flex-row justify-between items-center">
                  <p class="mb-0">&copy; KGParl <xsl:value-of select="year-from-date(current-date())"/></p>
               </div>
            </div>
         </div>
      </footer>
   </xsl:template>
</xsl:stylesheet>
