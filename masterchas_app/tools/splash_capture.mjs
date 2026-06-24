import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';

const url = process.argv[2] || 'http://localhost:6209/#/splash';
const outDir = process.argv[3] || 'splash_capture_output';
const delays = [200, 1000, 2000, 3000, 4000];

fs.mkdirSync(outDir, { recursive: true });

const browser = await puppeteer.launch({
  headless: true,
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
});

const page = await browser.newPage();
await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2 });

const consoleLogs = [];
page.on('console', (msg) => {
  consoleLogs.push({ type: msg.type(), text: msg.text() });
});
page.on('pageerror', (err) => {
  consoleLogs.push({ type: 'pageerror', text: err.message });
});
page.on('requestfailed', (req) => {
  consoleLogs.push({
    type: 'requestfailed',
    text: `${req.url()} :: ${req.failure()?.errorText || 'failed'}`,
  });
});

await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
await page.reload({ waitUntil: 'networkidle0', timeout: 60000 });

const start = Date.now();
for (const delay of delays) {
  const elapsed = Date.now() - start;
  const waitMs = Math.max(0, delay - elapsed);
  if (waitMs > 0) await new Promise((r) => setTimeout(r, waitMs));
  const shotPath = path.join(outDir, `splash_${delay}ms.png`);
  await page.screenshot({ path: shotPath, fullPage: false });
  console.log(`saved ${shotPath}`);
}

const domInfo = await page.evaluate(() => {
  const canvases = [...document.querySelectorAll('canvas')].map((c) => ({
    width: c.width,
    height: c.height,
    style: c.getAttribute('style'),
  }));
  const fltGlass = document.querySelector('flt-glass-pane');
  const textNodes = [...document.querySelectorAll('body *')]
    .filter((el) => el.textContent?.includes('Master.tj'))
    .map((el) => ({
      tag: el.tagName,
      text: el.textContent,
      visible: !!(el.offsetWidth || el.offsetHeight),
    }));
  return {
    title: document.title,
    hash: location.hash,
    bodyChildren: document.body?.children.length ?? 0,
    canvases,
    hasFltGlass: !!fltGlass,
    textNodes,
    bodyTextSample: document.body?.innerText?.slice(0, 500) ?? '',
  };
});

fs.writeFileSync(path.join(outDir, 'console.json'), JSON.stringify(consoleLogs, null, 2));
fs.writeFileSync(path.join(outDir, 'dom.json'), JSON.stringify(domInfo, null, 2));

console.log('DOM INFO:', JSON.stringify(domInfo, null, 2));
console.log('CONSOLE ERRORS:', JSON.stringify(consoleLogs.filter((l) => l.type === 'error' || l.type === 'pageerror'), null, 2));

await browser.close();
