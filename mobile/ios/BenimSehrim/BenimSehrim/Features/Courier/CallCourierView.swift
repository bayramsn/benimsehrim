import SwiftUI
import MapKit
import CoreLocation

struct CallCourierView: View {
    @StateObject private var viewModel = CallCourierViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: viewModel.mapAnnotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    if annotation.isPickup {
                        Image(systemName: "cube.box.fill")
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 16) {
                Text("Paket Gönder")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Pickup
                HStack {
                    Image(systemName: "cube.box.fill")
                        .foregroundColor(.green)
                    
                    TextField("Alınacak Adres (Boş = Mevcut konum)", text: $viewModel.pickupAddress)
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
                                .foregroundColor(.green)
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
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Mevcut konumunuz kullanılıyor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
                
                // Dropoff
                HStack {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                    TextField("Teslim Adresi", text: $viewModel.dropAddress)
                        .onChange(of: viewModel.dropAddress) { newValue in
                            viewModel.onDropAddressChanged(newValue)
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Package Desc
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.gray)
                    TextField("Paket içeriği (örn: Dosya)", text: $viewModel.packageDesc)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Location error
                if let error = viewModel.locationError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button(action: viewModel.callCourier) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Kurye Çağır")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(viewModel.isValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
            }
            .padding()
            .background(.ultraThickMaterial)
            .cornerRadius(24)
            .shadow(radius: 10)
        }
        .navigationTitle("Kurye")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.initialize()
        }
    }
}

// MARK: - Map Annotation Model
struct CourierMapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let isPickup: Bool
}

// MARK: - ViewModel
class CallCourierViewModel: ObservableObject {
    @Published var pickupAddress = ""
    @Published var dropAddress = ""
    @Published var packageDesc = ""
    @Published var isLoading = false
    @Published var isGettingLocation = false
    @Published var usingCurrentLocation = false
    @Published var locationError: String?
    @Published var pickupCoordinate: CLLocationCoordinate2D?
    @Published var destinationCoordinate: CLLocationCoordinate2D?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.1425, longitude: 34.1709),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    private let locationManager = LocationManager.shared
    // Turkey-wide search region for better geocoding results
    private let searchRegion = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0), // Turkey center
        radius: 1000000, // 1000km radius covers all of Turkey
        identifier: "Turkey"
    )
    private var geocodeTask: Task<Void, Never>?
    
    var mapAnnotations: [CourierMapAnnotation] {
        var annotations: [CourierMapAnnotation] = []
        
        if let pickup = pickupCoordinate {
            annotations.append(CourierMapAnnotation(coordinate: pickup, isPickup: true))
        }
        
        if let dest = destinationCoordinate {
            annotations.append(CourierMapAnnotation(coordinate: dest, isPickup: false))
        }
        
        return annotations
    }
    
    var isValid: Bool {
        pickupCoordinate != nil && destinationCoordinate != nil && !packageDesc.isEmpty
    }
    
    @MainActor
    func initialize() async {
        // Request location permission
        locationManager.requestPermission()
        
        // Auto-get current location for pickup
        await useCurrentLocationForPickup()
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
                    
                    // Fit map to show both points if both exist
                    if let pickup = self.pickupCoordinate {
                        self.fitMapToShowBothPoints(start: pickup, end: result.coordinate)
                    }
                }
            }
        }
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
    
    func callCourier() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
        }
    }
}
