"""
main.py — SmartPark Camera Processor

Continuously monitors parking spot occupancy using frame difference
detection against a reference (empty lot) frame, and reports spot
status to the SmartPark backend every CAPTURE_INTERVAL seconds.

Environment variables (loaded from .env):
    BACKEND_URL      — e.g. http://localhost:8080/api/v1
    CAMERA_API_KEY   — secret key for the X-API-Key header
    CAPTURE_INTERVAL — seconds between backend POSTs (default: 10)

Usage:
    python main.py

Runtime controls (press in the debug window):
    r    — recapture reference frame (re-baseline empty lot)
    d    — toggle debug overlay on/off
    +/-  — adjust pixel sensitivity threshold
    q    — quit
"""

import cv2
import json
import os
import sys
import time
import numpy as np
import requests
from datetime import datetime, timezone
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Configuration — loaded once at import time
# ---------------------------------------------------------------------------

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8080/api/v1")
CAMERA_API_KEY = os.getenv("CAMERA_API_KEY", "smartpark-camera-key-2026")
CAPTURE_INTERVAL = int(os.getenv("CAPTURE_INTERVAL", "10"))

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "spots_config.json")


# ---------------------------------------------------------------------------
# Setup helpers
# ---------------------------------------------------------------------------

def load_config():
    """
    Load spots_config.json produced by calibrate.py.

    Returns:
        Config dict containing camera_index, resolution, pixel_threshold,
        area_threshold, and spots.

    Raises:
        FileNotFoundError: If spots_config.json does not exist.
    """
    if not os.path.exists(CONFIG_PATH):
        raise FileNotFoundError(
            f"spots_config.json not found at {CONFIG_PATH}. "
            "Run calibrate.py first to define parking spot regions."
        )
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)


def open_camera(camera_index, resolution):
    """
    Open the webcam at the given index and apply the target resolution.

    On macOS, cv2.VideoCapture(index) without an explicit backend can
    pick a non-AVFoundation backend that enumerates cameras differently,
    causing index 1 to resolve to the built-in camera instead of the
    external one.  Passing cv2.CAP_AVFOUNDATION explicitly forces the
    correct device ordering (0 = external Rapoo, 1 = built-in FaceTime).

    Args:
        camera_index: Integer index (0 = external Rapoo, 1 = built-in FaceTime under AVFoundation).
        resolution:   [width, height] list from config.

    Returns:
        Opened cv2.VideoCapture object.

    Raises:
        RuntimeError: If the camera cannot be opened.
    """
    backend = cv2.CAP_AVFOUNDATION if sys.platform == "darwin" else cv2.CAP_ANY
    print(f"[main] Opening camera index {camera_index} "
          f"(backend: {'AVFoundation' if backend == cv2.CAP_AVFOUNDATION else 'default'})")
    cap = cv2.VideoCapture(camera_index, backend)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open camera at index {camera_index}. "
                           "Check that the camera is connected and not in use.")
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, resolution[0])
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, resolution[1])
    return cap


def capture_reference_frame(cap):
    """
    Prompt the operator to clear the lot, then capture one frame as the
    empty-lot baseline for all subsequent difference comparisons.

    Args:
        cap: Open cv2.VideoCapture.

    Returns:
        BGR reference frame (numpy array).

    Raises:
        RuntimeError: If the camera fails to return a frame.
    """
    print("\n[main] REFERENCE FRAME CAPTURE")
    print("  All parking spots must be EMPTY before continuing.")
    input("  Press Enter when the lot is clear...")

    ret, frame = cap.read()
    if not ret:
        raise RuntimeError("Failed to capture reference frame from camera.")

    print("[main] Reference frame captured.\n")
    return frame


# ---------------------------------------------------------------------------
# Detection
# ---------------------------------------------------------------------------

def is_spot_occupied(frame_gray, ref_gray, spot, pixel_threshold, area_threshold):
    """
    Determine whether a parking spot ROI is occupied via frame difference.

    Both ROI crops are Gaussian-blurred before computing the absolute
    per-pixel difference so that minor lighting noise is ignored.

    Args:
        frame_gray:      Current live frame in grayscale.
        ref_gray:        Reference (empty lot) frame in grayscale.
        spot:            Dict with x1, y1, x2, y2 pixel coordinates.
        pixel_threshold: Minimum per-pixel diff (0-255) to count as changed.
        area_threshold:  Fraction of ROI pixels that must be changed to
                         classify the spot as occupied.

    Returns:
        True if the spot appears occupied, False otherwise.
    """
    x1, y1, x2, y2 = spot["x1"], spot["y1"], spot["x2"], spot["y2"]
    roi_live = frame_gray[y1:y2, x1:x2]
    roi_ref = ref_gray[y1:y2, x1:x2]

    if roi_live.size == 0 or roi_ref.size == 0:
        return False

    roi_live_blur = cv2.GaussianBlur(roi_live, (5, 5), 0)
    roi_ref_blur = cv2.GaussianBlur(roi_ref, (5, 5), 0)

    diff = cv2.absdiff(roi_live_blur, roi_ref_blur)
    changed_pixels = np.sum(diff > pixel_threshold)
    ratio = changed_pixels / diff.size

    return ratio > area_threshold


# ---------------------------------------------------------------------------
# Backend communication
# ---------------------------------------------------------------------------

