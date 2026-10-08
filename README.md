# Locus 1.0.5 native speed test kit

This branch builds two unsigned iPhone IPAs: Locus 1.0.5 and Locus Speed Helper. The experimental engine sends complete CLLocation readings with speed and course through a separately running XCTest helper. Windows starts that helper; no local Mac or jailbreak is required. The default Coordinates engine retains the original latitude/longitude simulation.

Use the two IPAs with `native-speed-helper/windows/Start-Native-Speed.cmd`; see [the setup steps](native-speed-helper/README.txt). Stop an existing spoof before switching engines. Native route and joystick movement send speed and course; holding a location and reaching the route endpoint send zero speed. Movement check distinguishes requested helper speed from actual iOS readings. The VPN check now recognizes LocalDevVPN's 10.7.1.1 interface separately from its 10.7.0.1 device endpoint.

Both native ARM64 builds, playback/payload/course/tunnel checks, and Windows launcher syntax passed in [run 37727953794](https://github.com/Blacktop4321/ImNoKid/actions/runs/37727953794). Downloaded IPAs passed archive, bundle, required-code, and license checks. Actual Windows launch, phone runtime behavior, speed-field forwarding, and Life360's car icon remain unverified. Core Motion simulation is not implemented.

Sources: Locus `83c8fb324983728e8f44759cfd834dc637ee38b5` (MIT) and Appium/WebDriverAgent `2e98ac0ad4dbc99ab7c8bb01b7216fde252afb54` (BSD). The helper exposes location-only routes on 127.0.0.1 and disables screenshot streaming.
