"""
calibrate.py — SmartPark Camera Processor

Interactive tool for defining parking spot ROIs (Regions of Interest)
on the webcam feed and verifying detection accuracy before deployment.

Usage:
    python calibrate.py

Calibration mode controls:
    Left-click x2  — define a spot (top-left then bottom-right corner)
    t              — switch to test mode after defining spots
    q              — quit without saving

Test mode controls:
    +/-  — adjust pixel sensitivity (lower threshold = more sensitive)
    c    — go back to calibration mode and redefine all spots from scratch
    s    — save config and quit
    q    — quit without saving
"""

import cv2
import json
import os
import sys
import numpy as np

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "spots_config.json")

DEFAULT_CONFIG = {
    "camera_index": 0,
    "resolution": [1920, 1080],
    "pixel_threshold": 30,
    "area_threshold": 0.25,
    "spots": {},
}


def load_config():
    """
    Load existing spots_config.json if it exists.

    Returns:
        Tuple of (config dict, already_configured bool).
        If the file exists, already_configured is True and calibration is skipped.
    """
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            config = json.load(f)
        print(f"[calibrate] Loaded existing config from {CONFIG_PATH}")
        return config, True
    return dict(DEFAULT_CONFIG), False


def save_config(config):
    """Persist the configuration dict to spots_config.json."""
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=2)
    print(f"[calibrate] Config saved to {CONFIG_PATH}")


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
        resolution: [width, height] list.

    Returns:
        cv2.VideoCapture object (already opened).

    Raises:
        RuntimeError: If the camera cannot be opened.
    """
    backend = cv2.CAP_AVFOUNDATION if sys.platform == "darwin" else cv2.CAP_ANY
    print(f"[calibrate] Opening camera index {camera_index} "
          f"(backend: {'AVFoundation' if backend == cv2.CAP_AVFOUNDATION else 'default'})")
    cap = cv2.VideoCapture(camera_index, backend)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open camera at index {camera_index}")
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, resolution[0])
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, resolution[1])
    return cap


def is_spot_occupied(frame_gray, ref_gray, spot, pixel_threshold, area_threshold):
    """
    Determine if a parking spot is occupied using frame difference.

    Extracts the ROI from both frames, applies Gaussian blur, computes
    absolute pixel difference, and checks whether the fraction of changed
    pixels exceeds area_threshold.

    Args:
        frame_gray: Current live frame converted to grayscale.
        ref_gray:   Reference (empty lot) frame in grayscale.
        spot:       Dict with keys x1, y1, x2, y2.
        pixel_threshold: Minimum per-pixel diff (0-255) to count as changed.
        area_threshold:  Fraction of ROI pixels that must change to flag occupied.

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


def draw_spots(frame, spots, color=(0, 200, 0)):
    """
    Draw labeled rectangles for all defined spots onto the frame.

    Args:
        frame:  BGR frame to annotate (drawn in-place).
        spots:  Dict mapping spot name → {x1, y1, x2, y2}.
        color:  BGR tuple for the rectangle and label color.
    """
    for name, coords in spots.items():
        x1, y1, x2, y2 = coords["x1"], coords["y1"], coords["x2"], coords["y2"]
        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
        cv2.putText(frame, name, (x1, y1 - 5),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)


