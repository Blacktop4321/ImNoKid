# RimoSpoof update log

## 1.1.0 — October 8, 2026

- Renamed the main app to RimoSpoof and prepared its supplied face photo icon for local IPA packaging; the photo is not uploaded to this repository.
- Added route distance, travel time, and estimated arrival before playback.
- Added live remaining time, remaining distance, and a progress bar on the map.
- Added pause/resume without discarding route progress; ending a route holds the current simulated location.
- Added up to 10 persisted scheduled routes. Each saves its path, start time, speed, variation, travel mode, and location engine.
- Added local reminders, Start now, and cancellation for scheduled routes.
- Scheduled routes auto-start while the app is in the foreground with a working location connection. Past-due routes wait for Start now after reopening; schedules do not replace an active route or joystick.
- Added Settings > Update log and Settings > Scheduled routes.
- Kept the existing app identifier, preference keys, pairing type, and URL scheme for updates.
- The speed helper is unchanged. Start it through the Windows launcher; tapping its app icon alone does not start its testing service. The reported direct-launch closure has not been diagnosed from a crash log.

Core Motion spoofing is not implemented. Native speed forwarding and Life360 driving indicators still require a physical-phone test. Scheduling does not create reliable background or force-quit auto-starts.

## 1.0.5

- Added the experimental Windows-launched native speed helper.
- Fixed recognition of LocalDevVPN's separate tunnel and device IPs.

## 1.0.4

- Added Movement check with actual iOS speed, location source, and motion readings.
- Accounted for send latency and limited movement after app suspension.

## 1.0.3

- Added target mph, optional speed variation, and route/joystick movement controls.
