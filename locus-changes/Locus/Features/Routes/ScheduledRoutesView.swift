import SwiftUI

struct ScheduledRoutesView: View {
    var body: some View {
        List { ScheduledRoutesSection() }.navigationTitle("Scheduled routes")
    }
}

struct ScheduledRoutesSection: View {
    @EnvironmentObject private var session: SpoofSession

    var body: some View {
        Section {
            if session.scheduledRoutes.isEmpty {
                Text("No scheduled routes. Build a route, then choose a start time in Routes.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(session.scheduledRoutes) { route in ScheduledRouteRow(route: route) }
                    .onDelete { offsets in
                        let ids = offsets.map { session.scheduledRoutes[$0].id }
                        ids.forEach { session.cancelScheduledRoute($0) }
                    }
            }
        } header: {
            Text("Scheduled routes")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Auto-start requires RimoSpoof open in the foreground and a working location connection. If the app is closed or another route is active, the schedule waits for Start now. Native speed also needs the Windows helper running.")
                if let note = session.scheduleNotificationNote { Text(note) }
            }
        }
    }
}

private struct ScheduledRouteRow: View {
    let route: ScheduledRoute
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var pairing: PairingStore

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(route.name).font(.headline)
                Spacer()
                Text(route.status == .waiting ? "Scheduled" : "Ready")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(route.status == .waiting ? LocusTheme.accent : LocusTheme.statusWarn)
            }
            Text(route.startsAt.formatted(date: .abbreviated, time: .shortened)).font(.subheadline)
            Text("\(String(format: "%.1f mph", route.speedMPH)) · \(RouteTiming.distanceText(route.distance)) · \(RouteTiming.durationText(route.duration))")
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            Text(InjectionMode(rawValue: route.injectionMode)?.title ?? "Unknown engine")
                .font(.caption).foregroundStyle(.secondary)
            if let note = route.note { Text(note).font(.caption).foregroundStyle(.secondary) }
            HStack {
                Button("Start now", systemImage: "play.fill") {
                    session.startScheduledRoute(route.id, pairing: pairing)
                }
                .disabled(session.routePlaybackActive || session.joystickActive || session.isBusy)
                Spacer()
                Button("Cancel", role: .destructive) { session.cancelScheduledRoute(route.id) }
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 5)
    }
}
