#!/usr/bin/env python3
"""Browser playtest of the web build (Playwright + software WebGL).

Usage: python3 scripts/playtest.py [URL]
Boots the game, checks it gets past the Godot loader, starts a run, drives
WASD + mouse, pauses/resumes, and saves screenshots + docs/PLAYTEST.json.
State is read from window.__NEON_DRIFT__ (published by scripts/core/web_bridge.gd).
"""
import json
import os
import sys
import time

from playwright.sync_api import sync_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "https://neon-drift-aphiwe.abacusai.cloud/"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")
checks = []


def check(name, ok, detail=""):
    checks.append({"name": name, "pass": bool(ok), "detail": str(detail)})
    print(("PASS " if ok else "FAIL ") + name, detail)


def state(page):
    return page.evaluate("() => window.__NEON_DRIFT__ || null")


def wait_state(page, pred, timeout):
    end = time.time() + timeout
    s = None
    while time.time() < end:
        s = state(page)
        if s and pred(s):
            return s
        time.sleep(0.5)
    return s


with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=os.environ.get("CHROME_PATH") or None, args=["--use-gl=swiftshader", "--enable-webgl", "--ignore-gpu-blocklist", "--no-sandbox", "--autoplay-policy=no-user-gesture-required"])
    page = browser.new_page(viewport={"width": 1280, "height": 720})
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
    page.goto(URL)
    s = wait_state(page, lambda s: s["state"] == "TITLE", 180)
    check("boot", s and s["state"] == "TITLE", s)
    time.sleep(3)
    page.screenshot(path=os.path.join(DOCS, "screenshot_title.png"))

    page.mouse.move(900, 300)
    page.mouse.click(640, 400)
    s = wait_state(page, lambda s: s["state"] == "PLAYING", 20)
    check("start", s and s["state"] == "PLAYING", s)
    x0 = s["player"][0] if s and s["player"] else None
    page.keyboard.down("KeyD")
    time.sleep(2.0)
    page.keyboard.up("KeyD")
    s = state(page)
    check("move_right", x0 is not None and s["player"] and s["player"][0] > x0 + 20, f"{x0} -> {s and s['player']}")

    # Fight for a while: hold fire and sweep the aim around while strafing.
    page.mouse.down()
    end = time.time() + 40
    i = 0
    while time.time() < end:
        s = state(page)
        if not s or s["state"] != "PLAYING":
            break
        px, py = s["player"] if s["player"] else (640, 360)
        import math
        a = i * 0.7
        page.mouse.move(px + math.cos(a) * 250, py + math.sin(a) * 250)
        key = ["KeyW", "KeyA", "KeyS", "KeyD"][(i // 3) % 4]
        page.keyboard.down(key)
        time.sleep(0.4)
        page.keyboard.up(key)
        if i == 25:
            page.screenshot(path=os.path.join(DOCS, "screenshot_gameplay.png"))
        i += 1
    page.mouse.up()
    s = state(page)
    check("gameplay", s and (s["score"] > 0 or s["wave"] >= 1), s)
    if not os.path.exists(os.path.join(DOCS, "screenshot_gameplay.png")):
        page.screenshot(path=os.path.join(DOCS, "screenshot_gameplay.png"))

    if s and s["state"] == "PLAYING":
        page.keyboard.press("Escape")
        s = wait_state(page, lambda s: s["state"] == "PAUSED", 10)
        check("pause", s and s["paused"], s)
        page.screenshot(path=os.path.join(DOCS, "screenshot_pause.png"))
        page.keyboard.press("KeyP")
        s = wait_state(page, lambda s: s["state"] == "PLAYING", 10)
        check("resume", s and not s["paused"], s)
    page.keyboard.press("KeyM")
    s = wait_state(page, lambda s: s["muted"], 5)
    check("mute_toggle", s and s["muted"], s)
    page.keyboard.press("KeyM")

    real_errors = [e for e in errors if "AudioContext" not in e]
    check("no_errors", not real_errors, real_errors[:5])
    browser.close()

json.dump({"url": URL, "checks": checks}, open(os.path.join(DOCS, "PLAYTEST.json"), "w"), indent=2)
print("ALL PASSED" if all(c["pass"] for c in checks) else "SOME CHECKS FAILED")
