# Locus MPH modification

This package changes Locus 1.0.2 to add a 0.5–100 mph slider and fine adjustment
buttons on the map and Routes screen. Changing travel mode restores its preset;
Reset also restores it. Speed variation is optional and off by default.
Route speed changes apply during playback, and the full joystick uses the same
target speed. A partial joystick position produces a lower speed.

Only GPS coordinate movement is simulated. This modification does not override
Core Motion, guarantee Life360's driving icon, or force the speed another app
reports. Device latency and location update behavior can affect measured speed.

## Build from Windows using GitHub

1. Sign into GitHub and fork https://github.com/ChrisMack32/Locus.
2. Unzip `Locus_MPH_Changes.zip`. The archive contains changed and new files,
   not the complete original app. In your fork, use **Add file → Upload files**
   to upload the contents while preserving their folders, including `.github`.
   These files belong at the repository root, not inside an extra wrapper folder.
3. Commit the upload to the fork's default branch. Do not upload the ZIP itself.
4. Open **Actions**. If GitHub asks, enable Actions for your fork. Select
   **Build Locus MPH IPA → Run workflow**.
5. After a successful run, open its **Artifacts** and download
   **Locus-MPH-unsigned**. Unzip that download to obtain the IPA.
6. Sign the IPA with your own sideloading tool before installing it. The same
   bundle ID is retained, so an installation can replace the original Locus app.

The workflow builds on a standard GitHub-hosted Mac runner. It does not require
an Apple account or signing certificate in GitHub. Standard runners are free
for public repositories; private repositories use the account's Actions quota.
No releases or public downloads are published by the workflow.

## Validation status

The GitHub Mac build passed on October 8, 2026 with Xcode 26.6, including the
independent speed checks and the Release iPhone app build. The downloaded IPA
was checked for ZIP integrity, ARM64 architecture, version 1.0.3/build 4, an
iOS 18 minimum, and the presence of the new mph controls in the executable.
Installation and behavior on a physical phone have not been tested here.
If a later build fails, download `Locus-MPH-build-log` for diagnosis.

## Local Mac build

Use Xcode 26 or later and XcodeGen, then run:

```sh
bash scripts/build_ipa.sh
```

## Upstream and license

Based on https://github.com/ChrisMack32/Locus, commit 83c8fb324983728e8f44759cfd834dc637ee38b5.
The original MIT license is retained. This package is a local modification and
is not an official upstream release.
