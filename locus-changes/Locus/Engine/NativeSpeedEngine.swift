import Foundation

enum NativeSpeedError: LocalizedError {
    case invalidReading
    case unavailable
    case incompatibleHelper
    case rejected(String)

    var errorDescription: String? {
        switch self {
        case .invalidReading: return "The requested coordinates, speed, or course are invalid."
        case .unavailable: return "Native speed helper is not responding. Sideload the helper IPA, unlock your iPhone, and start it with Start-Native-Speed.cmd on Windows."
        case .incompatibleHelper: return "This is not the RimoSpoof native speed helper. Start the helper from the supplied kit."
        case .rejected(let message): return "Native speed helper: \(message)"
        }
    }
}

/// Loopback client for a separately installed, running XCTest helper.
/// The helper supplies full CLLocation objects; it does not change Core Motion.
enum NativeSpeedEngine {
    private static let queue = DispatchQueue(label: "com.chrismack.locus.native-speed")
    private static let baseURL = URL(string: "http://127.0.0.1:8100")!
    private static var active = false
    private static var verified = false
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 3
        config.timeoutIntervalForResource = 5
        config.waitsForConnectivity = false
        config.connectionProxyDictionary = [:]
        return URLSession(configuration: config)
    }()

    private final class Reply: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Result<[String: Any], NativeSpeedError>?

        func finish(_ value: Result<[String: Any], NativeSpeedError>) {
            lock.lock()
            stored = value
            lock.unlock()
        }

        func read() -> Result<[String: Any], NativeSpeedError> {
            lock.lock()
            defer { lock.unlock() }
            return stored ?? .failure(.unavailable)
        }
    }

    static var isSessionActive: Bool { queue.sync { active } }

    static func check() -> Result<Void, NativeSpeedError> {
        queue.sync { verifyLocked() }
    }

    static func set(latitude: Double, longitude: Double, speed: Double,
                    course: Double) -> Result<Void, NativeSpeedError> {
        queue.sync {
            guard let fix = NativeLocationPayload(latitude: latitude, longitude: longitude,
                                                  speed: speed, course: course),
                  let body = try? JSONEncoder().encode(fix) else { return .failure(.invalidReading) }
            if !verified, case .failure(let error) = verifyLocked() { return .failure(error) }
            let result = requestLocked(method: "POST", path: "wda/simulatedLocation", body: body)
            switch result {
            case .success:
                active = true
                return .success(())
            case .failure(let error):
                active = false
                verified = false
                return .failure(error)
            }
        }
    }

    static func clear() -> Result<Void, NativeSpeedError> {
        queue.sync {
            if !verified, case .failure(let error) = verifyLocked() { return .failure(error) }
            let result = requestLocked(method: "DELETE", path: "wda/simulatedLocation")
            active = false
            switch result {
            case .success: return .success(())
            case .failure(let error):
                verified = false
                return .failure(error)
            }
        }
    }

    private static func verifyLocked() -> Result<Void, NativeSpeedError> {
        verified = false
        switch requestLocked(method: "GET", path: "locus/capabilities") {
        case .success(let value):
            guard (value["locusProtocolVersion"] as? NSNumber)?.intValue == 1,
                  value["speed"] as? Bool == true else { return .failure(.incompatibleHelper) }
            verified = true
            return .success(())
        case .failure(let error): return .failure(error)
        }
    }

    private static func requestLocked(method: String, path: String,
                                      body: Data? = nil) -> Result<[String: Any], NativeSpeedError> {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let reply = Reply()
        let finished = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { data, response, error in
            defer { finished.signal() }
            guard error == nil, let response = response as? HTTPURLResponse, let data,
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                reply.finish(.failure(.unavailable))
                return
            }
            let value = object["value"] as? [String: Any] ?? [:]
            if !(200..<300).contains(response.statusCode) || value["error"] != nil {
                reply.finish(.failure(.rejected(value["message"] as? String ?? "Request failed (HTTP \(response.statusCode)).")))
            } else {
                reply.finish(.success(value))
            }
        }
        task.resume()
        guard finished.wait(timeout: .now() + 5) == .success else {
            task.cancel()
            return .failure(.unavailable)
        }
        return reply.read()
    }
}
