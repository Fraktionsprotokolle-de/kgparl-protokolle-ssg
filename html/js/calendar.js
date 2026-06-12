var popups = [];
var observedBrowserCapabilities = {
  touch: false,
};

const LINK_WINDOW_TARGET = "_self";
const MIN_YEAR = 1949;
const MAX_YEAR = 1998;

// Faction abbreviation mapping for accessibility labels
const FACTION_ABBR = {
  "SPD": "SPD",
  "CDU/CSU": "CDU-CSU",
  "CSU-LG": "CSU-LG",
  "FDP": "FDP",
  "Grüne": "Grü",
  "PDS": "PDS",
};

var handleEnterDay = function (ev) {
  if (observedBrowserCapabilities.touch) {
    return;
  }
  var thisDayHasAnAssociatedPopover = ev.events.length !== 0;
  if (thisDayHasAnAssociatedPopover) {
    showExclusiveNewPopover(ev.events, ev.element, ev.date);
  }
};

var handleLeaveDay = function (ev) {
  if (observedBrowserCapabilities.touch) {
    return;
  }
  var thisDayHasAnAssociatedPopover = ev.events.length !== 0;
  if (thisDayHasAnAssociatedPopover) {
    startPopoverDestructionCountdown();
  }
};

var handleClickDay = function (ev) {
  if (observedBrowserCapabilities.touch) {
    // Delay showing the popover slightly to avoid triggering pointer or mouse events
    // on the popover by accident; there are usually some stragglers
    window.setTimeout(() => {
      showExclusiveNewPopover(ev.events, ev.element, ev.date);
    }, 100);
  } else {
    openDateLink(ev);
  }
};

var openDateLink = function (e) {
  const dayEvents = e.events;
  if (dayEvents.length === 1) {
    const documentId = dayEvents[0].id;
    const documentUrl = mrpLogic.getDocumentUrlFromId(documentId);
    window.open(documentUrl, linkWindowTarget);
  } else if (dayEvents.length > 1) {
    showExclusiveNewPopover(dayEvents, e.element, e.date);
  }
};

var localCache = {
  data: {},
  remove: function (url) {
    delete localCache.data[url];
  },
  exist: function (url) {
    return localCache.data.hasOwnProperty(url) && localCache.data[url] !== null;
  },
  get: function (url) {
    return localCache.data[url];
  },
  set: function (url, cachedData) {
    localCache.remove(url);
    localCache.data[url] = cachedData;
  },
};

let KGParlColors = {
  Grüne: "#00FF00",
  Linke: "#FF0000",
  CDU_CSU: "#000000",
  CSU_LG: "#0080c8",
  SPD: "#FF0000",
  PDS: "#800080",
  FDP: "#FFFF00",
};

var response = KGParlData;
var result = JSON.stringify(response);
const jsonArray = JSON.parse(result);
const data = jsonArray.map((r) => ({
  id: r.id,
  startDate: new Date(r.startDate),
  endDate: new Date(r.startDate),
  fraction: r.fraktion,
  topics: r.topics,
  name: r.name,
  url: window.location.protocol + "//" + window.location.host + "/" + r.id,
  color:
    KGParlColors[r.fraktion.replace("-", "_").replace("/", "_")] || "#808080",
}));

var calendar = new Calendar("#calendar", {
  language: "de",
  enableRangeSelection: false,
  minDate: new Date(1949, 7, 1),   // August 1949 (JS months 0-based)
  maxDate: new Date(1998, 11, 31), // December 1998 (fixed: was month 12 = Jan 1999)
  startYear: MIN_YEAR,
  mouseOnDay: handleEnterDay,
  mouseOutDay: handleLeaveDay,
  clickDay: function(ev) {
    if (ev.events && ev.events.length > 0) {
      showExclusiveNewPopover(ev.events, ev.element, ev.date);
    }
  },
  dataSource: data,
  yearChanged: function(ev) {
    // Clamp year to valid range when user navigates via built-in calendar header
    var year = ev.currentYear;
    if (year < MIN_YEAR) {
      calendar.setYear(MIN_YEAR);
      return;
    }
    if (year > MAX_YEAR) {
      calendar.setYear(MAX_YEAR);
      return;
    }
    updateYearDisplay(year);
    injectFactionLabels();
  },
  renderEnd: function() {
    injectFactionLabels();
    // Accessibility: add scope="col" to calendar table headers and captions
    document.querySelectorAll('#calendar table').forEach(function(table) {
      table.querySelectorAll('th').forEach(function(th) {
        if (!th.getAttribute('scope')) th.setAttribute('scope', 'col');
      });
      if (!table.querySelector('caption')) {
        var monthHeader = table.closest('.month-container')?.querySelector('.month-title');
        if (monthHeader) {
          var caption = document.createElement('caption');
          caption.className = 'sr-only';
          caption.textContent = monthHeader.textContent;
          table.insertBefore(caption, table.firstChild);
        }
      }
    });
  }
});

