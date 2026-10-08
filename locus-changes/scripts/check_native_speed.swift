import Foundation

@main
struct NativeSpeedChecks {
    static func main() throws {
        let speed = MovementSpeed.metersPerSecond(forMPH: 30)
        precondition(abs(speed - 13.4112) < 1e-9)
        let moving = NativeLocationPayload(latitude: 40, longitude: -74, speed: speed, course: 90)!
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(moving)) as! [String: Double]
        precondition(json["speed"] == speed && json["course"] == 90)
        let resting = NativeLocationPayload(latitude: 40, longitude: -74, speed: 0, course: -1)!
        precondition(resting.speed == 0 && resting.course == -1)
        precondition(NativeLocationPayload(latitude: 91, longitude: 0, speed: 1, course: 0) == nil)
        precondition(NativeLocationPayload(latitude: 0, longitude: 181, speed: 1, course: 0) == nil)
        precondition(NativeLocationPayload(latitude: 0, longitude: 0, speed: .nan, course: 0) == nil)
        precondition(NativeLocationPayload(latitude: 0, longitude: 0, speed: -1, course: 0) == nil)
        precondition(NativeLocationPayload(latitude: 0, longitude: 0, speed: 1, course: 360) == nil)
        precondition(abs(NativeLocationPayload.bearing(fromLatitude: 0, fromLongitude: 0,
            toLatitude: 0, toLongitude: 1) - 90) < 1e-9)
        precondition(abs(NativeLocationPayload.bearing(fromLatitude: 0, fromLongitude: 0,
            toLatitude: 1, toLongitude: 0)) < 1e-9)
        precondition(abs(NativeLocationPayload.bearing(fromLatitude: 0, fromLongitude: 179.9,
            toLatitude: 0, toLongitude: -179.9) - 90) < 1e-9)
        precondition(NativeLocationPayload.bearing(fromLatitude: 0, fromLongitude: 0,
            toLatitude: 0, toLongitude: 0) == -1)
        precondition(TunnelAddressMatcher.matches(targetIP: "10.7.0.1", interfaceIP: "10.7.1.1", isTunnel: true))
        precondition(!TunnelAddressMatcher.matches(targetIP: "10.7.0.1", interfaceIP: "10.7.1.1", isTunnel: false))
        precondition(!TunnelAddressMatcher.matches(targetIP: "10.7.0.1", interfaceIP: "10.8.1.1", isTunnel: true))
        precondition(TunnelAddressMatcher.matches(targetIP: "10.9.0.1", interfaceIP: "10.9.0.2", isTunnel: true))
        print("Native speed payload, course, stationary speed, and tunnel address checks passed.")
    }
}
