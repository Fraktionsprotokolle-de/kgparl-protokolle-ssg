/**
 * i18n Configuration for Fraktionsprotokolle
 * Uses i18next for internationalization
 *
 * Sprachen werden dynamisch aus locales/manifest.json geladen.
 * Das Manifest erzeugt scripts/generate_languages_manifest.py zur Build-Zeit
 * aus html/locales/<code>/translation.json (_meta-Block pro Sprache).
 */

// Object-Identität beibehalten: Andere Skripte können bereits
// window.i18nUtils.supportedLanguages referenzieren, daher nicht neu
// zuweisen, sondern in-place befüllen.
const supportedLanguages = {};
const supportedCodes = [];
const FALLBACK_LNG = 'de';

// Manifest laden; bei Fehler auf Default (de, en) zurückfallen,
// damit bestehende Funktionalität garantiert erhalten bleibt.
async function loadLanguageManifest() {
  const applyFallback = () => {
    Object.keys(supportedLanguages).forEach(k => delete supportedLanguages[k]);
    Object.assign(supportedLanguages, {
      de: { nativeName: 'Deutsch', code: 'DE' },
      en: { nativeName: 'English', code: 'EN' }
    });
    supportedCodes.length = 0;
    supportedCodes.push('de', 'en');
  };
  try {
    const resp = await fetch('locales/manifest.json', { cache: 'no-cache' });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    const data = await resp.json();
    const list = Array.isArray(data.languages) ? data.languages : [];
    const complete = list.filter(l => l && l.code && l.complete);
    if (complete.length === 0) throw new Error('manifest has no complete languages');
    Object.keys(supportedLanguages).forEach(k => delete supportedLanguages[k]);
    complete.forEach(l => {
      supportedLanguages[l.code] = { nativeName: l.nativeName, code: l.shortCode };
    });
    supportedCodes.length = 0;
    complete.forEach(l => supportedCodes.push(l.code));
  } catch (err) {
    console.warn('i18n: could not load locales/manifest.json, using fallback config:', err);
    applyFallback();
  }
}

// Detect language: localStorage first, then browser, always base code only
function detectLanguage() {
  const stored = localStorage.getItem('i18nextLng');
  if (stored) {
    const base = stored.split('-')[0];
    if (supportedCodes.includes(base)) return base;
  }
  const nav = (navigator.language || FALLBACK_LNG).split('-')[0];
  return supportedCodes.includes(nav) ? nav : FALLBACK_LNG;
}

// Initialize i18next
async function initI18n() {
  await loadLanguageManifest();

  const lng = detectLanguage();
  localStorage.setItem('i18nextLng', lng);

  i18next
    .use(i18nextHttpBackend)
    .init({
      debug: false,
      lng: lng,
      fallbackLng: FALLBACK_LNG,
      supportedLngs: supportedCodes,
      backend: {
        loadPath: 'locales/{{lng}}/translation.json',
      }
    }, (err, t) => {
      if (err) {
        console.error('i18next initialization error:', err);
        return;
      }

      // Initialize jQuery i18next if available
      if (typeof jqueryI18next !== 'undefined' && typeof $ !== 'undefined') {
        jqueryI18next.init(i18next, $, { useOptionsAttr: true });
      }

      // Apply translations
      updateContent();

      // Update language switcher UI
      updateLanguageSwitcher();

      // Setup language switcher event listeners
      setupLanguageSwitcher();
    });
}

// Update page content with translations
function updateContent() {
  // Use jQuery localize if available
  if (typeof $ !== 'undefined' && $.fn.localize) {
    $('body').localize();
  } else {
    // Fallback: manually update elements with data-i18n
    document.querySelectorAll('[data-i18n]').forEach(element => {
      const key = element.getAttribute('data-i18n');

      // Handle attribute translations (e.g., [placeholder]key;[aria-label]key2)
      if (key.includes('[')) {
        const parts = key.split(';');
        parts.forEach(part => {
          const match = part.match(/\[([^\]]+)\](.+)/);
          if (match) {
            const attr = match[1];
            const translationKey = match[2];
            const translation = i18next.t(translationKey);
            if (translation && translation !== translationKey) {
              element.setAttribute(attr, translation);
            }
          }
        });
      } else {
        // Simple text content translation
        const translation = i18next.t(key);
        if (translation && translation !== key) {
          element.textContent = translation;
        }
      }
    });
  }
}

// Update language switcher UI to reflect current language
function updateLanguageSwitcher() {
  const currentLang = i18next.language || 'de';
  const langCode = supportedLanguages[currentLang]?.code || 'DE';

  // Update desktop switcher
  document.querySelectorAll('.current-lang').forEach(el => {
    el.textContent = langCode;
  });

  // Update active state on language options
  document.querySelectorAll('.language-option').forEach(option => {
    const lang = option.getAttribute('data-lang');
    const isActive = lang === currentLang;
    option.classList.toggle('active', isActive);
    if (isActive) {
      option.setAttribute('aria-current', 'true');
    } else {
      option.removeAttribute('aria-current');
    }
  });
}

// Setup language switcher event listeners
function setupLanguageSwitcher() {
  // Desktop language toggle
  document.querySelectorAll('.language-toggle').forEach(toggle => {
    toggle.addEventListener('click', (e) => {
      e.preventDefault();
      e.stopPropagation();

      const switcher = toggle.closest('.language-switcher');
      const isOpen = switcher.classList.toggle('open');
      toggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    });
  });

  // Language option buttons
  document.querySelectorAll('.language-option').forEach(option => {
    option.addEventListener('click', (e) => {
      e.preventDefault();
      const lang = option.getAttribute('data-lang');

      if (lang && lang !== i18next.language) {
        changeLanguage(lang);
      }

      // Close dropdown
      document.querySelectorAll('.language-switcher').forEach(switcher => {
        switcher.classList.remove('open');
        const toggle = switcher.querySelector('.language-toggle');
        if (toggle) toggle.setAttribute('aria-expanded', 'false');
      });
    });
  });

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.language-switcher')) {
      document.querySelectorAll('.language-switcher').forEach(switcher => {
        switcher.classList.remove('open');
        const toggle = switcher.querySelector('.language-toggle');
        if (toggle) toggle.setAttribute('aria-expanded', 'false');
      });
    }
  });

  // Close dropdown on Escape
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      document.querySelectorAll('.language-switcher').forEach(switcher => {
        switcher.classList.remove('open');
        const toggle = switcher.querySelector('.language-toggle');
        if (toggle) toggle.setAttribute('aria-expanded', 'false');
      });
    }
  });
}

// Change language
function changeLanguage(lang) {
  i18next.changeLanguage(lang, (err) => {
    if (err) {
      console.error('Error changing language:', err);
      return;
    }

    // Update content
    updateContent();

    // Update language switcher UI
    updateLanguageSwitcher();

    // Store preference
    localStorage.setItem('i18nextLng', lang);

    // Update HTML lang attribute
    document.documentElement.setAttribute('lang', lang);
  });
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initI18n);
} else {
  initI18n();
}

// Export for use in other scripts
window.i18nUtils = {
  changeLanguage,
  updateContent,
  supportedLanguages
};
