import CoreLocation
import Foundation
import MapKit
import UIKit
import UserNotifications

enum TravelMode: String, CaseIterable, Identifiable {
    case walk, run, cycle, drive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walk: return "Walk"
        case .run: return "Run"
        case .cycle: return "Cycle"
        case .drive: return "Drive"
        }
    }

    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .run: return "figure.run"
        case .cycle: return "bicycle"
        case .drive: return "car.fill"
        }
    }

    /// Base meters per second before natural variation.
    var baseSpeed: CLLocationSpeed {
        switch self {
        case .walk: return 1.4
        case .run: return 3.3
        case .cycle: return 6.5
        case .drive: return 13.4
        }
    }

    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .walk, .run: return .walking
        case .cycle, .drive: return .automobile
        }
    }
}

enum SpoofStatus: Equatable {
    case idle
    case connecting
    case active
    case reconnecting
    case dropped(String)

    var label: String {
        switch self {
        case .idle: return "Not Spoofing"
        case .connecting: return "Starting…"
        case .active: return "Spoofing"
        case .reconnecting: return "Reconnecting…"
        case .dropped: return "Interrupted"
        }
    }

    var isDropped: Bool {
        if case .dropped = self { return true }
        return false
    }
}

@MainActor
final class SpoofSession: ObservableObject {
    @Published var status: SpoofStatus = .idle
    @Published var pin: CLLocationCoordinate2D?
    @Published var simulated: CLLocationCoordinate2D?
    @Published var travelMode: TravelMode = .walk {
        didSet {
            if oldValue != travelMode { customSpeedMPH = nil }
        }
    }
    @Published private var customSpeedMPH: Double? = nil
    @Published var speedVariationEnabled = false
    @Published var mapStyleIndex: Int = 0
    @Published var lastError: String?
    @Published var isBusy = false
    @Published var joystickActive = false
    @Published private(set) var routePlaybackActive = false
    @Published var injectionMode: InjectionMode = InjectionMode(
        rawValue: UserDefaults.standard.string(forKey: "locus.injectionMode") ?? "coordinates"
    ) ?? .coordinates {
        didSet { UserDefaults.standard.set(injectionMode.rawValue, forKey: "locus.injectionMode") }
    }
    @Published private(set) var lastSentSpeed = 0.0
    @Published private(set) var lastSentCourse = -1.0

    @Published var favorites: [SavedPlace] = []
    @Published var recents: [SavedPlace] = []

    private var resendTimer: Timer?
    private var healthTimer: Timer?
    private var joystickTimer: Timer?
    private var routeTask: Task<Void, Never>?
    private var routeGeneration: UUID?
    private var joystickLastTick = 0.0
    private var backgroundTask = UIBackgroundTaskIdentifier.invalid
    private var joystickVector: CGVector = .zero
    private let locationKeeper = BackgroundKeepAlive()

    private let favoritesKey = "locus.favorites"
    private let recentsKey = "locus.recents"

    init() {
        favorites = SavedPlace.load(key: favoritesKey)
        recents = SavedPlace.load(key: recentsKey)
    }

    var isSpoofing: Bool {
        if case .active = status { return true }
        if case .reconnecting = status { return true }
        return false
    }

    var speedMPH: Double {
        get { customSpeedMPH ?? MovementSpeed.mph(forMetersPerSecond: travelMode.baseSpeed) }
        set { customSpeedMPH = MovementSpeed.normalizedMPH(newValue) }
    }

    func resetSpeedToPreset() {
        customSpeedMPH = nil
    }

    private func movementSpeedMetersPerSecond() -> Double {
        let speed = MovementSpeed.metersPerSecond(forMPH: speedMPH)
        return speed * (speedVariationEnabled ? Double.random(in: 0.9...1.1) : 1)
    }

    func teleport(to coordinate: CLLocationCoordinate2D, pairing: PairingStore) {
        guard pairing.hasPairingFile || injectionMode == .nativeSpeed else {
            lastError = "Import an RPPairing file in Settings first."
            return
        }
        cancelRoute()
        stopJoystick()
        pin = coordinate
        apply(coordinate, pairing: pairing, markRecent: true)
    }

