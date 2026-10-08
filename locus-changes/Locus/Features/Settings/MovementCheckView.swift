import CoreLocation
import SwiftUI

struct MovementCheckView: View {
    @EnvironmentObject private var session: SpoofSession
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var probe = MovementProbe()

    private var reportedSpeed: String {
        guard let location = probe.location,
              location.speed.isFinite, location.speed >= 0 else { return "Unavailable" }
        return String(format: "%.1f mph", MovementSpeed.mph(forMetersPerSecond: location.speed))
    }

    private var playbackState: String {
        if session.routePlaybackActive { return "Route running" }
        if session.joystickActive { return "Joystick active" }
        return session.isSpoofing ? "Holding a location" : "Stopped"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Playback", value: playbackState)
                LabeledContent("Selected speed", value: String(format: "%.1f mph", session.speedMPH))
                LabeledContent("Location engine", value: session.injectionMode.title)
                if session.injectionMode == .nativeSpeed {
                    LabeledContent("Speed sent to helper", value: String(format: "%.1f mph",
                        MovementSpeed.mph(forMetersPerSecond: session.lastSentSpeed)))
                    LabeledContent("Core Motion simulation", value: "Not provided")
                }
            } header: {
                Text("Locus")
            } footer: {
                Text("Selected speed controls route and joystick movement. Start a route before opening this page to check it while playing.")
            }

            Section {
                LabeledContent("iOS reported speed", value: reportedSpeed)
                if let location = probe.location {
                    LabeledContent("Location updated", value: location.timestamp.formatted(date: .omitted, time: .standard))
                    if location.horizontalAccuracy >= 0 {
                        LabeledContent("Location accuracy", value: String(format: "±%.0f m", location.horizontalAccuracy))
                    }
                    if let source = location.sourceInformation {
                        LabeledContent("Simulated location", value: source.isSimulatedBySoftware ? "Yes" : "No")
                    }
                }
                if let error = probe.locationError {
                    Text(error).foregroundStyle(.secondary)
                }
            } header: {
                Text("iPhone location reading")
            } footer: {
                Text("Unavailable means iOS has not supplied Locus with a valid speed. An old update time means the reading may be stale.")
            }

            Section {
                LabeledContent("Activity", value: probe.activity)
                LabeledContent("Confidence", value: probe.confidence)
                LabeledContent("Motion permission", value: probe.motionPermission)
                LabeledContent("Location permission", value: probe.locationPermission)
            } header: {
                Text("iPhone motion reading")
            } footer: {
                Text("These are readings received by Locus. Life360 may interpret them differently. This check reads motion; it does not simulate it. Permissions here apply to Locus separately from Life360.")
            }
        }
        .navigationTitle("Movement check")
        .onAppear { probe.start() }
        .onDisappear { probe.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { probe.updatePermissions() }
        }
    }
}
