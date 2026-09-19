import json
import subprocess
import time
import os
import re

UDID = os.environ.get("UDID")
BUNDLE_ID = "tj.masterchas.masterchasApp"
SCREEN_DIR = "screenshots"
os.makedirs(SCREEN_DIR, exist_ok=True)

# Flutter's semantics tree on this app groups whole "cards" (icon + title +
# subtitle + chips + button) into a SINGLE accessibility element whose
# AXLabel is all the lines joined by "\n", with the action word (e.g.
# "Войти") as the last line. There is no separate tappable node for the
# button itself, so tapping the element's geometric center often lands on
# dead space. We detect that pattern and aim near the bottom of the card
# instead, where the actual button renders.
ACTION_WORDS = (
    "войти", "далее", "подтвердить", "продолжить", "готово",
    "отправить", "получить код", "зарегистрироваться", "начать",
)


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


def describe_all(tag, retries=3):
    """Try to get the accessibility tree as a list of dicts, tolerating
    different idb output shapes and transient empty results (idb sometimes
    needs a moment after the companion starts before it reports elements)."""
    data = []
    for attempt in range(retries):
        r = run(["idb", "ui", "describe-all", "--udid", UDID, "--json"], timeout=25)
        if r is not None and r.stdout.strip():
            raw = r.stdout.strip()
            try:
                parsed = json.loads(raw)
                if isinstance(parsed, dict):
                    parsed = [parsed]
                if isinstance(parsed, list) and parsed:
                    data = parsed
                    break
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
                if items:
                    data = items
                    break
        print(f"[{tag}] describe-all attempt {attempt + 1} returned nothing, retrying...", flush=True)
        time.sleep(2)
    try:
        with open(f"tree-{tag}.json", "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print("could not write tree json:", e, flush=True)
    print(f"[{tag}] parsed {len(data)} accessibility elements", flush=True)
    return data if isinstance(data, list) else []


def elem_label(el):
    if not isinstance(el, dict):
        return ""
    for key in ("AXLabel", "label", "title", "AXValue", "value", "help_text",
                "role_description", "placeholder_value"):
        v = el.get(key)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return ""


def elem_lines(el):
    label = elem_label(el)
    return [l.strip() for l in label.split("\n") if l.strip()]


def elem_frame(el):
    frame = el.get("frame") if isinstance(el, dict) else None
    if not isinstance(frame, dict):
        frame = el.get("AXFrame") if isinstance(el, dict) else None
        if isinstance(frame, str):
            nums = re.findall(r"[-\d.]+", frame)
            if len(nums) >= 4:
                x, y, w, h = map(float, nums[:4])
                return x, y, w, h
        return None
    try:
        return (float(frame.get("x", 0)), float(frame.get("y", 0)),
                float(frame.get("width", 0)), float(frame.get("height", 0)))
    except Exception:
        return None


def tap(x, y):
    run(["idb", "ui", "tap", str(x), str(y), "--udid", UDID])


def type_text(text):
    run(["idb", "ui", "text", text, "--udid", UDID])


def find_best_match(elements, keywords):
    """Return (element, lines, how) for the best match of `keywords`
    against `elements`. Prefers an element whose FIRST label line exactly
    equals (or starts with) a keyword -- this avoids e.g. "мастер" matching
    "Поиск мастеров" inside an unrelated card -- before falling back to a
    substring search anywhere in the label."""
    low_kws = [k.lower() for k in keywords]

    for el in elements:
        lines = elem_lines(el)
        if not lines:
            continue
        first = lines[0].lower()
        for kw in low_kws:
            if first == kw or first.startswith(kw):
                return el, lines, f"first-line:{kw}"

    for el in elements:
        lines = elem_lines(el)
        for line in lines:
            low = line.lower()
            for kw in low_kws:
                if low == kw:
                    return el, lines, f"line-exact:{kw}"

    for el in elements:
        text = elem_label(el).lower()
        for kw in low_kws:
            if kw in text:
                return el, elem_lines(el), f"substring:{kw}"

    return None, None, None


def tap_best_match(elements, keywords, tag):
    el, lines, how = find_best_match(elements, keywords)
    if el is None:
        print(f"[{tag}] no match for {keywords}", flush=True)
        return False
    frame = elem_frame(el)
    if not frame:
        print(f"[{tag}] matched ({how}) lines={lines} but no usable frame", flush=True)
        return False
    fx, fy, fw, fh = frame
    x = fx + fw / 2
    y = fy + fh / 2
    # If this looks like a merged "card" element (several stacked lines
    # ending in an action word), aim near the bottom where that button
    # actually renders instead of the card's geometric center.
    if lines and len(lines) >= 3 and lines[-1].lower() in ACTION_WORDS:
        y = fy + fh * 0.90
        print(f"[{tag}] matched ({how}) lines={lines} -> card heuristic, tapping near bottom", flush=True)
    else:
        print(f"[{tag}] matched ({how}) lines={lines} -> tapping center", flush=True)
    print(f"[{tag}] tapping at ({x:.1f}, {y:.1f})", flush=True)
    tap(x, y)
    return True


def step(name):
    print(f"\n=== STEP: {name} ===", flush=True)


def main():
    step("initial state")
    time.sleep(3)
    screenshot("10-launch.png")
    els = describe_all("00-launch")

    step("select master role (Я мастер card -> Войти)")
    tap_best_match(els, ["я мастер"], "role-select")
    time.sleep(2)
    screenshot("11-after-role-tap.png")
    els = describe_all("01-after-role")

    step("find login / register entry point (in case role tap only expanded a card)")
    tap_best_match(els, ["войти", "регистр", "продолж", "начать"], "login-entry")
    time.sleep(2)
    screenshot("12-after-login-entry.png")
    els = describe_all("02-after-login-entry")

    step("enter phone number")
    tap_best_match(els, ["телефон", "номер", "phone"], "phone-field")
    time.sleep(1)
    type_text("989003100")
    time.sleep(1)
    screenshot("13-after-phone.png")
    els = describe_all("03-after-phone")

    step("submit phone / request code")
    tap_best_match(els, ["войти", "получить", "далее", "продолж", "отправ"], "phone-submit")
    time.sleep(3)
    screenshot("14-after-phone-submit.png")
    els = describe_all("04-after-phone-submit")

    step("enter confirmation code")
    tap_best_match(els, ["код", "code"], "code-field")
    time.sleep(1)
    type_text("umRJO.1711")
    time.sleep(1)
    screenshot("15-after-code.png")
    els = describe_all("05-after-code")

    step("confirm code")
    tap_best_match(els, ["подтверд", "войти", "далее", "готово"], "code-submit")
    time.sleep(4)
    screenshot("16-after-code-submit.png")
    els = describe_all("06-after-code-submit")

    step("wait for home screen to settle")
    time.sleep(4)
    screenshot("20-home-glavnaya.png")
    els = describe_all("07-home")

    step("find and tap catalog tab")
    tap_best_match(els, ["каталог", "catalog"], "catalog-tab")
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