    func stop(pairing: PairingStore) {
        cancelRoute()
        stopJoystick()
        stopResend()
        stopHealth()
        isBusy = true
        let result: Result<Void, Error> = injectionMode == .nativeSpeed
            ? NativeSpeedEngine.clear().mapError { $0 as Error }
            : LocationEngine.clear().mapError { $0 as Error }
        isBusy = false
        switch result {
        case .success:
            simulated = nil
            lastSentSpeed = 0
            lastSentCourse = -1
            status = .idle
            endBackground()
            // Keep location updates running so the map puck / locate button
            // can return to the real GPS fix (not the leftover pin).
            locationKeeper.start()
        case .failure(let error):
            lastError = error.localizedDescription
            status = .dropped(error.localizedDescription)
            postDropNotification(error.localizedDescription)
        }
    }

    /// Best-known real device coordinate (not the teleport pin).
    var realCoordinate: CLLocationCoordinate2D? {
        locationKeeper.lastKnownCoordinate
    }

    /// Start lightweight GPS updates for the map puck / locate button.
    func startLocationUpdates() {
        locationKeeper.start()
    }

    func startJoystick(pairing: PairingStore) {
        guard pairing.hasPairingFile || injectionMode == .nativeSpeed else {
            lastError = "Import an RPPairing file in Settings first."
            return
        }
        let start = simulated ?? pin ?? locationKeeper.lastKnownCoordinate
        guard let start else {
            lastError = "Drop a pin or teleport somewhere before using the joystick."
            return
        }
        cancelRoute()
        if simulated == nil {
            apply(start, pairing: pairing, markRecent: false)
        }
        joystickActive = true
        joystickLastTick = ProcessInfo.processInfo.systemUptime
        joystickTimer?.invalidate()
        joystickTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickJoystick(pairing: pairing)
            }
        }
    }

    func updateJoystick(vector: CGVector) {
        joystickVector = vector
    }

    func stopJoystick() {
        let wasActive = joystickActive
        joystickActive = false
        joystickVector = .zero
        joystickTimer?.invalidate()
        joystickTimer = nil
        if wasActive { sendRestingSpeed() }
    }

    func followRoute(_ coordinates: [CLLocationCoordinate2D], pairing: PairingStore) {
        guard pairing.hasPairingFile || injectionMode == .nativeSpeed,
              coordinates.count >= 2 else { return }
        cancelRoute()
        stopJoystick()
        let generation = UUID()
        routeGeneration = generation
        routePlaybackActive = true
        routeTask = Task { [weak self] in
            guard let self, !Task.isCancelled else { return }
            defer {
                if self.routeGeneration == generation {
                    self.routePlaybackActive = false
                    self.routeTask = nil
                    self.routeGeneration = nil
                }
            }
            self.apply(coordinates[0], pairing: pairing, markRecent: true)
            guard self.isSpoofing else { return }
            let lengths = zip(coordinates, coordinates.dropFirst()).map { start, end in
                CLLocation(latitude: start.latitude, longitude: start.longitude)
                    .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
            }
            var progress = PlaybackProgress(
                segmentLengths: lengths,
                startedAt: ProcessInfo.processInfo.systemUptime
            )
            while !progress.hasFinished {
                if Task.isCancelled || self.routeGeneration != generation { return }
                let speed = self.movementSpeedMetersPerSecond()
                let interval = min(MovementSpeed.maximumStepSeconds, progress.remainingInSegment / speed)
                let deadline = progress.lastUpdateTime + interval
                let delay = max(0, deadline - ProcessInfo.processInfo.systemUptime)
                do {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } catch {
                    return
                }
                if Task.isCancelled || self.routeGeneration != generation { return }
                progress.advance(to: ProcessInfo.processInfo.systemUptime, metersPerSecond: speed)
                let coordinate: CLLocationCoordinate2D
                if progress.hasFinished {
                    coordinate = coordinates[coordinates.count - 1]
                } else {
                    let start = coordinates[progress.segmentIndex]
                    let end = coordinates[progress.segmentIndex + 1]
                    coordinate = CLLocationCoordinate2D(
                        latitude: start.latitude + (end.latitude - start.latitude) * progress.fraction,
                        longitude: start.longitude + (end.longitude - start.longitude) * progress.fraction
                    )
                }
                let course = progress.hasFinished ? -1 : NativeLocationPayload.bearing(
                    fromLatitude: coordinates[progress.segmentIndex].latitude,
                    fromLongitude: coordinates[progress.segmentIndex].longitude,
                    toLatitude: coordinates[progress.segmentIndex + 1].latitude,
                    toLongitude: coordinates[progress.segmentIndex + 1].longitude
                )
                self.apply(coordinate, pairing: pairing, markRecent: false,
                           speed: progress.hasFinished ? 0 : speed, course: course)
                if self.status.isDropped || self.status == .idle { return }
            }
        }
    }

    private func cancelRoute() {
        let wasActive = routePlaybackActive
        routeTask?.cancel()
        routeTask = nil
        routeGeneration = nil
        routePlaybackActive = false
        if wasActive { sendRestingSpeed() }
    }

    func addFavorite(name: String, coordinate: CLLocationCoordinate2D) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = SavedPlace(
            name: trimmed.isEmpty ? Self.coordinateLabel(coordinate) : trimmed,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        // Don't let a generic star overwrite a named favorite for the same spot.
        if let existing = favorites.first(where: { $0.id == place.id }),
           Self.isGenericFavoriteName(place.name),
           !Self.isGenericFavoriteName(existing.name) {
            return
        }
        favorites.removeAll { $0.id == place.id }
        favorites.insert(place, at: 0)
        SavedPlace.save(favorites, key: favoritesKey)
    }

    func renameFavorite(_ place: SavedPlace, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = favorites.firstIndex(where: { $0.id == place.id }) else { return }
        favorites[index].name = trimmed
        SavedPlace.save(favorites, key: favoritesKey)
    }

    func removeFavorite(_ place: SavedPlace) {
        favorites.removeAll { $0.id == place.id }
        SavedPlace.save(favorites, key: favoritesKey)
    }

    func removeRecent(_ place: SavedPlace) {
        recents.removeAll { $0.id == place.id }
        SavedPlace.save(recents, key: recentsKey)
    }

    /// Best display name for starring the current pin (search title, matching recent, etc.).
    func suggestedFavoriteName(for coordinate: CLLocationCoordinate2D, fallback: String? = nil) -> String {
        if let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let favorite = favorites.first(where: { $0.id == SavedPlace(name: "", latitude: coordinate.latitude, longitude: coordinate.longitude).id }),
           !Self.isGenericFavoriteName(favorite.name) {
            return favorite.name
        }
        if let recent = recents.first(where: {
            abs($0.latitude - coordinate.latitude) < 0.00015 && abs($0.longitude - coordinate.longitude) < 0.00015
        }), !Self.isGenericFavoriteName(recent.name) {
            return recent.name
        }
        return Self.coordinateLabel(coordinate)
    }

    private static func coordinateLabel(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    private static func isGenericFavoriteName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "Favorite" { return true }
        // Coordinate-looking labels from older teleports.
        let parts = trimmed.split(separator: ",")
        if parts.count == 2,
           Double(parts[0].trimmingCharacters(in: .whitespaces)) != nil,
           Double(parts[1].trimmingCharacters(in: .whitespaces)) != nil {
            return true
        }
        return false
    }

    private func apply(_ coordinate: CLLocationCoordinate2D, pairing: PairingStore,
                       markRecent: Bool, speed: Double = 0, course: Double = -1) {
        if status == .idle || status.isDropped {
            status = .connecting
        }
        isBusy = true
        let result = send(coordinate, pairing: pairing, speed: speed, course: course)
        isBusy = false
        switch result {
        case .success:
            lastSentSpeed = injectionMode == .nativeSpeed ? speed : 0
            lastSentCourse = injectionMode == .nativeSpeed ? course : -1
            simulated = coordinate
            pin = coordinate
            status = .active
            lastError = nil
            beginBackground()
            locationKeeper.start()
            startResend(pairing: pairing)
            startHealth(pairing: pairing)
            if markRecent {
                pushRecent(coordinate)
            }
        case .failure(let error):
            lastError = error.localizedDescription
            if simulated != nil {
                status = .dropped(error.localizedDescription)
                postDropNotification(error.localizedDescription)
            } else {
                status = .idle
            }
        }
    }

    private func tickJoystick(pairing: PairingStore) {
        guard joystickActive, let current = simulated else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = min(max(0, now - joystickLastTick), PlaybackProgress.maximumCatchUpSeconds)
        joystickLastTick = now
        let magnitude = hypot(joystickVector.dx, joystickVector.dy)
        guard magnitude > 0.08 else {
            if lastSentSpeed > 0 { sendRestingSpeed() }
            return
        }
        let nx = joystickVector.dx / magnitude
        let ny = -joystickVector.dy / magnitude
        let speed = movementSpeedMetersPerSecond() * min(1.0, magnitude)
        let meters = speed * elapsed
        let next = offset(coordinate: current, eastMeters: nx * meters, northMeters: ny * meters)
        let course = (atan2(Double(nx), Double(ny)) * 180 / .pi + 360)
            .truncatingRemainder(dividingBy: 360)
        apply(next, pairing: pairing, markRecent: false, speed: speed, course: course)
    }

    private func send(_ coordinate: CLLocationCoordinate2D, pairing: PairingStore,
                      speed: Double, course: Double) -> Result<Void, Error> {
        switch injectionMode {
        case .coordinates:
            return LocationEngine.set(latitude: coordinate.latitude, longitude: coordinate.longitude,
                                      pairingPath: pairing.pairingPath, deviceIP: TunnelConfig.targetIP)
                .mapError { $0 as Error }
        case .nativeSpeed:
            return NativeSpeedEngine.set(latitude: coordinate.latitude, longitude: coordinate.longitude,
                                         speed: speed, course: course)
                .mapError { $0 as Error }
        }
    }

    private func sendRestingSpeed() {
        guard injectionMode == .nativeSpeed, lastSentSpeed > 0, let coordinate = simulated else { return }
        switch NativeSpeedEngine.set(latitude: coordinate.latitude, longitude: coordinate.longitude,
                                    speed: 0, course: -1) {
        case .success:
            lastSentSpeed = 0
            lastSentCourse = -1
        case .failure(let error):
            lastError = error.localizedDescription
            status = .dropped(error.localizedDescription)
        }
    }

    private func startResend(pairing: PairingStore) {
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let sim = self.simulated,
                      !self.routePlaybackActive, !self.joystickActive else { return }
                _ = self.send(sim, pairing: pairing, speed: 0, course: -1)
            }
        }
    }

    private func stopResend() {
        resendTimer?.invalidate()
        resendTimer = nil
    }

    private func startHealth(pairing: PairingStore) {
        healthTimer?.invalidate()
        healthTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let sim = self.simulated else { return }
                if case .dropped = self.status {
                    self.status = .reconnecting
                    self.apply(sim, pairing: pairing, markRecent: false)
                } else if !(self.injectionMode == .nativeSpeed
                            ? NativeSpeedEngine.isSessionActive : LocationEngine.isSessionActive), self.isSpoofing {
                    self.status = .reconnecting
                    self.apply(sim, pairing: pairing, markRecent: false)
                }
            }
        }
    }

    private func stopHealth() {
        healthTimer?.invalidate()
        healthTimer = nil
    }

    private func pushRecent(_ coordinate: CLLocationCoordinate2D) {
        pushNamedRecent(
            name: Self.coordinateLabel(coordinate),
            coordinate: coordinate
        )
    }

    func pushNamedRecent(name: String, coordinate: CLLocationCoordinate2D) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = SavedPlace(
            name: trimmed.isEmpty ? Self.coordinateLabel(coordinate) : trimmed,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        recents.removeAll {
            abs($0.latitude - place.latitude) < 0.00015 && abs($0.longitude - place.longitude) < 0.00015
        }
        recents.insert(place, at: 0)
        if recents.count > 20 { recents = Array(recents.prefix(20)) }
        SavedPlace.save(recents, key: recentsKey)
    }

    private func beginBackground() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackground()
        }
    }

    private func endBackground() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    private func postDropNotification(_ message: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = "Locus spoof dropped"
        content.body = message
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func offset(coordinate: CLLocationCoordinate2D, eastMeters: Double, northMeters: Double) -> CLLocationCoordinate2D {
        let earth = 6378137.0
        let dLat = northMeters / earth * (180 / .pi)
        let dLon = eastMeters / (earth * cos(coordinate.latitude * .pi / 180)) * (180 / .pi)
        return CLLocationCoordinate2D(latitude: coordinate.latitude + dLat, longitude: coordinate.longitude + dLon)
    }
}
