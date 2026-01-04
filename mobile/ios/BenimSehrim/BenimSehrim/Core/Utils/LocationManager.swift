import Foundation
import CoreLocation
import MapKit
import Combine

/// High-accuracy location manager for the app
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating = false
    @Published var locationError: String?
    
    // Heading/Compass
    @Published var heading: CLHeading?
    @Published var headingDegrees: Double = 0
    
    // Location History
    @Published var locationHistory: [CLLocation] = []
    
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // Turkey region for search bias
    private let turkeyRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0),
        span: MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 20.0)
    )
    
    // MARK: - Cache Storage
    private static var geocodeCache: [String: CLLocationCoordinate2D] = [:]
    private static var reverseCache: [String: String] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.benimsehrim.locationcache")
    
    // History settings
    private static let maxHistoryCount = 100
    
    // Saved locations key
    private static let savedLocationsKey = "savedLocations"
    
    override init() {
        super.init()
        locationManager.delegate = self
        // Highest accuracy for best location precision (like Maps app)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Distance filter - update on any movement
        locationManager.distanceFilter = kCLDistanceFilterNone
        // Activity type for better accuracy
        locationManager.activityType = .other
        // Allow background location updates if needed
        locationManager.allowsBackgroundLocationUpdates = false
        // Pause updates automatically to save battery
        locationManager.pausesLocationUpdatesAutomatically = true
        
        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start continuous location updates
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        isLocating = true
        locationManager.startUpdatingLocation()
    }
    
    /// Stop location updates
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        isLocating = false
    }
    
    /// Get current location once with high accuracy
    func getCurrentLocation() async throws -> CLLocation {
        // Check authorization
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            throw LocationError.notAuthorized
        }
        
        await MainActor.run {
            isLocating = true
            locationError = nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            
            // Request single high-accuracy location
            locationManager.requestLocation()
            
            // Timeout after 15 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
                if self?.locationContinuation != nil {
                    self?.locationContinuation?.resume(throwing: LocationError.timeout)
                    self?.locationContinuation = nil
                    self?.isLocating = false
                }
            }
        }
    }
    
    /// Reverse geocode a coordinate to get address
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                return formatAddress(placemark)
            }
        } catch {
            print("Reverse geocode error: \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Smart geocode - uses MKLocalSearch for typo tolerance and high accuracy
    func smartGeocode(_ query: String, near coordinate: CLLocationCoordinate2D? = nil) async -> PlaceResult? {
        guard query.count >= 2 else { return nil }
        
        // Check cache first
        let cacheKey = query.lowercased().trimmingCharacters(in: .whitespaces)
        if let cachedCoord = Self.geocodeCache[cacheKey] {
            return PlaceResult(name: query, address: query, coordinate: cachedCoord)
        }
        
        // Use MKLocalSearch for better results with typo tolerance
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        // Set region bias - prefer nearby results or Turkey
        if let coord = coordinate {
            searchRequest.region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        } else {
            searchRequest.region = turkeyRegion
        }
        
        searchRequest.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            if let firstItem = response.mapItems.first {
                let placemark = firstItem.placemark
                let result = PlaceResult(
                    name: firstItem.name ?? placemark.name ?? query,
                    address: formatAddress(placemark),
                    coordinate: placemark.coordinate
                )
                
                // Cache the result
                Self.cacheQueue.async {
                    Self.geocodeCache[cacheKey] = result.coordinate
                }
                
                return result
            }
        } catch {
            print("MKLocalSearch error: \(error.localizedDescription)")
        }
        
        // Fallback to CLGeocoder
        return await fallbackGeocode(query)
    }
    
    /// Search for multiple place suggestions (for autocomplete)
    func searchPlaces(_ query: String, near coordinate: CLLocationCoordinate2D? = nil) async -> [PlaceResult] {
        guard query.count >= 2 else { return [] }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        if let coord = coordinate {
            searchRequest.region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        } else {
            searchRequest.region = turkeyRegion
        }
        
        searchRequest.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            return response.mapItems.prefix(5).map { item in
                PlaceResult(
                    name: item.name ?? item.placemark.name ?? "",
                    address: formatAddress(item.placemark),
                    coordinate: item.placemark.coordinate
                )
            }
        } catch {
            print("Place search error: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fallback geocoding using CLGeocoder
    private func fallbackGeocode(_ query: String) async -> PlaceResult? {
        var searchQuery = query
        let lowerQuery = query.lowercased()
        if !lowerQuery.contains("türkiye") && !lowerQuery.contains("turkey") {
            searchQuery = "\(query), Türkiye"
        }
        
        geocoder.cancelGeocode()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(searchQuery)
            if let placemark = placemarks.first, let location = placemark.location {
                return PlaceResult(
                    name: placemark.name ?? query,
                    address: formatAddress(placemark),
                    coordinate: location.coordinate
                )
            }
        } catch {
            print("Fallback geocode error: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Legacy geocode method for compatibility
    func geocodeAddress(_ address: String, near region: CLCircularRegion? = nil) async -> CLLocationCoordinate2D? {
        let result = await smartGeocode(address)
        return result?.coordinate
    }
    
    /// Format CLPlacemark to readable address
    private func formatAddress(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            if !components.isEmpty {
                components[0] = "\(components[0]) No: \(subThoroughfare)"
            }
        }
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            if administrativeArea != placemark.locality {
                components.append(administrativeArea)
            }
        }
        
        return components.isEmpty ? "Bilinmeyen Konum" : components.joined(separator: ", ")
    }
    
    /// Format MKPlacemark to readable address
    private func formatAddress(_ placemark: MKPlacemark) -> String {
        var components: [String] = []
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let subThoroughfare = placemark.subThoroughfare {
            if !components.isEmpty {
                components[0] = "\(components[0]) No: \(subThoroughfare)"
            }
        }
        if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            if administrativeArea != placemark.locality {
                components.append(administrativeArea)
            }
        }
        
        return components.isEmpty ? "Bilinmeyen Konum" : components.joined(separator: ", ")
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or inaccurate locations
        let age = -location.timestamp.timeIntervalSinceNow
        if age > 10.0 { return }
        
        if location.horizontalAccuracy < 0 { return }
        if location.horizontalAccuracy > 100 { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.isLocating = false
            
            // Add to history
            self.addToHistory(location)
            
            // Fulfill continuation if waiting
            if let continuation = self.locationContinuation {
                continuation.resume(returning: location)
                self.locationContinuation = nil
            }
        }
        
        // Get address for current location
        Task {
            if let address = await reverseGeocode(coordinate: location.coordinate) {
                await MainActor.run {
                    self.currentAddress = address
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isLocating = false
            self.locationError = error.localizedDescription
            
            if let continuation = self.locationContinuation {
                continuation.resume(throwing: error)
                self.locationContinuation = nil
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    // MARK: - Heading Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading
            self.headingDegrees = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        }
    }
    
    // MARK: - Geofencing Delegate
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NotificationCenter.default.post(
            name: .didEnterGeofence,
            object: nil,
            userInfo: ["region": region]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NotificationCenter.default.post(
            name: .didExitGeofence,
            object: nil,
            userInfo: ["region": region]
        )
    }
}

// MARK: - Heading/Compass Tracking
extension LocationManager {
    /// Start heading updates for compass functionality
    func startHeadingUpdates() {
        guard CLLocationManager.headingAvailable() else {
            print("Heading not available on this device")
            return
        }
        locationManager.startUpdatingHeading()
    }
    
    /// Stop heading updates
    func stopHeadingUpdates() {
        locationManager.stopUpdatingHeading()
    }
    
    /// Get compass direction as string (K, KD, D, GD, G, GB, B, KB)
    var compassDirection: String {
        let directions = ["K", "KD", "D", "GD", "G", "GB", "B", "KB"]
        let index = Int((headingDegrees + 22.5) / 45.0) % 8
        return directions[index]
    }
    
    /// Get full compass direction name
    var compassDirectionFull: String {
        let directions = ["Kuzey", "Kuzey-Doğu", "Doğu", "Güney-Doğu", "Güney", "Güney-Batı", "Batı", "Kuzey-Batı"]
        let index = Int((headingDegrees + 22.5) / 45.0) % 8
        return directions[index]
    }
}

// MARK: - Speed Tracking
extension LocationManager {
    /// Current speed in meters per second
    var currentSpeed: Double {
        guard let speed = currentLocation?.speed, speed >= 0 else { return 0 }
        return speed
    }
    
    /// Current speed in km/h
    var speedKmh: Double {
        currentSpeed * 3.6
    }
    
    /// Formatted speed string
    var formattedSpeed: String {
        "\(Int(speedKmh)) km/sa"
    }
    
    /// Check if user is moving (speed > 2 km/h)
    var isMoving: Bool {
        speedKmh > 2
    }
    
    /// Speed category
    var speedCategory: SpeedCategory {
        switch speedKmh {
        case 0..<2: return .stationary
        case 2..<7: return .walking
        case 7..<25: return .cycling
        case 25..<60: return .urbanDriving
        case 60..<120: return .highwayDriving
        default: return .veryFast
        }
    }
}

// MARK: - Altitude
extension LocationManager {
    /// Current altitude in meters
    var altitude: Double? {
        currentLocation?.altitude
    }
    
    /// Formatted altitude string
    var formattedAltitude: String {
        guard let alt = altitude else { return "Bilinmiyor" }
        return "\(Int(alt)) m"
    }
    
    /// Vertical accuracy in meters
    var verticalAccuracy: Double? {
        guard let acc = currentLocation?.verticalAccuracy, acc >= 0 else { return nil }
        return acc
    }
}

// MARK: - Location History
extension LocationManager {
    /// Add location to history
    func addToHistory(_ location: CLLocation) {
        locationHistory.append(location)
        if locationHistory.count > Self.maxHistoryCount {
            locationHistory.removeFirst()
        }
    }
    
    /// Total distance traveled in meters
    var totalDistanceTraveled: Double {
        guard locationHistory.count > 1 else { return 0 }
        var total: Double = 0
        for i in 1..<locationHistory.count {
            total += locationHistory[i].distance(from: locationHistory[i-1])
        }
        return total
    }
    
    /// Formatted total distance
    var formattedTotalDistance: String {
        let meters = totalDistanceTraveled
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters)) m"
    }
    
    /// Clear location history
    func clearHistory() {
        locationHistory.removeAll()
    }
    
    /// Get average speed from history
    var averageSpeed: Double {
        guard locationHistory.count > 1,
              let first = locationHistory.first,
              let last = locationHistory.last else { return 0 }
        
        let timeInterval = last.timestamp.timeIntervalSince(first.timestamp)
        guard timeInterval > 0 else { return 0 }
        
        return totalDistanceTraveled / timeInterval // m/s
    }
    
    /// Formatted average speed
    var formattedAverageSpeed: String {
        let kmh = averageSpeed * 3.6
        return String(format: "%.1f km/sa", kmh)
    }
}

// MARK: - Saved/Favorite Locations
extension LocationManager {
    /// Get saved locations from UserDefaults
    var savedLocations: [SavedLocation] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Self.savedLocationsKey),
                  let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) else {
                return []
            }
            return locations
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Self.savedLocationsKey)
            }
        }
    }
    
    /// Save a new location
    func saveLocation(name: String, address: String, coordinate: CLLocationCoordinate2D, icon: String = "mappin") {
        var locations = savedLocations
        let newLocation = SavedLocation(
            id: UUID(),
            name: name,
            address: address,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            icon: icon,
            createdAt: Date()
        )
        locations.append(newLocation)
        savedLocations = locations
    }
    
    /// Save current location
    func saveCurrentLocation(name: String, icon: String = "mappin") async {
        guard let location = currentLocation else { return }
        let address = await reverseGeocode(coordinate: location.coordinate) ?? "Bilinmeyen Adres"
        saveLocation(name: name, address: address, coordinate: location.coordinate, icon: icon)
    }
    
    /// Delete a saved location
    func deleteLocation(id: UUID) {
        savedLocations.removeAll { $0.id == id }
    }
    
    /// Update a saved location
    func updateLocation(id: UUID, name: String? = nil, icon: String? = nil) {
        var locations = savedLocations
        if let index = locations.firstIndex(where: { $0.id == id }) {
            if let name = name {
                locations[index].name = name
            }
            if let icon = icon {
                locations[index].icon = icon
            }
            savedLocations = locations
        }
    }
    
    /// Get distance to a saved location
    func distanceToSavedLocation(_ location: SavedLocation) -> Double? {
        guard let current = currentLocation else { return nil }
        let saved = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return current.distance(from: saved)
    }
    
    /// Get nearest saved location
    var nearestSavedLocation: SavedLocation? {
        guard currentLocation != nil else { return nil }
        return savedLocations.min { loc1, loc2 in
            (distanceToSavedLocation(loc1) ?? .infinity) < (distanceToSavedLocation(loc2) ?? .infinity)
        }
    }
}

