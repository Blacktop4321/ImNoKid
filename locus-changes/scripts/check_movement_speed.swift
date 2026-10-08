import Foundation

@main
struct MovementSpeedCheck {
    static func close(_ actual: Double, _ expected: Double, _ label: String) {
        precondition(abs(actual - expected) < 0.000001, "\(label): \(actual) != \(expected)")
    }

    static func main() {
        close(MovementSpeed.metersPerSecond(forMPH: 30), 13.4112, "30 mph conversion")
        close(MovementSpeed.mph(forMetersPerSecond: 13.4112), 30, "30 mph round trip")
        close(MovementSpeed.normalizedMPH(-1), 0.5, "lower bound")
        close(MovementSpeed.normalizedMPH(200), 100, "upper bound")
        close(MovementSpeed.normalizedMPH(.nan), 0.5, "NaN handling")
        close(MovementSpeed.normalizedMPH(.infinity), 0.5, "infinity handling")
        precondition(MovementSpeed.nextStep(remainingMeters: 0, metersPerSecond: 1) == nil)
        precondition(MovementSpeed.nextStep(remainingMeters: 10, metersPerSecond: 0) == nil)

        // The old playback over-delayed short segments. Check both partial final
        // steps and long segments at low, normal, and high selected speeds.
        for mph in [0.5, 3.1, 15.0, 30.0, 100.0] {
            let speed = MovementSpeed.metersPerSecond(forMPH: mph)
            for distance in [0.01, 1.0, 10.0, 12.0, 123.456] {
                var traveled = 0.0
                var elapsed = 0.0
                while traveled < distance {
                    guard let step = MovementSpeed.nextStep(
                        remainingMeters: distance - traveled,
                        metersPerSecond: speed
                    ) else { preconditionFailure("Expected a playback step") }
                    precondition(step.delaySeconds > 0 && step.delaySeconds <= 0.500001)
                    traveled = min(distance, traveled + step.distanceMeters)
                    elapsed += step.delaySeconds
                }
                close(traveled, distance, "route endpoint")
                close(elapsed, distance / speed, "route duration at \(mph) mph")
            }
        }

        let slow = MovementSpeed.nextStep(remainingMeters: 100, metersPerSecond: 1)!
        let fast = MovementSpeed.nextStep(remainingMeters: 100, metersPerSecond: 10)!
        close(fast.distanceMeters / slow.distanceMeters, 10, "live speed change")

        // Sending a coordinate must consume the playback interval, not be added
        // to it. Advance through corners when a delayed update crosses them.
        var progress = PlaybackProgress(segmentLengths: [5, 0, 5, 90], startedAt: 0)
        progress.advance(to: 0.5, metersPerSecond: 10)
        precondition(progress.segmentIndex == 2)
        close(progress.fraction, 0, "corner with repeated point")
        progress.advance(to: 1.2, metersPerSecond: 10)
        precondition(progress.segmentIndex == 3)
        close(progress.distanceInSegment, 2, "send latency carries through corner")
        progress.advance(to: 2.0, metersPerSecond: 20)
        close(progress.distanceInSegment, 18, "speed change with elapsed time")
        progress.advance(to: 3.0, metersPerSecond: 100)
        precondition(progress.hasFinished)

        // Variable send delays still move 30 mph over a 10-second route window.
        let selectedSpeed = MovementSpeed.metersPerSecond(forMPH: 30)
        var delayed = PlaybackProgress(segmentLengths: [1_000], startedAt: 0)
        for time in [0.5, 1.0, 1.7, 2.2, 2.9, 3.7, 4.2, 5.1, 6.2, 7.4, 8.0, 9.0, 10.0] {
            delayed.advance(to: time, metersPerSecond: selectedSpeed)
        }
        close(delayed.distanceInSegment / 10, selectedSpeed, "real-time speed with send latency")

        var paused = PlaybackProgress(segmentLengths: [1_000], startedAt: 0)
        paused.advance(to: 30, metersPerSecond: 10)
        close(paused.distanceInSegment, 20, "long suspension is capped")
        paused.advance(to: 29, metersPerSecond: 10)
        close(paused.distanceInSegment, 20, "backward clock rejected")
        let empty = PlaybackProgress(segmentLengths: [0, .nan, -1], startedAt: 0)
        precondition(empty.hasFinished)
        print("Movement-speed checks passed.")
    }
}
