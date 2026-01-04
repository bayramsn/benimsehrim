import SwiftUI
import MapKit
import CoreLocation

struct TaxiView: View {
    @StateObject private var viewModel = TaxiViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map - iOS 16 Compatible
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: viewModel.mapAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    if annotation.type == .driver {
                        Image(systemName: "car.fill")
                            .foregroundColor(.yellow)
                            .padding(8)
                            .background(Color.black)
                            .clipShape(Circle())
                    } else if annotation.type == .pickup {
                        Image(systemName: "location.fill")
                            .foregroundColor(.primaryGreen)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    } else {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Bottom Sheet
            VStack(spacing: 16) {
                // Pickup
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.primaryGreen)
                    
                    TextField("Nereden? (Boş bırakın = Mevcut konum)", text: $viewModel.pickupAddress)
                        .submitLabel(.next)
                        .onChange(of: viewModel.pickupAddress) { newValue in
                            viewModel.onPickupAddressChanged(newValue)
                        }
                    
                    if viewModel.isGettingLocation {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if viewModel.pickupAddress.isEmpty {
                        Button(action: {
                            Task { await viewModel.useCurrentLocationForPickup() }
                        }) {
                            Image(systemName: "location.viewfinder")
                                .foregroundColor(.primaryGreen)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Current location indicator
                if viewModel.usingCurrentLocation && !viewModel.pickupAddress.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.primaryGreen)
                            .font(.caption)
                        Text("Mevcut konumunuz kullanılıyor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                
                // Destination
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    
                    TextField("Nereye?", text: $viewModel.dropAddress)
                        .submitLabel(.done)
                        .onChange(of: viewModel.dropAddress) { newValue in
                            viewModel.onDropAddressChanged(newValue)
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Fare estimate
                if let estimate = viewModel.fareEstimate {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tahmini Ücret")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(estimate.estimatedFare.min)) - \(Int(estimate.estimatedFare.max))₺")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(estimate.distance, specifier: "%.1f") km")
                                .font(.body)
                            Text("~\(estimate.duration) dk")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.primaryGreen.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.opacity)
                }
                
                // Location error
                if let error = viewModel.locationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                // Request button
                Button(action: viewModel.requestRide) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "car.fill")
                            Text("Taksi Çağır")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(!viewModel.canRequest || viewModel.isLoading ? Color.gray : Color.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canRequest || viewModel.isLoading)
                
                if !viewModel.nearbyDrivers.isEmpty {
                    Text("🚕 \(viewModel.nearbyDrivers.count) taksi yakınızda")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        }
        .navigationTitle("Taksi Çağır")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.initialize()
        }
    }
}

// MARK: - Map Annotation Model
enum MapAnnotationType {
    case driver
    case pickup
    case destination
}

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MapAnnotationType
}

