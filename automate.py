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
    "стать мастером", "стать пользователем",
)

PHONE_KEYWORDS = ["телефон", "номер", "phone"]
CODE_KEYWORDS = ["промо", "реферал", "инвайт", "пригла", "код мастера",
                  "referral", "invite", "partner"]


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
    # idb's CLI parser rejects float-formatted coordinates ("220.0") with
    # "ui tap expects 'x y' coordinates or a single marker string" -- it
    # wants plain integers. This was silently failing every single tap in
    # the whole flow.
    run(["idb", "ui", "tap", str(int(round(x))), str(int(round(y))), "--udid", UDID])


def type_text(text):
    run(["idb", "ui", "text", text, "--udid", UDID])


def is_textfield(el):
    if not isinstance(el, dict):
        return False
    role = (el.get("role") or "") + " " + (el.get("type") or "")
    return "TextField" in role


def find_textfield_near_label(elements, label_keywords):
    """The phone/code inputs on this screen are split into two separate
    accessibility elements: a plain AXStaticText label ("Номер телефона",
    "Код входа") and, right below it, a real AXTextField that is the
    actually-editable/tappable node. Matching on the label text alone (as
    tap_best_match does) taps the inert label, not the field -- the tap
    lands outside the field's frame, nothing gets focused, and the
    subsequent idb ui text call types into nothing. Find the label first,
    then pick the nearest AXTextField at or below it."""
    label_el, label_lines, how = find_best_match(elements, label_keywords)
    if label_el is None:
        return None, None, None
    label_frame = elem_frame(label_el)
    if not label_frame:
        return None, None, None
    lx, ly, lw, lh = label_frame
    best = None
    for el in elements:
        if not is_textfield(el):
            continue
        frame = elem_frame(el)
        if not frame:
            continue
        fx, fy, fw, fh = frame
        if fy < ly - 5:
            continue
        delta = fy - ly
        if best is None or delta < best[0]:
            best = (delta, frame)
    if best is None:
        return None, None, label_lines
    return best[1], how, label_lines


def tap_and_type_field(elements, label_keywords, text, tag):
    frame, how, label_lines = find_textfield_near_label(elements, label_keywords)
    if frame is None:
        print(f"[{tag}] no textfield found near label {label_keywords} (label lines={label_lines}), "
              f"falling back to tapping the matched element directly", flush=True)
        tap_best_match(elements, label_keywords, tag)
    else:
        fx, fy, fw, fh = frame
        x = fx + fw / 2
        y = fy + fh / 2
        print(f"[{tag}] label matched ({how}) lines={label_lines} -> tapping textfield at ({x:.1f}, {y:.1f})",
              flush=True)
        tap(x, y)
    time.sleep(1)
    if text:
        type_text(text)


def nearest_label_for_field(elements, field_frame):
    """Given a textfield's frame, find the nearest non-textfield element
    positioned at or above it (by y) and return its joined label lines --
    this is how we discover what an unlabeled-by-us AXTextField actually
    represents on an unfamiliar screen (e.g. a registration form whose
    exact fields we haven't seen before)."""
    fx, fy, fw, fh = field_frame
    best = None
    for el in elements:
        if is_textfield(el):
            continue
        lines = elem_lines(el)
        if not lines:
            continue
        frame = elem_frame(el)
        if not frame:
            continue
        lx, ly, lw, lh = frame
        if ly > fy + 5:
            continue
        delta = fy - ly
        if delta < 0:
            continue
        if best is None or delta < best[0]:
            best = (delta, " / ".join(lines))
    return best[1] if best else "(no label found)"


def discover_fields(elements, tag):
    """List every AXTextField on the current screen along with its nearest
    label and current value, so unfamiliar screens (like a registration
    form we've never automated before) are fully logged even if our
    keyword-based auto-fill doesn't recognize every field."""
    results = []
    for el in elements:
        if not is_textfield(el):
            continue
        frame = elem_frame(el)
        label = nearest_label_for_field(elements, frame) if frame else "(no frame)"
        value = el.get("AXValue")
        ax_label = el.get("AXLabel")
        print(f"[{tag}] FIELD label={label!r} AXValue={value!r} AXLabel={ax_label!r} frame={frame}", flush=True)
        results.append({"label": label, "frame": frame, "el": el})
    if not results:
        print(f"[{tag}] no AXTextField elements found on this screen", flush=True)
    return results


def auto_fill_fields(elements, tag):
    """Fill in whatever fields we can confidently recognize (phone number,
    a promo/referral/invite-style code). Anything we don't recognize is
    logged but deliberately left untouched rather than guessed at."""
    fields = discover_fields(elements, tag)
    for f in fields:
        label_low = f["label"].lower()
        frame = f["frame"]
        if not frame:
            continue
        fx, fy, fw, fh = frame
        x, y = fx + fw / 2, fy + fh / 2
        if any(k in label_low for k in PHONE_KEYWORDS):
            print(f"[{tag}] filling PHONE field (label={f['label']!r})", flush=True)
            tap(x, y)
            time.sleep(1)
            type_text("989003100")
            time.sleep(1)
        elif any(k in label_low for k in CODE_KEYWORDS):
            print(f"[{tag}] filling CODE field (label={f['label']!r})", flush=True)
            tap(x, y)
            time.sleep(1)
            type_text("umRJO.1711")
            time.sleep(1)
        else:
            print(f"[{tag}] SKIPPING unrecognized field (label={f['label']!r}) -- not auto-filling", flush=True)


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


