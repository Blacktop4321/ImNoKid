import Foundation

struct RoutePoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    var isValid: Bool {
        latitude.isFinite && longitude.isFinite
            && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
}

enum RouteTiming {
    static let metersPerMile = 1609.344

    static func segmentLengths(_ points: [RoutePoint]) -> [Double] {
        zip(points, points.dropFirst()).map { start, end in
            guard start.isValid, end.isValid else { return 0 }
            let lat1 = start.latitude * .pi / 180
            let lat2 = end.latitude * .pi / 180
            let dLat = lat2 - lat1
            let dLon = (end.longitude - start.longitude) * .pi / 180
            let a = pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2)
            return 6_371_008.8 * 2 * asin(sqrt(min(1, max(0, a))))
        }
    }

    static func seconds(distance: Double, speedMPH: Double) -> TimeInterval {
        guard distance.isFinite, distance > 0 else { return 0 }
        return distance / MovementSpeed.metersPerSecond(forMPH: MovementSpeed.normalizedMPH(speedMPH))
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0 sec" }
        let total = Int(ceil(min(seconds, 2_000_000_000)))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let remaining = total % 60
        if hours > 0 { return "\(hours) hr \(minutes) min" }
        if minutes > 0 { return "\(minutes) min \(remaining) sec" }
        return "\(remaining) sec"
    }

    static func distanceText(_ meters: Double) -> String {
        String(format: "%.2f mi", max(0, meters.isFinite ? meters : 0) / metersPerMile)
    }
}