// MARK: - ViewModel
class TaxiViewModel: ObservableObject {
    @Published var pickupAddress: String = ""
    @Published var dropAddress: String = ""
    @Published var nearbyDrivers: [NearbyDriver] = []
    @Published var fareEstimate: FareEstimate?
    @Published var isLoading = false
    @Published var isGettingLocation = false
    @Published var usingCurrentLocation = false
    @Published var locationError: String?
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var pickupCoordinate: CLLocationCoordinate2D?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.1425, longitude: 34.1709),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    private let locationManager = LocationManager.shared
    private let geocoder = CLGeocoder()
    // Turkey-wide search region for better geocoding results
    private let searchRegion = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0), // Turkey center
        radius: 1000000, // 1000km radius covers all of Turkey
        identifier: "Turkey"
    )
    private var geocodeTask: Task<Void, Never>?
    
    var mapAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = []
        
        // Add drivers
        for driver in nearbyDrivers {
            annotations.append(MapAnnotationItem(
                coordinate: CLLocationCoordinate2D(latitude: driver.latitude, longitude: driver.longitude),
                type: .driver
            ))
        }
        
        // Add pickup
        if let pickup = pickupCoordinate {
            annotations.append(MapAnnotationItem(coordinate: pickup, type: .pickup))
        }
        
        // Add destination
        if let dest = destinationCoordinate {
            annotations.append(MapAnnotationItem(coordinate: dest, type: .destination))
        }
        
        return annotations
    }
    
    var canRequest: Bool {
        pickupCoordinate != nil && destinationCoordinate != nil && fareEstimate != nil
    }
    
    @MainActor
    func initialize() async {
        // Request location permission
        locationManager.requestPermission()
        
        // Load nearby drivers
        await loadNearbyDrivers()
        
        // Auto-get current location for pickup
        await useCurrentLocationForPickup()
    }
    
    @MainActor
    func loadNearbyDrivers() async {
        // Mock drivers near current location
        nearbyDrivers = [
            NearbyDriver(id: "1", latitude: 39.1430, longitude: 34.1715, distance: 0.2),
            NearbyDriver(id: "2", latitude: 39.1420, longitude: 34.1700, distance: 0.3),
            NearbyDriver(id: "3", latitude: 39.1440, longitude: 34.1725, distance: 0.4)
        ]
    }
    
    @MainActor
    func useCurrentLocationForPickup() async {
        isGettingLocation = true
        locationError = nil
        
        do {
            let location = try await locationManager.getCurrentLocation()
            
            pickupCoordinate = location.coordinate
            usingCurrentLocation = true
            
            // Get address for the location
            if let address = await locationManager.reverseGeocode(coordinate: location.coordinate) {
                pickupAddress = address
            } else {
                pickupAddress = "Mevcut Konum"
            }
            
            // Update map region
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            
            // Update drivers location based on user location
            updateNearbyDriversLocation(near: location.coordinate)
            
            recalculateRoute()
            
        } catch {
            locationError = error.localizedDescription
            // Fallback to default location
            pickupCoordinate = CLLocationCoordinate2D(latitude: 39.1425, longitude: 34.1709)
            pickupAddress = "Kırşehir Merkez"
            usingCurrentLocation = false
        }
        
        isGettingLocation = false
    }
    
    func onPickupAddressChanged(_ newAddress: String) {
        // If user clears the field, prepare to use current location
        if newAddress.isEmpty {
            usingCurrentLocation = false
            pickupCoordinate = nil
            fareEstimate = nil
            return
        }
        
        // If user starts typing, they want a custom address
        if usingCurrentLocation && newAddress != pickupAddress {
            usingCurrentLocation = false
        }
        
        // Geocode the entered address
        geocodePickup(newAddress)
    }
    
    func onDropAddressChanged(_ newAddress: String) {
        if newAddress.isEmpty {
            destinationCoordinate = nil
            fareEstimate = nil
            return
        }
        
        geocodeDropoff(newAddress)
    }
    
    private func geocodePickup(_ address: String) {
        geocodeTask?.cancel()
        
        guard address.count >= 2 else { return }
        
        geocodeTask = Task {
            // Debounce - wait 600ms before geocoding for better UX
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            
            // Use smartGeocode for better typo tolerance and accuracy
            if let result = await locationManager.smartGeocode(address, near: pickupCoordinate) {
                await MainActor.run {
                    self.pickupCoordinate = result.coordinate
                    
                    withAnimation {
                        self.region = MKCoordinateRegion(
                            center: result.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                    
                    self.recalculateRoute()
                }
            }
        }
    }
    
    private func geocodeDropoff(_ address: String) {
        geocodeTask?.cancel()
        
        guard address.count >= 2 else { return }
        
        geocodeTask = Task {
            // Debounce - wait 600ms before geocoding for better UX
            try? await Task.sleep(nanoseconds: 600_000_000)
            if Task.isCancelled { return }
            
            // Use smartGeocode for better typo tolerance and accuracy
            if let result = await locationManager.smartGeocode(address, near: pickupCoordinate) {
                await MainActor.run {
                    self.destinationCoordinate = result.coordinate
                    
                    withAnimation {
                        self.region = MKCoordinateRegion(
                            center: result.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                    
                    self.recalculateRoute()
                }
            }
        }
    }
    
    private func updateNearbyDriversLocation(near coordinate: CLLocationCoordinate2D) {
        // Update mock drivers to be near the user's location
        nearbyDrivers = [
            NearbyDriver(id: "1", latitude: coordinate.latitude + 0.002, longitude: coordinate.longitude + 0.003, distance: 0.2),
            NearbyDriver(id: "2", latitude: coordinate.latitude - 0.001, longitude: coordinate.longitude - 0.002, distance: 0.3),
            NearbyDriver(id: "3", latitude: coordinate.latitude + 0.003, longitude: coordinate.longitude - 0.001, distance: 0.4)
        ]
    }
    
    private func recalculateRoute() {
        guard let start = pickupCoordinate, let end = destinationCoordinate else {
            fareEstimate = nil
            return
        }
        
        // Use LocationManager's calculateRoute for accurate distance and duration
        Task {
            if let routeResult = await locationManager.calculateRoute(from: start, to: end) {
                // Use real route data
                let fareEstimation = locationManager.estimateFare(
                    distance: routeResult.distance,
                    duration: routeResult.duration
                )
                
                await MainActor.run {
                    self.fareEstimate = FareEstimate(
                        distance: routeResult.distanceKm,
                        duration: routeResult.durationMinutes,
                        estimatedFare: FareRange(min: fareEstimation.minFare, max: fareEstimation.maxFare),
                        nearbyDrivers: nearbyDrivers.count
                    )
                }
            } else {
                // Fallback to straight-line calculation
                let dist = locationManager.distance(from: start, to: end) / 1000.0 // km
                let duration = Int(dist * 2.5) + 5
                let basePrice = 20.0
                let perKm = 15.0
                let total = basePrice + (dist * perKm)
                
                await MainActor.run {
                    self.fareEstimate = FareEstimate(
                        distance: dist,
                        duration: duration,
                        estimatedFare: FareRange(min: total, max: total * 1.2),
                        nearbyDrivers: nearbyDrivers.count
                    )
                }
            }
        }
        
        // Adjust map to show both points
        fitMapToShowBothPoints(start: start, end: end)
    }
    
    private func fitMapToShowBothPoints(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        let midLat = (start.latitude + end.latitude) / 2
        let midLng = (start.longitude + end.longitude) / 2
        
        let latDelta = abs(start.latitude - end.latitude) * 1.5
        let lngDelta = abs(start.longitude - end.longitude) * 1.5
        
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: midLat, longitude: midLng),
                span: MKCoordinateSpan(
                    latitudeDelta: max(latDelta, 0.02),
                    longitudeDelta: max(lngDelta, 0.02)
                )
            )
        }
    }
    
    func requestRide() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
        }
    }
}
