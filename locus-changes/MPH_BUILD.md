# Locus 1.0.5 native speed experiment

This modification adds adjustable 0.5–100 mph, elapsed-time route and joystick playback, and a live Movement check. The default Coordinates engine uses idevice DVT and changes latitude and longitude only.

The optional Native speed helper engine sends a full CLLocation reading with speed, course, timestamp, and accuracy through a separately installed and running XCTest helper. The helper uses pinned Appium/WebDriverAgent source, exposes location-only HTTP routes on loopback, and disables screenshot streaming. Core Motion automotive activity is not simulated.

## Setup

Extract the native speed kit on Windows. Sideload both IPAs with Sideloadly, enable Developer Mode, and trust your developer. Install Python 3.12 or newer, connect and unlock the phone over USB, and run `Start-Native-Speed.cmd`. Keep the window and USB connection open. The launcher discovers the helper identifier, prepares the developer image, and starts its test service.

Stop any existing spoof in Locus. In Settings choose **Native speed helper (experimental)** and check that it is Ready. Start a road route at 30 mph and open **Movement check**. **Speed sent to helper** is the request; **iOS reported speed** is what the phone delivered. These readings and permissions belong to Locus separately from Life360.

Stop spoofing in Locus before closing the launcher. If an interrupted helper leaves a simulated fix active and Stop cannot reach it, restart the phone. For Coordinates mode use LocalDevVPN's Device IP, usually 10.7.0.1. Its local interface is normally 10.7.1.1; the interface check now recognizes this address.

## Validation and limitations

GitHub Actions run 37727953794 passed both native iPhone builds, playback and native payload/course/tunnel checks, and Windows launcher syntax on October 8, 2026. Downloaded packages passed ZIP integrity and ARM64/bundle checks. The helper contains the complete native-speed CLLocation initializer and loopback location API.

Installation, Windows execution, physical-phone field forwarding, and Life360 driving detection remain unverified. Neither engine guarantees a car icon. The kit does not simulate Core Motion, remove Apple's simulated-location flag, or modify Life360.

## Sources and licenses

Locus: https://github.com/ChrisMack32/Locus at 83c8fb324983728e8f44759cfd834dc637ee38b5 (MIT).
Helper: https://github.com/appium/WebDriverAgent at 2e98ac0ad4dbc99ab7c8bb01b7216fde252afb54 (BSD).
Original licenses are retained in the respective app packages.
