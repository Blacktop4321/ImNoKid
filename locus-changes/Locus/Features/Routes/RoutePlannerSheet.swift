import CoreLocation
import SwiftUI

struct RoutePlannerSheet: View {
    @Binding var start: CLLocationCoordinate2D?
    @Binding var end: CLLocationCoordinate2D?
    @Binding var isRouting: Bool
    var path: [CLLocationCoordinate2D]
    var onBuild: () -> Void
    var onPlay: () -> Void
    var onImportGPX: () -> Void
    var onExportGPX: () -> Void
    var onUseDrawn: () -> Void

    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss
    @State private var scheduledName = "My route"
    @State private var scheduledAt = Date().addingTimeInterval(900)
    @State private var scheduleSaved = false

    private var distance: Double {
        RouteTiming.segmentLengths(path.map { RoutePoint(latitude: $0.latitude, longitude: $0.longitude) }).reduce(0, +)
    }

    private var duration: TimeInterval {
        RouteTiming.seconds(distance: distance, speedMPH: session.speedMPH)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Speed") {
                    MovementSpeedControls()
                }

                Section("Route estimate") {
                    if path.count >= 2, distance > 0 {
                        LabeledContent("Distance", value: RouteTiming.distanceText(distance))
                        LabeledContent("Travel time", value: RouteTiming.durationText(duration))
                        LabeledContent("Arrive if started now") {
                            Text(Date().addingTimeInterval(duration), style: .time)
                        }
                    } else {
                        Text("Build, draw, or import a route to see its travel time.")
                            .foregroundStyle(.secondary)
                    }
                    Text("Estimates use the selected speed. Speed changes, variation, pauses, and connection delays can change arrival.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                if session.routePlaybackActive {
                    Section("Current route") { RouteProgressCard() }
                }

                Section("Road route") {
                    Button("Use current pin / spoof as start") {
                        start = session.simulated ?? session.pin
                    }
                    Button("Use current pin as end") {
                        end = session.pin
                    }
                    LabeledContent("Start") {
                        Text(coordText(start)).font(.caption.monospaced())
                    }
                    LabeledContent("End") {
                        Text(coordText(end)).font(.caption.monospaced())
                    }
                    Button {
                        onBuild()
                    } label: {
                        if isRouting {
                            ProgressView()
                        } else {
                            Label("Build walk/drive route on roads", systemImage: "road.lanes")
                        }
                    }
                    .disabled(isRouting)
                }

                Section("Play / draw / GPX") {
                    Button {
                        onUseDrawn()
                    } label: {
                        Label("Use drawn path from map", systemImage: "pencil.tip")
                    }
                    Button(action: onPlay) {
                        Label("Follow route", systemImage: "play.fill")
                    }
                    .disabled(path.count < 2 || distance == 0 || session.routePlaybackActive || session.isBusy)
                    Button(action: onImportGPX) {
                        Label("Import GPX", systemImage: "square.and.arrow.down")
                    }
                    Button(action: onExportGPX) {
                        Label("Export GPX", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    Text("Travel mode selects roads or footpaths. Target speed applies during playback and at full joystick movement. Turn on speed variation for changes of up to 10%.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Schedule this route") {
                    TextField("Route name", text: $scheduledName)
                    DatePicker("Start", selection: $scheduledAt, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    if distance > 0 {
                        LabeledContent("Estimated arrival") {
                            Text(scheduledAt.addingTimeInterval(duration), style: .date)
                            Text(scheduledAt.addingTimeInterval(duration), style: .time)
                        }
                    }
                    Button {
                        scheduleSaved = session.scheduleRoute(path, name: scheduledName, startsAt: scheduledAt)
                    } label: {
                        Label("Schedule route", systemImage: "calendar.badge.plus")
                    }
                    .disabled(path.count < 2 || distance == 0 || isRouting)
                    if scheduleSaved {
                        Label("Schedule saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(LocusTheme.statusGood)
                    }
                }

                ScheduledRoutesSection()
            }
            .navigationTitle("Routes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func coordText(_ c: CLLocationCoordinate2D?) -> String {
        guard let c else { return "—" }
        return String(format: "%.5f, %.5f", c.latitude, c.longitude)
    }
}