initializePopoversForJsYearCalendar("#calendar");

// ============ Year Display Button ============
function updateYearDisplay(year) {
  var el = document.getElementById('year-display-text');
  if (el) el.textContent = year;
}

// Initialize display
updateYearDisplay(calendar.getYear());

// Year display button cycles through years on click (opens a simple prompt)
document.getElementById('year-display').addEventListener('click', function() {
  var input = prompt(
    t('calendar.enterYear') + ' (' + MIN_YEAR + '–' + MAX_YEAR + '):',
    calendar.getYear()
  );
  if (input !== null) {
    var year = parseInt(input, 10);
    if (!isNaN(year)) {
      setYear(year);
    }
  }
});

function setYear(year) {
  var validYear = Math.max(MIN_YEAR, Math.min(MAX_YEAR, year));
  calendar.setYear(validYear);
  updateYearDisplay(validYear);
}

// Navigation buttons
document.getElementById('decade-prev').addEventListener('click', function() {
  setYear(calendar.getYear() - 10);
});
document.getElementById('decade-next').addEventListener('click', function() {
  setYear(calendar.getYear() + 10);
});
document.getElementById('year-prev').addEventListener('click', function() {
  setYear(calendar.getYear() - 1);
});
document.getElementById('year-next').addEventListener('click', function() {
  setYear(calendar.getYear() + 1);
});

// ============ Accessibility: Inject faction labels into day cells ============
// Uses data-faction attribute + CSS ::after to avoid polluting .day-content textContent,
// which the js-year-calendar library reads via _getDate() to determine the day number.
function injectFactionLabels() {
  requestAnimationFrame(function() {
    var currentYear = calendar.getYear();

    // Build a map: "YYYY-MM-DD" -> [faction1, faction2, ...]
    var dayFactions = {};
    data.forEach(function(ev) {
      var d = ev.startDate;
      if (d.getFullYear() !== currentYear) return;
      var key = d.getFullYear() + '-' +
        String(d.getMonth() + 1).padStart(2, '0') + '-' +
        String(d.getDate()).padStart(2, '0');
      if (!dayFactions[key]) dayFactions[key] = [];
      var abbr = FACTION_ABBR[ev.fraction] || ev.fraction;
      if (dayFactions[key].indexOf(abbr) === -1) {
        dayFactions[key].push(abbr);
      }
    });

    // Set data-faction on td.day cells (rendered by CSS ::after on .day-content)
    var dayCells = document.querySelectorAll('#calendar td.day:not(.old):not(.new)');
    dayCells.forEach(function(cell) {
      // Remove previous attribute
      var content = cell.querySelector('.day-content');
      if (!content) return;
      content.removeAttribute('data-faction');

      var dayNum = parseInt(content.textContent, 10);
      if (isNaN(dayNum)) return;

      var monthContainer = cell.closest('.month-container');
      if (!monthContainer) return;
      var monthId = parseInt(monthContainer.dataset.monthId, 10);
      if (isNaN(monthId)) return;

      // monthId is 0-based offset from startDate month (January = 0 for full-year)
      var monthIndex = calendar.getStartDate().getMonth() + monthId;

      var key = currentYear + '-' +
        String(monthIndex + 1).padStart(2, '0') + '-' +
        String(dayNum).padStart(2, '0');

      var factions = dayFactions[key];
      if (factions && factions.length > 0) {
        content.setAttribute('data-faction', factions.join(', '));
      }
    });
  });
}

// Initial injection
injectFactionLabels();

// Sync year display when calendar header year changes via built-in navigation
var observer = new MutationObserver(function() {
  var yearHeader = document.querySelector('.calendar-header th');
  if (yearHeader) {
    var yearMatch = yearHeader.textContent.match(/\d{4}/);
    if (yearMatch) {
      var displayedYear = parseInt(yearMatch[0], 10);
      // Clamp if out of range
      if (displayedYear < MIN_YEAR) {
        calendar.setYear(MIN_YEAR);
        return;
      }
      if (displayedYear > MAX_YEAR) {
        calendar.setYear(MAX_YEAR);
        return;
      }
      updateYearDisplay(displayedYear);
    }
  }
});

var calendarElement = document.getElementById('calendar');
if (calendarElement) {
  observer.observe(calendarElement, {
    childList: true,
    subtree: true,
    characterData: true
  });
}

// Switch calendar language on i18next language change
if (typeof i18next !== 'undefined' && typeof i18next.on === 'function') {
  i18next.on('languageChanged', function(lng) {
    var calLang = (lng === 'de') ? 'de' : 'en';
    var currentYear = calendar.getYear();
    calendar.setLanguage(calLang);
    calendar.setYear(currentYear);
    updateYearDisplay(currentYear);
    injectFactionLabels();
  });
}