// MARK: - Proximity & Distance
extension LocationManager {
    /// Check if current location is near a coordinate
    func isNearby(coordinate: CLLocationCoordinate2D, radiusMeters: Double = 100) -> Bool {
        guard let current = currentLocation else { return false }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target) <= radiusMeters
    }
    
    /// Get distance to a coordinate
    func distanceTo(coordinate: CLLocationCoordinate2D) -> Double? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)
    }
    
    /// Get formatted distance to a coordinate
    func formattedDistanceTo(coordinate: CLLocationCoordinate2D) -> String? {
        guard let distance = distanceTo(coordinate: coordinate) else { return nil }
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        return "\(Int(distance)) m"
    }
    
    /// Calculate distance between two coordinates
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

// MARK: - Route Calculation
extension LocationManager {
    /// Calculate driving route between two points
    func calculateRoute(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile
    ) async -> RouteResult? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = transportType
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                return RouteResult(
                    distance: route.distance,
                    duration: route.expectedTravelTime,
                    polyline: route.polyline
                )
            }
        } catch {
            print("Route calculation error: \(error.localizedDescription)")
        }
        return nil
    }
    
    /// Format distance for display
    func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return "\(Int(meters)) m"
    }
    
    /// Format duration for display
    func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) sa"
            }
            return "\(hours) sa \(mins) dk"
        }
        return "\(minutes) dk"
    }
    
    /// Estimate fare based on distance and duration
    func estimateFare(distance: Double, duration: TimeInterval, baseFare: Double = 20.0, perKm: Double = 15.0, perMinute: Double = 1.0) -> FareEstimation {
        let distanceKm = distance / 1000.0
        let durationMin = duration / 60.0
        
        let distanceCost = distanceKm * perKm
        let timeCost = durationMin * perMinute
        let totalFare = baseFare + distanceCost + timeCost
        
        return FareEstimation(
            baseFare: baseFare,
            distanceCost: distanceCost,
            timeCost: timeCost,
            totalFare: totalFare,
            minFare: totalFare * 0.9,
            maxFare: totalFare * 1.2
        )
    }
}

