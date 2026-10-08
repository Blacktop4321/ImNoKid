import SwiftUI

struct RouteProgressCard: View {
    @EnvironmentObject private var session: SpoofSession

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(session.routePaused ? "Route paused" : "Route running",
                          systemImage: session.routePaused ? "pause.circle.fill" : "point.topleft.down.to.point.bottomright.curvepath")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(Int(session.routeCompletionFraction * 100))%")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                ProgressView(value: session.routeCompletionFraction).tint(LocusTheme.accent)
                HStack {
                    Text("\(RouteTiming.durationText(session.routeSecondsRemaining)) left")
                    Spacer()
                    Text("\(RouteTiming.distanceText(session.routeRemainingDistance)) left")
                }
                .font(.caption.monospacedDigit())
                HStack {
                    Text(session.routePaused ? "Resume to update arrival" :
                        "Est. arrival \(context.date.addingTimeInterval(session.routeSecondsRemaining).formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button { session.toggleRoutePause() } label: {
                        Image(systemName: session.routePaused ? "play.fill" : "pause.fill")
                            .frame(width: 36, height: 32)
                    }
                    .accessibilityLabel(session.routePaused ? "Resume route" : "Pause route")
                    Button { session.stopRoute() } label: {
                        Image(systemName: "stop.fill").frame(width: 36, height: 32)
                    }
                    .accessibilityLabel("End route and hold this location")
                }
                .buttonStyle(.borderless)
            }
            .padding(12)
            .locusGlass(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
