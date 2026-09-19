import json
import subprocess
import time
import os
import re

UDID = os.environ.get("UDID")
BUNDLE_ID = "tj.masterchas.masterchasApp"
SCREEN_DIR = "screenshots"
os.makedirs(SCREEN_DIR, exist_ok=True)


def run(cmd, timeout=30):
    print(f"$ {' '.join(cmd)}", flush=True)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        if r.stdout:
            print(r.stdout[:3000], flush=True)
        if r.stderr:
            print("STDERR:", r.stderr[:2000], flush=True)
        return r
    except Exception as e:
        print("EXC running command:", e, flush=True)
        return None


def screenshot(name):
    path = os.path.join(SCREEN_DIR, name)
    run(["xcrun", "simctl", "io", UDID, "screenshot", path])
    print(f"Saved screenshot {path}", flush=True)


def describe_all(tag):
    """Try to get the accessibility tree as a list of dicts, tolerating
    different idb output shapes (single JSON array, or JSON-lines)."""
    r = run(["idb", "ui", "describe-all", "--udid", UDID, "--json"], timeout=25)
    data = []
    if r is not None and r.stdout.strip():
        raw = r.stdout.strip()
        try:
            data = json.loads(raw)
            if isinstance(data, dict):
                data = [data]
        except Exception:
            # maybe JSON-lines
            items = []
            for line in raw.splitlines():
                line = line.strip()
                if not line:
                    continue
                try:
                    items.append(json.loads(line))
                except Exception:
                    pass
            data = items
    if not data:
        # retry without --json in case the flag isn't supported
        r2 = run(["idb", "ui", "describe-all", "--udid", UDID], timeout=25)
        if r2 is not None and r2.stdout.strip():
            raw = r2.stdout.strip()
            try:
                data = json.loads(raw)
            except Exception:
                items = []
                for line in raw.splitlines():
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        items.append(json.loads(line))
                    except Exception:
                        pass
                data = items
    try:
        with open(f"tree-{tag}.json", "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print("could not write tree json:", e, flush=True)
    print(f"[{tag}] parsed {len(data)} accessibility elements", flush=True)
    return data if isinstance(data, list) else []


def elem_text(el):
    if not isinstance(el, dict):
        return ""
    parts = []
    for key in ("AXLabel", "label", "title", "AXValue", "value", "help_text",
                "role_description", "placeholder_value"):
        v = el.get(key)
        if isinstance(v, str) and v.strip():
            parts.append(v.strip())
    return " | ".join(parts)


def elem_center(el):
    frame = el.get("frame") if isinstance(el, dict) else None
    if frame is None and isinstance(el, dict):
        frame = el.get("AXFrame")
    if isinstance(frame, dict):
        x = frame.get("x", 0)
        y = frame.get("y", 0)
        w = frame.get("width", 0)
        h = frame.get("height", 0)
        try:
            return float(x) + float(w) / 2, float(y) + float(h) / 2
        except Exception:
            return None
    if isinstance(frame, str):
        nums = re.findall(r"[-\d.]+", frame)
        if len(nums) >= 4:
            x, y, w, h = map(float, nums[:4])
            return x + w / 2, y + h / 2
    return None


def find_matches(elements, keywords):
    matches = []
    for el in elements:
        text = elem_text(el)
        if not text:
            continue
        low = text.lower()
        for kw in keywords:
            if kw.lower() in low:
                matches.append((el, text))
                break
    return matches


def tap(x, y):
    run(["idb", "ui", "tap", str(x), str(y), "--udid", UDID])


def type_text(text):
    run(["idb", "ui", "text", text, "--udid", UDID])


def tap_first_match(elements, keywords, tag):
    matches = find_matches(elements, keywords)
    print(f"[{tag}] matches for {keywords}: {[t for _, t in matches]}", flush=True)
    if not matches:
        return False
    el, text = matches[0]
    c = elem_center(el)
    if not c:
        print(f"[{tag}] matched '{text}' but no usable frame", flush=True)
        return False
    x, y = c
    print(f"[{tag}] tapping '{text}' at ({x:.1f}, {y:.1f})", flush=True)
    tap(x, y)
    return True


def step(name):
    print(f"\n=== STEP: {name} ===", flush=True)


def main():
    step("initial state")
    time.sleep(3)
    screenshot("10-launch.png")
    els = describe_all("00-launch")

    step("select master role (Я мастер)")
    tap_first_match(els, ["я мастер", "мастер"], "role-select")
    time.sleep(2)
    screenshot("11-after-role-tap.png")
    els = describe_all("01-after-role")

    step("find login / register entry point")
    tap_first_match(els, ["войти", "регистр", "продолж", "начать"], "login-entry")
    time.sleep(2)
    screenshot("12-after-login-entry.png")
    els = describe_all("02-after-login-entry")

    step("enter phone number")
    tap_first_match(els, ["телефон", "номер", "phone"], "phone-field")
    time.sleep(1)
    type_text("989003100")
    time.sleep(1)
    screenshot("13-after-phone.png")
    els = describe_all("03-after-phone")

    step("submit phone / request code")
    tap_first_match(els, ["войти", "получить", "далее", "продолж", "отправ"], "phone-submit")
    time.sleep(3)
    screenshot("14-after-phone-submit.png")
    els = describe_all("04-after-phone-submit")

    step("enter confirmation code")
    tap_first_match(els, ["код", "code"], "code-field")
    time.sleep(1)
    type_text("umRJO.1711")
    time.sleep(1)
    screenshot("15-after-code.png")
    els = describe_all("05-after-code")

    step("confirm code")
    tap_first_match(els, ["подтверд", "войти", "далее", "готово"], "code-submit")
    time.sleep(4)
    screenshot("16-after-code-submit.png")
    els = describe_all("06-after-code-submit")

    step("wait for home screen to settle")
    time.sleep(4)
    screenshot("20-home-glavnaya.png")
    els = describe_all("07-home")

    step("find and tap catalog tab")
    tap_first_match(els, ["каталог", "catalog"], "catalog-tab")
    time.sleep(3)
    screenshot("21-catalog.png")
    describe_all("08-catalog")

    step("done")
    screenshot("30-final-state.png")
    print("automate.py finished successfully", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("FATAL ERROR in automate.py:", e, flush=True)
        try:
            screenshot("99-error-state.png")
        except Exception:
            pass
