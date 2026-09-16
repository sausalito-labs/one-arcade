#!/usr/bin/env python3
"""Headless browser test for the One Arcade HTML5 demo.

Loads the demo page, captures console logs, and takes multiple screenshots
over time. Compares screenshots to detect whether the canvas content changes
(indicating animation).
"""
import os
import sys
import time
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

URL = sys.argv[1] if len(sys.argv) > 1 else "https://agent-box.tailadabc1.ts.net/demo/"
OUT_DIR = Path("/tmp/godot_web_test")
OUT_DIR.mkdir(exist_ok=True)

chrome_options = Options()
chrome_options.add_argument("--headless=new")
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")
chrome_options.add_argument("--enable-unsafe-swiftshader")
chrome_options.set_capability("goog:loggingPrefs", {"browser": "ALL"})

import shutil
driver_path = os.environ.get("CHROMEDRIVER") or shutil.which("chromedriver")
if not driver_path:
    print("ERROR: chromedriver not found. Set CHROMEDRIVER or add it to PATH.", file=sys.stderr)
    sys.exit(1)
service = Service(driver_path)
driver = webdriver.Chrome(service=service, options=chrome_options)

try:
    print(f"Loading {URL} ...")
    driver.get(URL)

    # Wait for the canvas to exist.
    wait = WebDriverWait(driver, 60)
    canvas = wait.until(EC.presence_of_element_located((By.ID, "canvas")))
    print("Canvas found.")

    # Wait a bit for the engine to boot and start rendering.
    time.sleep(8)

    # Capture console logs.
    logs = driver.get_log("browser")
    log_path = OUT_DIR / "console.log"
    with log_path.open("w") as f:
        for entry in logs:
            level = entry.get("level", "?")
            msg = entry.get("message", "")
            f.write(f"[{level}] {msg}\n")
    print(f"Wrote {len(logs)} console log lines to {log_path}")

    # Take multiple screenshots of the canvas.
    # First idle, then hold 'd' to run.
    screenshot_paths = []
    for i in range(5):
        path = OUT_DIR / f"canvas_{i}.png"
        canvas.screenshot(str(path))
        screenshot_paths.append(path)
        print(f"Screenshot {i}: {path} ({path.stat().st_size} bytes)")
        time.sleep(1)

    # Hold 'd' for a few seconds and capture running frames.
    from selenium.webdriver.common.action_chains import ActionChains
    ActionChains(driver).key_down('d').perform()
    for i in range(5, 10):
        path = OUT_DIR / f"canvas_{i}.png"
        canvas.screenshot(str(path))
        screenshot_paths.append(path)
        print(f"Screenshot {i}: {path} ({path.stat().st_size} bytes)")
        time.sleep(0.5)
    ActionChains(driver).key_up('d').perform()

    # Compare first and last screenshot pixel data to detect changes.
    from PIL import Image

    img0 = Image.open(screenshot_paths[0])
    imgN = Image.open(screenshot_paths[-1])
    if img0.size != imgN.size:
        print(f"SIZE_DIFFERENT: {img0.size} vs {imgN.size}")
    else:
        diff = 0
        total = img0.size[0] * img0.size[1]
        for x in range(img0.size[0]):
            for y in range(img0.size[1]):
                if img0.getpixel((x, y)) != imgN.getpixel((x, y)):
                    diff += 1
        print(f"PIXEL_DIFF: {diff}/{total} pixels changed ({100*diff/total:.2f}%)")

finally:
    driver.quit()
