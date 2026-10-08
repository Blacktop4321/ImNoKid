import Foundation

struct ScheduledRoute: Codable, Identifiable {
    enum Status: String, Codable { case waiting, ready }
    enum Decision: Equatable { case wait, start, needsOpen, busy }

    var id = UUID()
    var name: String
    var points: [RoutePoint]
    var startsAt: Date
    var speedMPH: Double
    var variationEnabled: Bool
    var travelMode: String
    var injectionMode: String
    var status: Status = .waiting
    var note: String?

    var distance: Double { RouteTiming.segmentLengths(points).reduce(0, +) }
    var duration: TimeInterval { RouteTiming.seconds(distance: distance, speedMPH: speedMPH) }
    var isValid: Bool {
        (2...10_000).contains(points.count) && points.allSatisfy(\.isValid)
            && startsAt.timeIntervalSinceReferenceDate.isFinite
            && speedMPH.isFinite && MovementSpeed.mphRange.contains(speedMPH)
            && ["walk", "run", "cycle", "drive"].contains(travelMode)
            && ["coordinates", "nativeSpeed"].contains(injectionMode)
            && distance > 0
    }

    var notificationID: String { "rimo.route.\(id.uuidString)" }

    func decision(at now: Date, canStartAutomatically: Bool, isBusy: Bool) -> Decision {
        guard status == .waiting, startsAt <= now else { return .wait }
        guard canStartAutomatically else { return .needsOpen }
        return isBusy ? .busy : .start
    }
}