def send_spot_status(spots_data):
    """
    POST current spot occupancy to the SmartPark backend.

    All exceptions are caught and logged; the processor never crashes on
    a network failure — it simply retries on the next interval.

    Args:
        spots_data: List of dicts, each with keys:
                    - spot_label (str)  e.g. "A1"
                    - is_occupied (bool)
    """
    url = f"{BACKEND_URL}/camera/spot-status"
    headers = {
        "X-API-Key": CAMERA_API_KEY,
        "Content-Type": "application/json",
    }
    payload = {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "spots": spots_data,
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=5)
        response.raise_for_status()
        print(f"[main] Sent {len(spots_data)} spots → HTTP {response.status_code}")
    except requests.exceptions.ConnectionError:
        print(f"[main] Backend unreachable ({url}) — will retry next cycle.")
    except requests.exceptions.Timeout:
        print("[main] Request timed out — will retry next cycle.")
    except requests.exceptions.HTTPError as e:
        print(f"[main] Backend error: {e}")
    except Exception as e:
        print(f"[main] Unexpected error sending status: {e}")


# ---------------------------------------------------------------------------
# Debug overlay
# ---------------------------------------------------------------------------

def draw_debug_overlay(frame, spots, occupancy, pixel_threshold, area_threshold):
    """
    Annotate each spot with a colored rectangle and status label.

    Green rectangle → spot is free.
    Red rectangle   → spot is occupied.

    Args:
        frame:           BGR frame to draw on (modified in-place).
        spots:           Dict of spot name → coordinate dict.
        occupancy:       Dict of spot name → bool (True = occupied).
        pixel_threshold: Shown in the HUD line at the bottom.
        area_threshold:  Shown in the HUD line at the bottom.
    """
    for name, coords in spots.items():
        occupied = occupancy.get(name, False)
        color = (0, 0, 220) if occupied else (0, 220, 0)
        x1, y1, x2, y2 = coords["x1"], coords["y1"], coords["x2"], coords["y2"]
        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
        label = f"{name}: {'OCCUPIED' if occupied else 'FREE'}"
        cv2.putText(frame, label, (x1, y1 - 5),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)

    hud = (f"px_thresh={pixel_threshold}  area={area_threshold:.0%}  "
           f"[r] recal  [d] hide  [+/-] sensitivity  [q] quit")
    cv2.putText(frame, hud, (10, frame.shape[0] - 10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 255, 255), 1)


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def main():
    """
    Entry point for the camera processor.

    Loads configuration, opens the camera, captures a reference frame,
    then loops indefinitely: detect occupancy → POST to backend → display.
    """
    # --- Load config ---
    config = load_config()
    camera_index = config.get("camera_index", 0)
    resolution = config.get("resolution", [1920, 1080])
    pixel_threshold = config.get("pixel_threshold", 30)
    area_threshold = config.get("area_threshold", 0.25)
    spots = config.get("spots", {})

    if not spots:
        print("[main] No spots defined in spots_config.json. Run calibrate.py first.")
        return

    print(f"[main] {len(spots)} spots loaded: {', '.join(spots.keys())}")
    print(f"[main] Backend  : {BACKEND_URL}")
    print(f"[main] Interval : {CAPTURE_INTERVAL}s")

    # --- Open camera ---
    cap = open_camera(camera_index, resolution)

    try:
        # --- Capture reference (empty lot) frame ---
        ref_frame = capture_reference_frame(cap)
        ref_gray = cv2.cvtColor(ref_frame, cv2.COLOR_BGR2GRAY)

        show_debug = True
        last_send_time = 0.0
        occupancy = {name: False for name in spots}
        window_name = "SmartPark Camera Processor"

        print("[main] Running — press 'q' in the debug window to quit.\n")

        while True:
            ret, frame = cap.read()
            if not ret:
                print("[main] Failed to read frame — retrying...")
                time.sleep(1)
                continue

            frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            # --- Detect occupancy for every spot ---
            for name, coords in spots.items():
                occupancy[name] = is_spot_occupied(
                    frame_gray, ref_gray, coords, pixel_threshold, area_threshold
                )

            # --- POST to backend on interval ---
            now = time.time()
            if now - last_send_time >= CAPTURE_INTERVAL:
                spots_data = [
                    {"spot_label": name, "is_occupied": bool(occupied)}
                    for name, occupied in occupancy.items()
                ]
                send_spot_status(spots_data)
                last_send_time = now

            # --- Debug overlay ---
            if show_debug:
                display = frame.copy()
                draw_debug_overlay(display, spots, occupancy, pixel_threshold, area_threshold)
                cv2.imshow(window_name, display)

            # --- Keyboard input (non-blocking 30 ms) ---
            key = cv2.waitKey(30) & 0xFF

            if key == ord("q"):
                print("[main] Quitting.")
                break

            elif key == ord("r"):
                print("[main] Recapturing reference frame...")
                ref_frame = capture_reference_frame(cap)
                ref_gray = cv2.cvtColor(ref_frame, cv2.COLOR_BGR2GRAY)

            elif key == ord("d"):
                show_debug = not show_debug
                if not show_debug:
                    cv2.destroyWindow(window_name)
                state = "enabled" if show_debug else "disabled"
                print(f"[main] Debug overlay {state}.")

            elif key == ord("+") or key == ord("="):
                pixel_threshold = max(5, pixel_threshold - 5)
                print(f"[main] pixel_threshold → {pixel_threshold} (more sensitive)")

            elif key == ord("-"):
                pixel_threshold = min(100, pixel_threshold + 5)
                print(f"[main] pixel_threshold → {pixel_threshold} (less sensitive)")

    finally:
        cap.release()
        cv2.destroyAllWindows()
        print("[main] Camera released.")


if __name__ == "__main__":
    main()