// MARK: - Geofencing
extension LocationManager {
    /// Start monitoring a circular region
    func startMonitoring(center: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("Geofencing not available")
            return
        }
        
        let maxRadius = locationManager.maximumRegionMonitoringDistance
        let actualRadius = min(radius, maxRadius)
        
        let region = CLCircularRegion(
            center: center,
            radius: actualRadius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    /// Stop monitoring a specific region
    func stopMonitoring(identifier: String) {
        for region in locationManager.monitoredRegions {
            if region.identifier == identifier {
                locationManager.stopMonitoring(for: region)
                break
            }
        }
    }
    
    /// Stop monitoring all regions
    func stopAllMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    /// Get all monitored regions
    var monitoredRegions: Set<CLRegion> {
        return locationManager.monitoredRegions
    }
}

// MARK: - Accuracy Helpers
extension LocationManager {
    /// Human-readable accuracy description
    var accuracyDescription: String {
        guard let location = currentLocation else { return "Bilinmiyor" }
        let accuracy = location.horizontalAccuracy
        
        switch accuracy {
        case ..<5: return "Mükemmel (\(Int(accuracy))m)"
        case ..<15: return "Çok İyi (\(Int(accuracy))m)"
        case ..<50: return "İyi (\(Int(accuracy))m)"
        case ..<100: return "Orta (\(Int(accuracy))m)"
        default: return "Düşük (\(Int(accuracy))m)"
        }
    }
    
