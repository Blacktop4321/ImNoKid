# Locus 1.0.4 playback and movement check build

This isolated branch builds Locus from upstream commit `83c8fb324983728e8f44759cfd834dc637ee38b5` with the changes in `locus-changes/`.

The GitHub Actions workflow runs speed checks, compiles the iPhone app on macOS, and uploads `Locus-MPH-unsigned.ipa`. Sign the IPA with your sideloading tool before installation.

Features: adjustable 0.5–100 mph, optional ±10% variation, live route speed changes, elapsed-time route/joystick playback, and Settings → Movement check for iOS-reported speed and motion activity. Only GPS coordinates are simulated. This build does not inject Core Motion activity or a native GPS speed field, and Life360's car icon has not been verified on a physical phone.

Upstream: https://github.com/ChrisMack32/Locus