def run_calibration_mode(cap, config):
    """
    Interactive spot-definition phase.

    The user clicks two points per spot (top-left then bottom-right).
    After each pair of clicks the tool pauses for the user to type the
    spot name in the terminal.  Defined spots are drawn in green.

    Args:
        cap:    Open cv2.VideoCapture.
        config: Current config dict (spots key is updated in-place).

    Returns:
        Tuple of (spots dict, proceed bool).
        proceed is False when the user quits with 'q'.
    """
    spots = dict(config.get("spots", {}))
    clicks = []
    window_name = "SmartPark Calibrate — Define Spots"

    def mouse_callback(event, x, y, flags, param):
        if event == cv2.EVENT_LBUTTONDOWN:
            clicks.append((x, y))

    cv2.namedWindow(window_name)
    cv2.setMouseCallback(window_name, mouse_callback)

    print("\n[calibrate] CALIBRATION MODE")
    print("  Click the TOP-LEFT corner of a spot, then the BOTTOM-RIGHT corner.")
    print("  Type the spot name in the terminal when prompted (e.g. A1, B2).")
    print("  Press 't' to enter test mode when all spots are defined.")
    print("  Press 'q' to quit without saving.\n")

    while True:
        ret, frame = cap.read()
        if not ret:
            print("[calibrate] Failed to read from camera.")
            break

        display = frame.copy()

        # Draw all confirmed spots in green
        draw_spots(display, spots, color=(0, 200, 0))

        if len(clicks) == 0:
            cv2.putText(display, "Click TOP-LEFT corner of next spot",
                        (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        elif len(clicks) == 1:
            cv2.circle(display, clicks[0], 5, (255, 80, 0), -1)
            cv2.putText(display, "Click BOTTOM-RIGHT corner",
                        (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

        # Two clicks ready — pause and ask for a name
        if len(clicks) >= 2:
            p1, p2 = clicks[0], clicks[1]
            x1 = min(p1[0], p2[0])
            y1 = min(p1[1], p2[1])
            x2 = max(p1[0], p2[0])
            y2 = max(p1[1], p2[1])
            cv2.rectangle(display, (x1, y1), (x2, y2), (0, 165, 255), 2)
            cv2.imshow(window_name, display)
            cv2.waitKey(1)  # Flush the frame before blocking on input()

            name = input(f"  Spot name for ({x1},{y1})→({x2},{y2}): ").strip().upper()
            if name:
                spots[name] = {"x1": x1, "y1": y1, "x2": x2, "y2": y2}
                print(f"  [+] '{name}' saved. Total spots: {len(spots)}")
            else:
                print("  [!] No name entered — rectangle discarded.")
            clicks.clear()
            continue

        cv2.imshow(window_name, display)
        key = cv2.waitKey(1) & 0xFF

        if key == ord("t"):
            print(f"\n[calibrate] Entering test mode with {len(spots)} spot(s)...")
            break
        elif key == ord("q"):
            print("[calibrate] Quit without saving.")
            cv2.destroyAllWindows()
            return spots, False

    cv2.destroyAllWindows()
    return spots, True


def run_test_mode(cap, config):
    """
    Live detection test phase.

    Captures a fresh reference frame (empty lot), then continuously
    overlays green (empty) or red (occupied) rectangles on each spot.
    The user can tune sensitivity before saving.

    Args:
        cap:    Open cv2.VideoCapture.
        config: Config dict — pixel_threshold and area_threshold are
                read and may be updated before returning.

    Returns:
        True if the user pressed 's' to save, False if they pressed 'q',
        or the string "recalibrate" if the user pressed 'c'.
    """
    spots = config["spots"]
    pixel_threshold = config["pixel_threshold"]
    area_threshold = config["area_threshold"]
    window_name = "SmartPark Calibrate — Test Mode"

    if not spots:
        print("[calibrate] No spots to test. Define at least one spot first.")
        return False

    print("\n[calibrate] TEST MODE — capturing reference frame.")
    print("  Make sure ALL parking spots are EMPTY before continuing.")
    input("  Press Enter when the lot is clear...")

    ret, ref_frame = cap.read()
    if not ret:
        print("[calibrate] Failed to capture reference frame.")
        return False

    ref_gray = cv2.cvtColor(ref_frame, cv2.COLOR_BGR2GRAY)
    print(f"[calibrate] Reference captured.")
    print(f"  pixel_threshold={pixel_threshold}  area_threshold={area_threshold:.0%}")
    print("  Controls: [+/-] sensitivity  [c] recalibrate  [s] save+quit  [q] quit\n")

    while True:
        ret, frame = cap.read()
        if not ret:
            print("[calibrate] Failed to read frame.")
            break

        frame_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        display = frame.copy()

        for name, coords in spots.items():
            occupied = is_spot_occupied(frame_gray, ref_gray, coords,
                                        pixel_threshold, area_threshold)
            color = (0, 0, 220) if occupied else (0, 220, 0)
            x1, y1, x2, y2 = coords["x1"], coords["y1"], coords["x2"], coords["y2"]
            cv2.rectangle(display, (x1, y1), (x2, y2), color, 2)
            label = f"{name}: {'OCCUPIED' if occupied else 'EMPTY'}"
            cv2.putText(display, label, (x1, y1 - 5),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)

        hud = (f"px_thresh={pixel_threshold}  area={area_threshold:.0%}  "
               f"[+/-] sensitivity  [c] recalibrate  [s] save  [q] quit")
        cv2.putText(display, hud, (10, display.shape[0] - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 255, 255), 1)

        cv2.imshow(window_name, display)
        key = cv2.waitKey(100) & 0xFF

        if key == ord("+") or key == ord("="):
            pixel_threshold = max(5, pixel_threshold - 5)
            config["pixel_threshold"] = pixel_threshold
            print(f"[calibrate] pixel_threshold → {pixel_threshold} (more sensitive)")
        elif key == ord("-"):
            pixel_threshold = min(100, pixel_threshold + 5)
            config["pixel_threshold"] = pixel_threshold
            print(f"[calibrate] pixel_threshold → {pixel_threshold} (less sensitive)")
        elif key == ord("c"):
            print("[calibrate] Returning to calibration mode — all spots will be redefined.")
            cv2.destroyAllWindows()
            return "recalibrate"
        elif key == ord("s"):
            print("[calibrate] Saving config and quitting.")
            cv2.destroyAllWindows()
            return True
        elif key == ord("q"):
            print("[calibrate] Quit without saving.")
            cv2.destroyAllWindows()
            return False

    cv2.destroyAllWindows()
    return False


def main():
    """
    Entry point for the calibration tool.

    If spots_config.json already exists the tool jumps straight to test
    mode so the user can verify or retune without redefining every spot.
    Pressing 'c' in test mode drops back into calibration mode and clears
    all previously defined spots, so the user never needs to manually
    delete spots_config.json to start over.
    """
    config, already_configured = load_config()

    cap = open_camera(config["camera_index"], config["resolution"])

    try:
        # Start in test mode when a config already exists; otherwise calibrate.
        go_to_test = already_configured

        while True:
            if go_to_test:
                if already_configured:
                    print("[calibrate] Existing config found — skipping to test mode.")
                result = run_test_mode(cap, config)
                if result == "recalibrate":
                    # Clear all spots and fall through to calibration mode.
                    config["spots"] = {}
                    go_to_test = False
                    already_configured = False  # suppress "existing config" banner
                    continue
                should_save = result
            else:
                spots, proceed = run_calibration_mode(cap, config)
                config["spots"] = spots

                if not proceed:
                    return

                go_to_test = True
                continue

            if should_save:
                save_config(config)
            return

    finally:
        cap.release()
        print("[calibrate] Camera released.")


if __name__ == "__main__":
    main()