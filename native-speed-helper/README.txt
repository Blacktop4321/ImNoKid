LOCUS NATIVE SPEED TEST KIT - VERSION 1.0.5

This is an experimental no-jailbreak path using Apple's UI-testing service.
It sends complete CLLocation objects with speed (m/s), course, timestamp,
and accuracy, through a separately signed and running XCTest helper.
It does not simulate Core Motion automotive activity. Life360's car icon
and speed display have not been verified on a physical phone.

SETUP ON WINDOWS
1. Extract this ZIP on your PC.
2. Sideload both Locus-1.0.5-unsigned.ipa and
   Locus-Native-Speed-Helper-unsigned.ipa with Sideloadly. Sign both with
   your own Apple account. Use Developer Mode and trust the developer.
3. Install Python 3.12 or newer from https://www.python.org/downloads/windows/.
   The Apple Mobile Device Service must be installed (the PC already used
   for Sideloadly should have it). Connect the iPhone by USB and unlock it.
4. Double-click Start-Native-Speed.cmd. It installs/updates pymobiledevice3,
   discovers the signed helper's identifier, mounts the developer image,
   and starts the helper. Keep the cable attached and the window open.
   Opening the helper's icon alone does not start its test service.
5. In Locus stop the existing spoof before switching engines. Open Settings,
   select Native speed helper (experimental), and tap Check native speed
   helper. Wait for Ready. Start a road route at 30 mph.
6. Open Settings > Movement check. Compare Speed sent to helper with
   iOS reported speed. The first is what Locus requested; the second is
   what iOS actually delivered. Save that screen, including Activity.
7. Stop spoofing in Locus before closing the Windows launcher. Stop clears
   the simulated location. If the helper is no longer reachable and a
   simulated fix remains, reboot the phone to restore the actual fix.

CONNECTION DETAILS
LocalDevVPN shows Tunnel IP 10.7.1.1 and Device IP 10.7.0.1. Leave the
Locus Device IP at 10.7.0.1 for Coordinates mode. Version 1.0.5 fixes the
interface check that previously called that connected VPN Not connected.
Native speed mode talks to the helper at 127.0.0.1:8100 on the same phone;
it does not use LocalDevVPN to send the route. Windows starts the helper
over Apple's developer connection. No Mac or jailbreak is used by you.

EXPECTED LIMITS
- The two IPAs are unsigned until your sideloading tool signs them.
- The helper must actually start and remain available. Windows or iOS
  launch/signing/runtime failures are possible and have not been tested
  with your hardware.
- The native-speed path is an experiment, not a guarantee that iOS forwards
  every field or that Life360 accepts it or recognizes a drive.
- Permissions shown in Movement check belong to Locus, separately from
  Life360. Enabling permission grants access; it does not invent activity.
- Both location methods can be marked simulated by iOS. This kit does not
  remove that flag or change Life360's app or account.

BUILD INPUTS AND LICENSES
Locus: ChrisMack32/Locus, MIT, pinned at
83c8fb324983728e8f44759cfd834dc637ee38b5, with the supplied modifications.
Helper: Appium/WebDriverAgent, BSD license, pinned at
2e98ac0ad4dbc99ab7c8bb01b7216fde252afb54, with location-only HTTP routes,
native speed/course, disabled screenshot streaming, and loopback binding.
The helper's BSD license is included in its app package.
Source changes and build logs are available on the locus-mph-build branch
of https://github.com/Blacktop4321/ImNoKid.