    /// Check if current location has high accuracy
    var isHighAccuracy: Bool {
        guard let location = currentLocation else { return false }
        return location.horizontalAccuracy <= 20
    }
    
    /// Get accuracy level
    var accuracyLevel: AccuracyLevel {
        guard let location = currentLocation else { return .unknown }
        let accuracy = location.horizontalAccuracy
        
        switch accuracy {
        case ..<5: return .excellent
        case ..<15: return .veryGood
        case ..<50: return .good
        case ..<100: return .moderate
        default: return .poor
        }
    }
    
    /// Location age in seconds
    var locationAge: TimeInterval? {
        guard let location = currentLocation else { return nil }
        return -location.timestamp.timeIntervalSinceNow
    }
    
    /// Check if location is fresh
    var isLocationFresh: Bool {
        guard let age = locationAge else { return false }
        return age < 30
    }
}

// MARK: - Cache Methods
extension LocationManager {
    /// Cached geocode
    func cachedGeocode(_ address: String) async -> CLLocationCoordinate2D? {
        let key = address.lowercased().trimmingCharacters(in: .whitespaces)
        
        var cachedResult: CLLocationCoordinate2D?
        Self.cacheQueue.sync {
            cachedResult = Self.geocodeCache[key]
        }
        
        if let cached = cachedResult {
            return cached
        }
        
        if let result = await smartGeocode(address) {
            Self.cacheQueue.async {
                Self.geocodeCache[key] = result.coordinate
            }
            return result.coordinate
        }
        return nil
    }
    