def has_match(elements, keywords):
    el, _, _ = find_best_match(elements, keywords)
    return el is not None


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


def print_textfield_values(elements, tag):
    for el in elements:
        if is_textfield(el):
            print(f"[{tag}] textfield AXValue={el.get('AXValue')!r} AXLabel={el.get('AXLabel')!r}",
                  flush=True)


def step(name):
    print(f"\n=== STEP: {name} ===", flush=True)


def main():
    step("initial state")
    time.sleep(3)
    screenshot("10-launch.png")
    els = describe_all("00-launch")

    # Run #5 (registration discovery via "Я мастер") showed the master
    # flow only ever offers two screens: the launch screen with two role
    # cards ("Я клиент" / "Я мастер"), and after "Я мастер" a "Вход для
    # мастера" screen with exactly two actions ("Войти в кабинет" /
    # "Стать мастером") -- no "Стать пользователем" text exists anywhere
    # in that path. The user confirmed: they meant tap "Я клиент" (the
    # OTHER role card) right at the start, not something nested inside
    # the master flow.
    step("select CLIENT role (Я клиент card, per user clarification -- NOT Я мастер)")
    tap_best_match(els, ["я клиент"], "role-select")
    time.sleep(2)
    screenshot("11-after-role-tap.png")
    els = describe_all("01-after-role")

    step("tap Стать пользователем / registration entry on the client screen")
    if has_match(els, ["стать пользователем", "пользователем", "зарегистр"]):
        tap_best_match(els, ["стать пользователем", "пользователем", "зарегистр"], "register-entry")
    elif has_match(els, ["войти", "продолж", "начать"]):
        print("[register-entry] no explicit 'Стать пользователем'/'зарегистрироваться' text found, "
              "but a generic entry button exists -- tapping that instead", flush=True)
        tap_best_match(els, ["войти", "продолж", "начать"], "register-entry")
    else:
        print("[register-entry] no obvious entry point found on this screen, "
              "logging full element list for inspection", flush=True)
        for el in els:
            lines = elem_lines(el)
            if lines:
                print(f"[register-entry] candidate element lines={lines} frame={elem_frame(el)}", flush=True)
    time.sleep(2)
    screenshot("12-after-register-tap.png")
    els = describe_all("02-after-register-tap")

    step("discover + auto-fill registration fields (pass 1)")
    auto_fill_fields(els, "reg-fields-1")
    time.sleep(1)
    screenshot("13-after-fill-1.png")
    els = describe_all("03-after-fill-1")

    step("attempt to advance registration form (submit 1)")
    tap_best_match(els, ["далее", "продолж", "зарегистрир", "готово", "отправ"], "register-submit-1")
    time.sleep(3)
    screenshot("14-after-submit-1.png")
    els = describe_all("04-after-submit-1")

    step("discover + auto-fill registration fields (pass 2, new fields may have appeared)")
    auto_fill_fields(els, "reg-fields-2")
    time.sleep(1)
    screenshot("15-after-fill-2.png")
    els = describe_all("05-after-fill-2")

    step("attempt to advance registration form (submit 2)")
    tap_best_match(els, ["далее", "продолж", "зарегистрир", "готово", "отправ", "подтверд"], "register-submit-2")
    time.sleep(3)
    screenshot("16-after-submit-2.png")
    els = describe_all("06-after-submit-2")

    step("discover + auto-fill registration fields (pass 3, in case of one more step)")
    auto_fill_fields(els, "reg-fields-3")
    time.sleep(1)
    screenshot("17-after-fill-3.png")
    els = describe_all("07-after-fill-3")

    step("attempt to advance registration form (submit 3)")
    tap_best_match(els, ["далее", "продолж", "зарегистрир", "готово", "отправ", "подтверд"], "register-submit-3")
    time.sleep(3)
    screenshot("18-after-submit-3.png")
    els = describe_all("08-after-submit-3")

    step("wait to see whatever screen we've landed on")
    time.sleep(4)
    screenshot("20-post-registration.png")
    els = describe_all("09-post-registration")

    step("best-effort: try catalog tab if it's visible (harmless no-op otherwise)")
    tap_best_match(els, ["каталог", "catalog"], "catalog-tab-attempt")
    time.sleep(3)
    screenshot("21-catalog-attempt.png")
    describe_all("10-catalog-attempt")

    step("done")
    screenshot("30-final-state.png")
    print("automate.py finished (registration discovery run) -- inspect tree JSON + screenshots for next steps", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print("FATAL ERROR in automate.py:", e, flush=True)
        try:
            screenshot("99-error-state.png")
        except Exception:
            pass
