RIMOSPOOF 1.1.0

INSTALL / UPDATE
Sign RimoSpoof-1.1.0-unsigned.ipa with your usual sideloading tool and install it.
Use the same Apple account and bundle identifier as the previous Locus install
to install as an update. Do not delete the old app first if you want to keep its
pairing file, favorites, and recents. The app now appears as RimoSpoof.

ROUTE TIME
Open Routes, build a road route, draw a path, or import GPX. The Route estimate
section shows distance, estimated duration, and arrival at your selected speed.
Following a route adds a map card with time left, distance left, progress,
pause/resume, and an end-route button. End route holds the current spoofed
location. The main Stop button clears spoofing.

SCHEDULES
In Routes > Schedule this route, enter a name and future start time, then tap
Schedule route. The saved schedule captures the route and current speed,
variation, travel mode, and location engine. Keep the app in the foreground,
the phone awake, and the required location connection available for auto-start.
If the app is inactive or another route/joystick is active, the schedule waits
for Start now. Schedules survive reopening and can be cancelled in Routes or
Settings > Scheduled routes. Allow notifications for reminders when closed.
There are up to 10 scheduled routes; each can contain up to 10,000 points.

UPDATE LOG
Open Settings > Update log. Full release notes are also in CHANGELOG.md.

NATIVE SPEED HELPER
The existing Locus Speed Helper and Windows launcher remain compatible.
The helper is an XCTest runner. Opening its icon alone does not start the
testing service; use Start-Native-Speed.cmd on Windows after sideloading both
IPAs. Keep the USB cable attached and the launcher window open. Stop spoofing
in RimoSpoof before closing the launcher. For native scheduled routes, leave
the Windows helper running before the scheduled start.

The user's report that the helper closed when tapped has not been diagnosed
from a crash log. It does not establish whether a Windows-launched session
will work. Windows launch, native speed forwarding, and Life360 compatibility
remain unverified on the user's phone. Core Motion spoofing is not implemented.

LICENSES
RimoSpoof is based on ChrisMack32/Locus (MIT). The helper is based on
Appium/WebDriverAgent (BSD). The original license remains inside each IPA.
