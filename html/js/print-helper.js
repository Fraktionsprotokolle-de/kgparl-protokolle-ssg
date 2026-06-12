/**
 * Print Helper - Expands all details elements before printing
 * and optionally restores their state afterwards
 */
(function() {
  'use strict';

  // Track which details were originally open
  var detailsStates = new Map();

  /**
   * Open all details elements and save their original state
   */
  function expandAllDetails() {
    var allDetails = document.querySelectorAll('details');

    allDetails.forEach(function(detail) {
      // Save original state
      detailsStates.set(detail, detail.open);

      // Open the detail
      detail.open = true;
    });

    console.log('Expanded ' + allDetails.length + ' details elements for printing');
  }

  /**
   * Restore details elements to their original state
   */
  function restoreDetailsState() {
    detailsStates.forEach(function(wasOpen, detail) {
      detail.open = wasOpen;
    });

    console.log('Restored details elements to original state');
    detailsStates.clear();
  }

  /**
   * Show all hidden content that should be visible in print
   */
  function expandPrintContent() {
    // Expand all details
    expandAllDetails();

    // Show any elements with .hidden or .d-none that should be visible in print
    // (but not those explicitly marked as hidden-print)
    var hiddenElements = document.querySelectorAll('.hidden:not(.hidden-print), .d-none:not(.d-print-none)');
    hiddenElements.forEach(function(element) {
      element.setAttribute('data-was-hidden', 'true');
      element.classList.remove('hidden', 'd-none');
      element.classList.add('visible-print');
    });
  }

  /**
   * Restore hidden content after printing
   */
  function restorePrintContent() {
    // Restore details state
    restoreDetailsState();

    // Restore hidden elements
    var visiblePrintElements = document.querySelectorAll('[data-was-hidden="true"]');
    visiblePrintElements.forEach(function(element) {
      element.removeAttribute('data-was-hidden');
      element.classList.remove('visible-print');
      element.classList.add('d-none');
    });
  }

  /**
   * Setup print event listeners
   */
  function setupPrintListeners() {
    // Modern browsers
    window.addEventListener('beforeprint', function() {
      console.log('Preparing page for printing...');
      expandPrintContent();
    });

    window.addEventListener('afterprint', function() {
      console.log('Restoring page after printing...');
      restorePrintContent();
    });

    // Fallback for browsers that don't support beforeprint/afterprint
    // Listen for Ctrl+P / Cmd+P
    document.addEventListener('keydown', function(e) {
      if ((e.ctrlKey || e.metaKey) && e.key === 'p') {
        // Give the browser a moment to open print dialog
        setTimeout(expandPrintContent, 10);
      }
    });

    // Also hook into window.print() calls
    var originalPrint = window.print;
    window.print = function() {
      expandPrintContent();
      originalPrint.call(window);
      // Restore after a delay (print dialog may still be open)
      setTimeout(restorePrintContent, 1000);
    };
  }

  /**
   * Initialize print helper when DOM is ready
   */
  function init() {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', setupPrintListeners);
    } else {
      setupPrintListeners();
    }
  }

  // Initialize
  init();

  // Export functions for manual use if needed
  window.printHelper = {
    expandAll: expandPrintContent,
    restore: restorePrintContent,
    expandDetails: expandAllDetails,
    restoreDetails: restoreDetailsState
  };

})();
