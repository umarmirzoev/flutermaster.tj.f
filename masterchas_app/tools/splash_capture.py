"""Capture splash screen at fixed delays after reload + browser console logs."""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:6209/#/splash"
OUT_DIR = Path(sys.argv[2] if len(sys.argv) > 2 else "splash_capture_output")
DELAYS_S = [0.2, 1.0, 2.0, 3.0, 4.0]


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    options = Options()
    options.add_argument("--window-size=390,844")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.set_capability("goog:loggingPrefs", {"browser": "ALL", "performance": "ALL"})

    driver = webdriver.Chrome(options=options)
    console_logs: list[dict] = []

    try:
        driver.get(URL)
        WebDriverWait(driver, 90).until(
            EC.presence_of_element_located((By.TAG_NAME, "flt-glass-pane"))
        )
        time.sleep(2)

        driver.refresh()
        WebDriverWait(driver, 90).until(
            EC.presence_of_element_located((By.TAG_NAME, "flt-glass-pane"))
        )

        reload_start = time.perf_counter()
        for delay in DELAYS_S:
            elapsed = time.perf_counter() - reload_start
            wait_s = max(0.0, delay - elapsed)
            if wait_s:
                time.sleep(wait_s)
            shot = OUT_DIR / f"splash_{int(delay * 1000)}ms.png"
            driver.save_screenshot(str(shot))
            print(f"saved {shot}")

        for entry in driver.get_log("browser"):
            console_logs.append(
                {
                    "level": entry.get("level"),
                    "message": entry.get("message"),
                    "source": entry.get("source"),
                    "timestamp": entry.get("timestamp"),
                }
            )

        dom_info = driver.execute_script(
            """
            return {
              title: document.title,
              hash: location.hash,
              href: location.href,
              bodyChildren: document.body?.children.length ?? 0,
              canvases: [...document.querySelectorAll('canvas')].map(c => ({
                width: c.width, height: c.height
              })),
              hasFltGlass: !!document.querySelector('flt-glass-pane'),
              bodyText: document.body?.innerText?.slice(0, 800) ?? '',
              bodyBg: getComputedStyle(document.body).backgroundColor,
            };
            """
        )

        (OUT_DIR / "console.json").write_text(
            json.dumps(console_logs, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        (OUT_DIR / "dom.json").write_text(
            json.dumps(dom_info, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

        errors = [
            e for e in console_logs if str(e.get("level", "")).upper() in {"SEVERE", "ERROR"}
        ]
        print("DOM:", json.dumps(dom_info, ensure_ascii=False, indent=2))
        print("CONSOLE ERRORS:", json.dumps(errors, ensure_ascii=False, indent=2))
    finally:
        driver.quit()


if __name__ == "__main__":
    main()
