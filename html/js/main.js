/**
 * KGParl Fraktionsprotokolle - Main JavaScript
 * Handles mobile menu, navigation dropdowns, and general UI interactions
 */

(function() {
    'use strict';

    // DOM Ready
    document.addEventListener('DOMContentLoaded', function() {
        initMobileMenu();
        initMobileSubmenus();
        initNavDropdowns();
        initSmoothScroll();
        initCurrentPageHighlight();
        initDataVersion();
    });

    /** Show data source version in footer */
    function initDataVersion() {
        if (typeof DATA_VERSION === 'undefined' || !DATA_VERSION) return;
        var el = document.getElementById('data-version');
        if (!el) return;
        var v = DATA_VERSION;
        var date = v.fetchedAt ? new Date(v.fetchedAt).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '';
        el.innerHTML = 'Letzter Datenimport ' + date + ': <a href="https://github.com/' + v.repo + '/commit/' + v.sha +
            '" target="_blank" rel="noopener" title="Commit ' + v.sha + ' auf GitHub anzeigen">' + v.sha + '</a>';
    }

    /**
     * Mobile Menu Toggle
     */
    function initMobileMenu() {
        const menuBtn = document.getElementById('mobile-menu-btn');
        const mobileNav = document.getElementById('mobile-nav');

        if (!menuBtn || !mobileNav) return;

        const openIcon = menuBtn.querySelector('.menu-open-icon');
        const closeIcon = menuBtn.querySelector('.menu-close-icon');

        menuBtn.addEventListener('click', function() {
            const isOpen = mobileNav.classList.contains('active');

            if (isOpen) {
                // Close menu
                mobileNav.classList.remove('active');
                menuBtn.setAttribute('aria-expanded', 'false');
                menuBtn.setAttribute('aria-label', 'Menü öffnen');
                if (openIcon) openIcon.classList.remove('hidden');
                if (closeIcon) closeIcon.classList.add('hidden');
                document.body.style.overflow = '';
            } else {
                // Open menu
                mobileNav.classList.add('active');
                menuBtn.setAttribute('aria-expanded', 'true');
                menuBtn.setAttribute('aria-label', 'Menü schließen');
                if (openIcon) openIcon.classList.add('hidden');
                if (closeIcon) closeIcon.classList.remove('hidden');
                document.body.style.overflow = 'hidden';
            }
        });

        // Close menu on escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && mobileNav.classList.contains('active')) {
                menuBtn.click();
            }
        });

        // Close menu when clicking outside
        document.addEventListener('click', function(e) {
            if (mobileNav.classList.contains('active') &&
                !mobileNav.contains(e.target) &&
                !menuBtn.contains(e.target)) {
                menuBtn.click();
            }
        });
    }

    /**
     * Mobile Submenus Toggle
     */
    function initMobileSubmenus() {
        const toggleButtons = document.querySelectorAll('.mobile-nav-toggle');

        toggleButtons.forEach(function(button) {
            button.addEventListener('click', function() {
                const submenu = button.nextElementSibling;
                const isExpanded = button.getAttribute('aria-expanded') === 'true';

                // Toggle state
                button.setAttribute('aria-expanded', !isExpanded);

                if (submenu) {
                    submenu.classList.toggle('open');
                }
            });
        });
    }

    /**
     * Navigation Dropdowns (Desktop) - WCAG 2.1 Accessible
     */
    function initNavDropdowns() {
        const dropdownTriggers = document.querySelectorAll('.nav-dropdown-trigger');

        dropdownTriggers.forEach(function(trigger) {
            const dropdown = trigger.nextElementSibling;
            const navItem = trigger.closest('.main-nav-item');
            if (!dropdown) return;

            // Toggle dropdown on click
            trigger.addEventListener('click', function(e) {
                e.preventDefault();
                const isExpanded = trigger.getAttribute('aria-expanded') === 'true';

                // Close all other dropdowns first
                dropdownTriggers.forEach(function(otherTrigger) {
                    if (otherTrigger !== trigger) {
                        otherTrigger.setAttribute('aria-expanded', 'false');
                    }
                });

                trigger.setAttribute('aria-expanded', !isExpanded);
            });

            // Keyboard navigation
            trigger.addEventListener('keydown', function(e) {
                if (e.key === 'Escape') {
                    trigger.setAttribute('aria-expanded', 'false');
                    trigger.focus();
                }
                if (e.key === 'ArrowDown' && trigger.getAttribute('aria-expanded') === 'true') {
                    e.preventDefault();
                    const firstLink = dropdown.querySelector('a');
                    if (firstLink) firstLink.focus();
                }
            });

            // Arrow key navigation within dropdown
            dropdown.addEventListener('keydown', function(e) {
                const links = Array.from(dropdown.querySelectorAll('a'));
                const currentIndex = links.indexOf(document.activeElement);

                if (e.key === 'ArrowDown') {
                    e.preventDefault();
                    const nextIndex = (currentIndex + 1) % links.length;
                    links[nextIndex].focus();
                }
                if (e.key === 'ArrowUp') {
                    e.preventDefault();
                    const prevIndex = currentIndex <= 0 ? links.length - 1 : currentIndex - 1;
                    links[prevIndex].focus();
                }
                if (e.key === 'Escape') {
                    trigger.setAttribute('aria-expanded', 'false');
                    trigger.focus();
                }
                if (e.key === 'Tab' && !e.shiftKey && currentIndex === links.length - 1) {
                    trigger.setAttribute('aria-expanded', 'false');
                }
            });

            // Close on click outside
            document.addEventListener('click', function(e) {
                if (!navItem.contains(e.target)) {
                    trigger.setAttribute('aria-expanded', 'false');
                }
            });

            // Close on focus leaving the nav item
            navItem.addEventListener('focusout', function(e) {
                setTimeout(function() {
                    if (!navItem.contains(document.activeElement)) {
                        trigger.setAttribute('aria-expanded', 'false');
                    }
                }, 0);
            });
        });
    }

    /**
     * Smooth Scroll for Anchor Links
     */
    function initSmoothScroll() {
        document.querySelectorAll('a[href^="#"]').forEach(function(anchor) {
            anchor.addEventListener('click', function(e) {
                const targetId = this.getAttribute('href');
                if (targetId === '#') return;

                const target = document.querySelector(targetId);
                if (target) {
                    e.preventDefault();
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });

                    // Update URL without jumping
                    history.pushState(null, null, targetId);
                }
            });
        });
    }

    /**
     * Highlight Current Page in Navigation
     */
    function initCurrentPageHighlight() {
        const currentPath = window.location.pathname;
        const currentPage = currentPath.substring(currentPath.lastIndexOf('/') + 1) || 'index.html';

        // Main navigation
        document.querySelectorAll('.main-nav-link, .nav-dropdown a').forEach(function(link) {
            const href = link.getAttribute('href');
            if (href === currentPage || (currentPage === 'index.html' && href === 'index.html')) {
                link.classList.add('active');
                // Also highlight parent nav item for dropdown items
                const parentItem = link.closest('.main-nav-item');
                if (parentItem) {
                    const parentLink = parentItem.querySelector('.main-nav-link');
                    if (parentLink && parentLink !== link) {
                        parentLink.classList.add('active');
                    }
                }
            }
        });

        // Mobile navigation
        document.querySelectorAll('.mobile-nav a').forEach(function(link) {
            const href = link.getAttribute('href');
            if (href === currentPage) {
                link.classList.add('active');
            }
        });
    }

    /**
     * Utility: Debounce function for scroll/resize events
     */
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = function() {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    // Expose utilities globally if needed
    window.KGParl = window.KGParl || {};
    window.KGParl.debounce = debounce;

})();
