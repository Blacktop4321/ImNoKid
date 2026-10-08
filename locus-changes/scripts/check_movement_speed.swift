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
        print("Movement-speed checks passed.")
    }
}
