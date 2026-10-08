# Locus MPH IPA build

This isolated branch builds Locus from upstream commit `83c8fb324983728e8f44759cfd834dc637ee38b5` with the changes in `locus-changes/`.

The GitHub Actions workflow runs speed checks, compiles the iPhone app on macOS, and uploads `Locus-MPH-unsigned.ipa`. Sign the IPA with your sideloading tool before installation.

Features: adjustable 0.5–100 mph, optional ±10% variation, live route speed changes, and joystick speed adjustment. Only GPS movement is simulated; this does not override motion data in other apps.

Upstream: https://github.com/ChrisMack32/Locus
