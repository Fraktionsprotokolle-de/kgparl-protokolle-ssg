// Debug script to check layout styles
const fs = require('fs');
const path = require('path');

// Read the HTML file
const htmlPath = path.join(__dirname, 'liste.html');
const html = fs.readFileSync(htmlPath, 'utf-8');

console.log('\n=== HTML STRUCTURE ANALYSIS ===\n');

// Check if aside.sidebar exists
if (html.includes('aside class="sidebar"')) {
    console.log('✓ Found: <aside class="sidebar">');
} else {
    console.log('✗ Not found: aside with class="sidebar"');
}

// Check if div#hits exists
if (html.includes('id="hits"')) {
    console.log('✓ Found: element with id="hits"');
} else {
    console.log('✗ Not found: element with id="hits"');
}

// Check if searchbox exists
if (html.includes('id="searchbox"')) {
    console.log('✓ Found: element with id="searchbox"');
} else {
    console.log('✗ Not found: element with id="searchbox"');
}

// Check if year-menu exists
if (html.includes('id="year-menu"')) {
    console.log('✓ Found: element with id="year-menu"');
} else {
    console.log('✗ Not found: element with id="year-menu"');
}

// Check main structure
if (html.includes('main class="d-flex')) {
    console.log('✓ Found: <main> with d-flex class');

    // Extract the main element
    const mainMatch = html.match(/<main[^>]*>([\s\S]*?)<\/main>/);
    if (mainMatch) {
        const mainContent = mainMatch[0];
        console.log('\n=== MAIN ELEMENT CLASSES ===');
        const classMatch = mainContent.match(/class="([^"]*)"/);
        if (classMatch) {
            console.log('Classes:', classMatch[1]);
        }
    }
}

// Check for any CSS related to sidebar in inline styles
console.log('\n=== INLINE STYLES ===');
const inlineStyleMatches = html.match(/<style[^>]*>([\s\S]*?)<\/style>/g);
if (inlineStyleMatches) {
    inlineStyleMatches.forEach((style, index) => {
        if (style.includes('sidebar') || style.includes('container') || style.includes('year-menu') || style.includes('searchbox')) {
            console.log(`\nInline Style Block ${index + 1}:`);
            console.log(style);
        }
    });
}

console.log('\n=== RECOMMENDATIONS ===\n');
console.log('1. The aside.sidebar has no CSS styling defined');
console.log('2. The main element uses d-flex (Bootstrap flexbox)');
console.log('3. Container has width: 65vw set in inline styles');
console.log('4. #year-menu has margin-left: 12px in kgparl.css');
console.log('\nTo fix the layout issues:');
console.log('- Add CSS for .sidebar to set width and height');
console.log('- Ensure searchbox and year-menu have width: 100%');
console.log('- Make aside.sidebar height match the main content area');
