#!/usr/bin/env node
//
// doc-review-batch.mjs — Post multiple anchored inline comments on a Google Doc
// in a single browser session via Playwright keyboard automation.
//
// Usage:
//   node doc-review-batch.mjs <DOC_URL> [COMMENTS_JSON_PATH]
//
// COMMENTS_JSON_PATH defaults to /tmp/doc-review-comments.json
// Expected JSON format:
//   [
//     { "searchTerm": "exact text from doc", "comment": "Your feedback here" },
//     ...
//   ]
//
// Multi-tab support:
//   Each comment may include an optional "tabUrl" field. When present, the script
//   navigates to that URL before posting the comment. Comments are grouped by
//   tabUrl to minimize navigation. Comments without tabUrl use DOC_URL.
//
//   [
//     { "tabUrl": "https://docs.google.com/.../edit?tab=t.abc", "searchTerm": "...", "comment": "..." },
//     { "tabUrl": "https://docs.google.com/.../edit?tab=t.xyz", "searchTerm": "...", "comment": "..." }
//   ]
//

import { createRequire } from 'module';
import { existsSync, readFileSync, realpathSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

// Resolve playwright from the skill's own node_modules directory.
// The skill dir is often reached via symlink (~/.config/opencode/skills ->
// ~/workstation-setup/...), and ESM resolves from the *real* path, not the
// symlink. Using createRequire anchored to the real __dirname ensures we
// always find the locally-installed playwright regardless of symlinks or cwd.
const __filename = realpathSync(fileURLToPath(import.meta.url));
const __dirname = dirname(__filename);
const require = createRequire(join(__dirname, 'package.json'));
const { chromium } = require('playwright');

const DOC_URL = process.argv[2];
const COMMENTS_PATH = process.argv[3] || '/tmp/doc-review-comments.json';
const AUTH_STATE = '/tmp/google-docs-auth.json';

if (!DOC_URL) {
  console.error('Usage: node doc-review-batch.mjs <DOC_URL> [COMMENTS_JSON_PATH]');
  process.exit(1);
}

if (!existsSync(COMMENTS_PATH)) {
  console.error(`Comments file not found: ${COMMENTS_PATH}`);
  process.exit(1);
}

const comments = JSON.parse(readFileSync(COMMENTS_PATH, 'utf-8'));
if (!Array.isArray(comments) || comments.length === 0) {
  console.error('Comments file must be a non-empty JSON array');
  process.exit(1);
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function getAuthenticatedPage(headlessBrowser) {
  if (existsSync(AUTH_STATE)) {
    console.log('Loading saved Google session...');
    const context = await headlessBrowser.newContext({
      storageState: AUTH_STATE,
      viewport: { width: 1400, height: 900 },
    });
    const page = await context.newPage();
    await page.goto(DOC_URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
    await sleep(5000);

    const title = await page.title();
    if (!title.includes('Sign-in') && !title.includes('Sign in')) {
      console.log(`Session valid: ${title}`);
      return { context, page, browser: headlessBrowser };
    }
    console.log('Saved session expired. Re-authenticating...');
    await page.close();
    await context.close();
  }

  console.log('\n=== One-time login required ===');
  console.log('A Chrome window will open. Log into Google.');
  console.log('Session will be saved — all future runs are fully headless.\n');

  await headlessBrowser.close();
  const visibleBrowser = await chromium.launch({
    headless: false,
    channel: 'chrome',
    args: ['--disable-blink-features=AutomationControlled'],
  });

  const context = await visibleBrowser.newContext({ viewport: { width: 1400, height: 900 } });
  const page = await context.newPage();
  await page.goto('https://accounts.google.com/ServiceLogin?continue=' + encodeURIComponent(DOC_URL));

  await page.waitForURL('**/document/**', { timeout: 300000 });
  await sleep(3000);

  await context.storageState({ path: AUTH_STATE });
  console.log(`Logged in! Session saved to ${AUTH_STATE}`);
  console.log('Closing visible browser, switching to headless...\n');
  await context.close();
  await visibleBrowser.close();

  const newBrowser = await chromium.launch({
    headless: true,
    channel: 'chrome',
    args: ['--disable-blink-features=AutomationControlled'],
  });
  const newContext = await newBrowser.newContext({
    storageState: AUTH_STATE,
    viewport: { width: 1400, height: 900 },
  });
  const newPage = await newContext.newPage();
  await newPage.goto(DOC_URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await sleep(5000);
  console.log(`Headless session loaded: ${await newPage.title()}`);
  return { context: newContext, page: newPage, browser: newBrowser };
}

// Group comments by tabUrl, preserving order within each group.
// Comments without tabUrl are grouped under DOC_URL.
function groupCommentsByTab(comments) {
  const groups = new Map();
  for (const c of comments) {
    const url = c.tabUrl || DOC_URL;
    if (!groups.has(url)) {
      groups.set(url, []);
    }
    groups.get(url).push(c);
  }
  return groups;
}

const totalComments = comments.length;

async function postComment(page, searchTerm, commentText, globalIndex) {
  console.log(`\n[${globalIndex + 1}/${totalComments}] Searching: "${searchTerm}"`);

  // Open Find with Cmd+F
  await page.keyboard.press('Meta+f');
  await sleep(1000);

  // Type search term
  await page.keyboard.type(searchTerm, { delay: 30 });
  await sleep(600);

  // Press Enter to find the match
  await page.keyboard.press('Enter');
  await sleep(500);

  // Close find bar — selection stays on matched text
  await page.keyboard.press('Escape');
  await sleep(500);

  // Open comment dialog: Cmd+Alt+M
  await page.keyboard.press('Meta+Alt+m');
  await sleep(1500);

  // Type the comment text
  await page.keyboard.type(commentText, { delay: 20 });
  await sleep(400);

  // Submit with Cmd+Enter
  await page.keyboard.press('Meta+Enter');
  await sleep(1500);

  console.log(`  -> Comment posted.`);
}

async function main() {
  const commentsByTab = groupCommentsByTab(comments);
  const tabCount = commentsByTab.size;

  console.log(`Doc:      ${DOC_URL}`);
  console.log(`Comments: ${totalComments} from ${COMMENTS_PATH}`);
  console.log(`Tabs:     ${tabCount}\n`);

  let browser = await chromium.launch({
    headless: true,
    channel: 'chrome',
    args: ['--disable-blink-features=AutomationControlled'],
  });

  try {
    const { context, page, browser: activeBrowser } = await getAuthenticatedPage(browser);
    browser = activeBrowser;

    let posted = 0;
    let failed = 0;
    let globalIndex = 0;
    let currentUrl = DOC_URL;
    let tabIndex = 0;

    for (const [tabUrl, tabComments] of commentsByTab) {
      tabIndex++;

      // Navigate to the tab if it differs from the current page
      if (tabUrl !== currentUrl) {
        console.log(`\n--- Navigating to tab ${tabIndex}/${tabCount}: ${tabUrl} ---`);
        try {
          await page.goto(tabUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
          await sleep(5000);
          currentUrl = tabUrl;
          console.log(`Tab loaded: ${await page.title()}`);
        } catch (err) {
          console.error(`Failed to navigate to tab: ${err.message}`);
          console.error(`Skipping ${tabComments.length} comments for this tab.`);
          failed += tabComments.length;
          globalIndex += tabComments.length;
          continue;
        }
      } else if (tabCount > 1) {
        console.log(`\n--- Tab ${tabIndex}/${tabCount}: ${tabUrl} (already loaded) ---`);
      }

      for (const { searchTerm, comment } of tabComments) {
        if (!searchTerm || !comment) {
          console.log(`\n[${globalIndex + 1}/${totalComments}] Skipping — missing searchTerm or comment`);
          failed++;
          globalIndex++;
          continue;
        }
        try {
          await postComment(page, searchTerm, comment, globalIndex);
          posted++;
        } catch (err) {
          console.error(`  -> Failed: ${err.message}`);
          failed++;
        }
        globalIndex++;
      }
    }

    console.log(`\nDone. Posted: ${posted}, Failed: ${failed}`);

    // Save session for next time
    await context.storageState({ path: AUTH_STATE });
    await context.close();
  } finally {
    await browser.close();
  }
}

main().catch(e => {
  console.error(e);
  process.exit(1);
});
