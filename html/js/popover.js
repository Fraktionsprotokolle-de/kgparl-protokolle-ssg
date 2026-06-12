/**
 * Custom Popover Implementation (No Bootstrap dependency)
 * For the KGParl Calendar
 */

let allPopoverElements = [];
let popoverDestructionCountdownActive = false;
let calendarJQueryElement = undefined;
let pendingPopoverTimeout = null;

const months = [
  "Januar",
  "Februar",
  "März",
  "April",
  "Mai",
  "Juni",
  "Juli",
  "August",
  "September",
  "Oktober",
  "November",
  "Dezember",
];
const POPOVER_DESTRUCTION_GRACE_PERIOD_MS = 750;
const POPOVER_HIDE_DELAY_MS = 400;

// Custom Popover Class
class CustomPopover {
  constructor(targetElement, options) {
    this.targetElement = targetElement;
    this.options = {
      title: '',
      content: '',
      placement: 'right',
      ...options
    };
    this.popoverElement = null;
  }

  create() {
    // Create popover element
    this.popoverElement = document.createElement('div');
    this.popoverElement.className = 'custom-popover';
    this.popoverElement.innerHTML = `
      <div class="custom-popover-arrow"></div>
      <div class="custom-popover-header">${this.options.title}</div>
      <div class="custom-popover-body">${this.options.content}</div>
    `;
    document.body.appendChild(this.popoverElement);

    // Position the popover
    this.position();

    // Add event listeners for popover itself
    this.popoverElement.addEventListener('pointerenter', (ev) => {
      if (ev.pointerType === 'touch') return;
      // Cancel any pending replacement — user reached the popover
      if (pendingPopoverTimeout) {
        clearTimeout(pendingPopoverTimeout);
        pendingPopoverTimeout = null;
      }
      abortPopoverDestructionCountdown();
    });

    this.popoverElement.addEventListener('pointerleave', (ev) => {
      if (ev.pointerType === 'touch') return;
      removeAllPopovers();
      abortPopoverDestructionCountdown();
    });

    // Add listeners to tooltip entries
    const tooltipEntries = this.popoverElement.querySelectorAll('.event-tooltip-entry');
    tooltipEntries.forEach((tooltip) => {
      tooltip.addEventListener('pointerenter', (ev) => {
        if (ev.pointerType === 'touch') return;
        abortPopoverDestructionCountdown();
      });
    });
  }

  position() {
    if (!this.popoverElement || !this.targetElement) return;

    const target = this.targetElement[0] || this.targetElement;
    const targetRect = target.getBoundingClientRect();
    const popoverRect = this.popoverElement.getBoundingClientRect();

    let top, left;

    // Default placement is right
    if (this.options.placement === 'right') {
      top = targetRect.top + window.scrollY + (targetRect.height / 2) - (popoverRect.height / 2);
      left = targetRect.right + window.scrollX + 10;

      // If popover goes off screen right, place it left
      if (left + popoverRect.width > window.innerWidth) {
        left = targetRect.left + window.scrollX - popoverRect.width - 10;
        this.popoverElement.classList.add('popover-left');
      }
    } else if (this.options.placement === 'top') {
      top = targetRect.top + window.scrollY - popoverRect.height - 10;
      left = targetRect.left + window.scrollX + (targetRect.width / 2) - (popoverRect.width / 2);
    } else if (this.options.placement === 'bottom') {
      top = targetRect.bottom + window.scrollY + 10;
      left = targetRect.left + window.scrollX + (targetRect.width / 2) - (popoverRect.width / 2);
    }

    // Ensure popover stays within viewport
    if (left < 10) left = 10;
    if (top < 10) top = 10;

    this.popoverElement.style.top = `${top}px`;
    this.popoverElement.style.left = `${left}px`;
  }

  show() {
    if (!this.popoverElement) {
      this.create();
    }
    this.popoverElement.classList.add('show');
  }

  hide() {
    if (this.popoverElement) {
      this.popoverElement.classList.remove('show');
    }
  }

  dispose() {
    if (this.popoverElement && this.popoverElement.parentNode) {
      this.popoverElement.parentNode.removeChild(this.popoverElement);
      this.popoverElement = null;
    }
  }
}

// Store popover instances on elements
const popoverInstances = new WeakMap();

function initializePopoversForJsYearCalendar(calendarSelector) {
  calendarJQueryElement = $(calendarSelector);
  // No need for Bootstrap's inserted.bs.popover event anymore
}

function initializePopoversForHeatmapCalendar(popoverData, heatmapElement) {
  calendarJQueryElement = $(heatmapElement).parent();
  addHeatmapDayHoverHandlers(
    popoverData,
    heatmapElement,
    calendarJQueryElement,
  );
}

