import Foundation

/// Fields passed to the XCTest helper, not measurements from this phone.
struct NativeLocationPayload: Codable {
    let latitude: Double
    let longitude: Double
    let speed: Double
    let course: Double

    init?(latitude: Double, longitude: Double, speed: Double, course: Double) {
        guard latitude.isFinite, (-90...90).contains(latitude),
              longitude.isFinite, (-180...180).contains(longitude),
              speed.isFinite, (0...100).contains(speed),
              course.isFinite, course == -1 || (0..<360).contains(course) else { return nil }
        self.latitude = latitude
        self.longitude = longitude
        self.speed = speed
        self.course = course
    }

    static func bearing(fromLatitude: Double, fromLongitude: Double,
                        toLatitude: Double, toLongitude: Double) -> Double {
        guard fromLatitude.isFinite, fromLongitude.isFinite,
              toLatitude.isFinite, toLongitude.isFinite else { return -1 }
        let radians = Double.pi / 180
        let start = fromLatitude * radians
        let end = toLatitude * radians
        let delta = (toLongitude - fromLongitude) * radians
        let east = sin(delta) * cos(end)
        let north = cos(start) * sin(end) - sin(start) * cos(end) * cos(delta)
        guard hypot(east, north) > 1e-12 else { return -1 }
        return (atan2(east, north) / radians + 360).truncatingRemainder(dividingBy: 360)
    }
}
