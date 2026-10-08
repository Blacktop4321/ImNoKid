import Foundation

enum MovementSpeed {
    static let metersPerSecondPerMPH = 0.44704
    static let mphRange: ClosedRange<Double> = 0.5...100
    static let maximumStepSeconds = 0.5

    static func normalizedMPH(_ value: Double) -> Double {
        guard value.isFinite else { return mphRange.lowerBound }
        return min(mphRange.upperBound, max(mphRange.lowerBound, value))
    }

    static func metersPerSecond(forMPH value: Double) -> Double {
        value * metersPerSecondPerMPH
    }

    static func mph(forMetersPerSecond value: Double) -> Double {
        value / metersPerSecondPerMPH
    }

    struct Step {
        let distanceMeters: Double
        let delaySeconds: Double
    }

    /// Short final segments keep the same planned speed as full segments.
    static func nextStep(remainingMeters: Double, metersPerSecond: Double) -> Step? {
        guard remainingMeters.isFinite, remainingMeters > 0,
              metersPerSecond.isFinite, metersPerSecond > 0 else { return nil }
        let distance = min(remainingMeters, metersPerSecond * maximumStepSeconds)
        return Step(distanceMeters: distance, delaySeconds: distance / metersPerSecond)
    }
}
