import { chromium } from 'playwright';

const BASE = process.env.ADMIN_URL ?? 'http://127.0.0.1:58923';
const PHONE = '+992900000099';
const PASSWORD = 'MasterChas2025!';

const browser = await chromium.launch({ headless: true, channel: 'msedge' });
const page = await browser.newPage();

try {
  await page.goto(`${BASE}/admin/login`, { waitUntil: 'networkidle', timeout: 60000 });

  const phoneField = page.locator('input').first();
  await phoneField.fill('900000099');

  const passwordField = page.locator('input[type="password"]');
  await passwordField.fill(PASSWORD);

  await page.getByRole('button', { name: 'Войти' }).click();

  await page.waitForURL(/\/admin\/dashboard/, { timeout: 30000 });
  await page.waitForTimeout(3000);

  const url = page.url();
  const hasDashboard = url.includes('/admin/dashboard');
  const bodyText = await page.locator('body').innerText();

  console.log(JSON.stringify({
    ok: hasDashboard,
    url,
    hasOrdersLabel: bodyText.includes('Заказы') || bodyText.includes('Admin Dashboard'),
    snippet: bodyText.slice(0, 300).replace(/\s+/g, ' '),
  }, null, 2));

  if (!hasDashboard) process.exit(1);
} catch (err) {
  console.error('FAIL:', err.message);
  process.exit(1);
} finally {
  await browser.close();
}
