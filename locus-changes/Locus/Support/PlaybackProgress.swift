import Foundation

/// Advances along the whole route using a monotonic clock, including send time.
struct PlaybackProgress {
    static let maximumCatchUpSeconds = 2.0

    private let lengths: [Double]
    private(set) var segmentIndex = 0
    private(set) var distanceInSegment = 0.0
    private(set) var lastUpdateTime: Double

    init(segmentLengths: [Double], startedAt: Double) {
        lengths = segmentLengths.map { $0.isFinite ? max(0, $0) : 0 }
        lastUpdateTime = startedAt
        skipEmptySegments()
    }

    var hasFinished: Bool { segmentIndex >= lengths.count }

    var fraction: Double {
        hasFinished ? 1 : distanceInSegment / lengths[segmentIndex]
    }

    var remainingInSegment: Double {
        hasFinished ? 0 : lengths[segmentIndex] - distanceInSegment
    }

    mutating func advance(to time: Double, metersPerSecond: Double) {
        guard time.isFinite, time >= lastUpdateTime,
              metersPerSecond.isFinite, metersPerSecond >= 0 else { return }
        // Treat a long app suspension as a pause instead of a giant jump.
        let elapsed = min(time - lastUpdateTime, Self.maximumCatchUpSeconds)
        lastUpdateTime = time
        var distance = elapsed * metersPerSecond
        while !hasFinished, distance > 0 {
            let remaining = remainingInSegment
            if distance < remaining {
                distanceInSegment += distance
                return
            }
            distance -= remaining
            segmentIndex += 1
            distanceInSegment = 0
            skipEmptySegments()
        }
    }

    private mutating func skipEmptySegments() {
        while !hasFinished, lengths[segmentIndex] == 0 {
            segmentIndex += 1
        }
    }
}
