import Foundation

@main
struct RouteFeatureChecks {
    static func close(_ actual: Double, _ expected: Double) {
        precondition(abs(actual - expected) < 1e-6, "\(actual) != \(expected)")
    }

    static func main() throws {
        // A mile at 30 mph takes two minutes; live speed changes update ETA.
        close(RouteTiming.seconds(distance: 1609.344, speedMPH: 30), 120)
        close(RouteTiming.seconds(distance: 1609.344, speedMPH: 60), 60)
        precondition(RouteTiming.durationText(61) == "1 min 1 sec")
        precondition(RouteTiming.durationText(3600) == "1 hr 0 min")
        precondition(RouteTiming.seconds(distance: .nan, speedMPH: 30) == 0)
        let points = [RoutePoint(latitude: 0, longitude: 179.9),
                      RoutePoint(latitude: 0, longitude: -179.9)]
        let acrossDateLine = RouteTiming.segmentLengths(points).reduce(0, +)
        precondition(acrossDateLine > 22_000 && acrossDateLine < 22_500)

        // Pausing for a minute holds distance; resuming advances normally.
        var progress = PlaybackProgress(segmentLengths: [5, 0, 95], startedAt: 0)
        progress.advance(to: 1, metersPerSecond: 10)
        close(progress.remainingDistance, 90)
        progress.rebaseClock(to: 61)
        close(progress.remainingDistance, 90)
        progress.advance(to: 61.5, metersPerSecond: 10)
        close(progress.remainingDistance, 85)
        var briefPause = PlaybackProgress(segmentLengths: [100], startedAt: 0)
        briefPause.rebaseClock(to: 0.4)
        briefPause.advance(to: 0.5, metersPerSecond: 10)
        close(briefPause.remainingDistance, 99)

        let due = Date(timeIntervalSince1970: 1000)
        var scheduled = ScheduledRoute(name: "Test", points: points, startsAt: due,
            speedMPH: 30, variationEnabled: false, travelMode: "drive", injectionMode: "nativeSpeed")
        precondition(scheduled.isValid)
        precondition(scheduled.decision(at: due.addingTimeInterval(-1), canStartAutomatically: true, isBusy: false) == .wait)
        precondition(scheduled.decision(at: due, canStartAutomatically: true, isBusy: false) == .start)
        precondition(scheduled.decision(at: due, canStartAutomatically: false, isBusy: false) == .needsOpen)
        precondition(scheduled.decision(at: due, canStartAutomatically: true, isBusy: true) == .busy)
        scheduled.status = .ready
        precondition(scheduled.decision(at: due, canStartAutomatically: true, isBusy: false) == .wait)
        let data = try JSONEncoder().encode([scheduled])
        let restored = try JSONDecoder().decode([ScheduledRoute].self, from: data)[0]
        precondition(restored.id == scheduled.id && restored.status == .ready && restored.points == points)
        scheduled.points[0] = RoutePoint(latitude: 91, longitude: 0)
        precondition(!scheduled.isValid)
        print("Route ETA, pause/resume, date-line, scheduling, and persistence checks passed.")
    }
}