function addHeatmapDayHoverHandlers(
  popoverData,
  heatmapElement,
  popoverContainer,
) {
  for (let [isoDate, { documents, jsDate }] of Object.entries(popoverData)) {
    const selector = `g > title:contains("${isoDate}")`;
    const container = $(selector).parent();
    container.on("pointerenter", (jQueryEvent) => {
      const event = jQueryEvent.originalEvent;
      if (event.pointerType === "touch") {
        return;
      }
      showExclusiveNewPopover(documents, container, jsDate);
    });
    container.on("pointerleave", (jQueryEvent) => {
      const event = jQueryEvent.originalEvent;
      if (event.pointerType === "touch") {
        return;
      }
      startPopoverDestructionCountdown();
    });
    container.on("pointerup", (jQueryEvent) => {
      const event = jQueryEvent.originalEvent;
      if (event.pointerType === "touch") {
        setTimeout(
          () => showExclusiveNewPopover(documents, container, jsDate),
          100,
        );
      }
    });
  }
}

function showExclusiveNewPopover(mrpDocuments, dayElement, date) {
  // Cancel any pending popover creation from a previous cell
  if (pendingPopoverTimeout) {
    clearTimeout(pendingPopoverTimeout);
    pendingPopoverTimeout = null;
  }

  // If a popover is already visible, delay replacing it so the user
  // can move the mouse into the existing popover without it being
  // destroyed by briefly crossing an adjacent calendar cell.
  if (allPopoverElements.length > 0) {
    pendingPopoverTimeout = setTimeout(function () {
      pendingPopoverTimeout = null;
      removeAllPopovers();
      let popoverContent = createPopoverContent(mrpDocuments);
      createAndShowNewPopover(dayElement, date, popoverContent);
      abortPopoverDestructionCountdown();
    }, 300);
  } else {
    removeAllPopovers();
    let popoverContent = createPopoverContent(mrpDocuments);
    createAndShowNewPopover(dayElement, date, popoverContent);
    abortPopoverDestructionCountdown();
  }
}

function startPopoverDestructionCountdown() {
  window.setTimeout(function () {
    if (popoverDestructionCountdownActive) {
      removeAllPopovers();
    }
  }, POPOVER_DESTRUCTION_GRACE_PERIOD_MS);

  popoverDestructionCountdownActive = true;
}

function abortPopoverDestructionCountdown() {
  popoverDestructionCountdownActive = false;
}

function removeAllPopovers() {
  while (allPopoverElements.length > 0) {
    let popover = allPopoverElements.pop();
    popover.dispose();
  }
}

function registerPopover(popover) {
  allPopoverElements.push(popover);
}

function createAndShowNewPopover(dayElement, date, content) {
  const dateString = new Date(date);
  const monthIndex = dateString.getMonth();
  const monthName = months[monthIndex];
  const day = String(dateString).split(" ")[2];
  const year = dateString.getFullYear();

  const datevalue = day + ". " + monthName + " " + year;
  const title = datevalue;

  const popover = new CustomPopover(dayElement, {
    title: title,
    content: content,
    placement: 'right'
  });

  registerPopover(popover);
  popover.show();
}

function createPopoverContent(mrpDocuments) {
  if (mrpDocuments.length > 0) {
    var host = window.location.protocol + "//" + window.location.host;
    return `<div class="event-tooltip-content">
		${mrpDocuments
      .map(
        (
          doc,
        ) => `<div class="event-tooltip-entry ${doc.fraction}">
				<h4><a href="${host}/${doc.id}.html" class="event-tooltip-link">${doc.fraction.replace('/', '-')}</a></h4>
			    <ul>${doc.topics
            .map(
              (element) =>
                `<li class="turboline"><a href="${host}/${doc.id}${element.corresp && !element.corresp.startsWith('#') ? '#' : ''}${element.corresp || ''}">${element.title}</a></li>`,
            )
            .join("")}</ul>
				</div>`,
      )
      .join("<br/>")}
		</div>`;
  } else {
    return null;
  }
}

function eventItemsAsListItems(items, base_url) {
  if (!items.map) {
    return "";
  } else {
    return items.map((item) => `<li>${item.name}</li>`).join("");
  }
}

document.addEventListener("pointerup", function (ev) {
  // Don't dismiss popover when clicking a link inside it
  if (ev.target.closest('.custom-popover a')) return;
  // Any click removes all popovers
  removeAllPopovers();
  abortPopoverDestructionCountdown();
});