    /// Cached reverse geocode
    func cachedReverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let key = String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude)
        
        var cachedResult: String?
        Self.cacheQueue.sync {
            cachedResult = Self.reverseCache[key]
        }
        
        if let cached = cachedResult {
            return cached
        }
        
        if let result = await reverseGeocode(coordinate: coordinate) {
            Self.cacheQueue.async {
                Self.reverseCache[key] = result
            }
            return result
        }
        return nil
    }
    
    /// Clear all caches
    func clearCache() {
        Self.cacheQueue.async {
            Self.geocodeCache.removeAll()
            Self.reverseCache.removeAll()
        }
    }
}

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case notAuthorized
    case timeout
    case unknown
    case geofencingNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Konum izni verilmedi"
        case .timeout:
            return "Konum alınamadı, lütfen tekrar deneyin"
        case .unknown:
            return "Bilinmeyen bir hata oluştu"
        case .geofencingNotAvailable:
            return "Bu cihazda geofencing desteklenmiyor"
        }
    }
}

// MARK: - Supporting Types
struct PlaceResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: PlaceResult, rhs: PlaceResult) -> Bool {
        lhs.id == rhs.id
    }
}

struct SavedLocation: Codable, Identifiable {
    let id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var icon: String
    var createdAt: Date
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RouteResult {
    let distance: CLLocationDistance
    let duration: TimeInterval
    let polyline: MKPolyline
    
    var distanceKm: Double {
        return distance / 1000.0
    }
    
    var durationMinutes: Int {
        return Int(duration / 60)
    }
}

struct FareEstimation {
    let baseFare: Double
    let distanceCost: Double
    let timeCost: Double
    let totalFare: Double
    let minFare: Double
    let maxFare: Double
    
    var formattedTotal: String {
        return String(format: "%.2f ₺", totalFare)
    }
    
    var formattedRange: String {
        return String(format: "%.0f - %.0f ₺", minFare, maxFare)
    }
}

enum AccuracyLevel: String {
    case excellent = "Mükemmel"
    case veryGood = "Çok İyi"
    case good = "İyi"
    case moderate = "Orta"
    case poor = "Düşük"
    case unknown = "Bilinmiyor"
    
    var color: String {
        switch self {
        case .excellent, .veryGood: return "green"
        case .good: return "blue"
        case .moderate: return "orange"
        case .poor, .unknown: return "red"
        }
    }
}

enum SpeedCategory: String {
    case stationary = "Durağan"
    case walking = "Yürüyüş"
    case cycling = "Bisiklet"
    case urbanDriving = "Şehir İçi"
    case highwayDriving = "Otoban"
    case veryFast = "Çok Hızlı"
    
    var icon: String {
        switch self {
        case .stationary: return "figure.stand"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .urbanDriving: return "car"
        case .highwayDriving: return "car.2"
        case .veryFast: return "airplane"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didEnterGeofence = Notification.Name("didEnterGeofence")
    static let didExitGeofence = Notification.Name("didExitGeofence")
}
