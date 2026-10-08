import SwiftUI

struct UpdateLogView: View {
    var body: some View {
        List {
            Section("1.1.0 · October 8, 2026") {
                item("RimoSpoof", "New app name and face photo icon.", "person.crop.square")
                item("Route timing", "Preview travel time and arrival before starting. Watch remaining time, distance, and progress while following a route.", "clock")
                item("Scheduled routes", "Save a route with its start time, speed, travel mode, and location engine. Auto-start while the app is open; otherwise receive a reminder and use Start now.", "calendar.badge.clock")
                item("Pause and resume", "Hold your current position without losing route progress. Resume when ready, or end the route and hold the location.", "pause.circle")
                item("Update log", "See the changes in each release from Settings.", "list.bullet.rectangle")
            }
            Section("1.0.5") {
                item("Native speed experiment", "Added a separate Windows-launched testing helper for location, speed, and direction. Phone behavior and Life360 compatibility remain unverified.", "speedometer")
                item("Tunnel status", "Recognizes LocalDevVPN’s separate tunnel and device addresses.", "network")
            }
            Section("1.0.4") {
                item("Movement check", "Displays iOS-reported speed and motion activity separately from the selected playback speed.", "waveform.path")
                item("Playback timing", "Accounts for location-send time and limits jumps after an app suspension.", "timer")
            }
            Section("1.0.3") {
                item("MPH controls", "Added a target speed from 0.5 to 100 mph and optional speed variation for routes and joystick movement.", "slider.horizontal.3")
            }
            Section {
                Text("Core Motion spoofing is not implemented. A selected route speed or schedule does not guarantee another app will show a drive or car icon.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("RimoSpoof is based on ChrisMack32/Locus, licensed under MIT. The native speed helper is based on Appium/WebDriverAgent, licensed under BSD.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Update log")
    }

    private func item(_ title: String, _ detail: String, _ icon: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.vertical, 3)
        } icon: {
            Image(systemName: icon).foregroundStyle(LocusTheme.accent)
        }
    }
}
