import Foundation
import SwiftUI
import MapKit
import CoreLocation
import NetworkingCore

@available(iOS 17.0, *)
@Observable
final class OrderDetailsShippingAddressMapViewModel {
    let shippingAddress: Address?

    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var isGeocoding: Bool = false
    var cameraPosition: MapCameraPosition = .automatic

    private let geocoder = CLGeocoder()

    /// The height of the map view - 150px if valid address, 0 if invalid
    var mapHeight: CGFloat {
        isValidAddress ? 150 : 0
    }

    /// Whether the address is valid for showing a map
    var isValidAddress: Bool {
        guard let address = shippingAddress else { return false }

        // An address is valid if it has at least city and country, or a street address
        let hasMinimalLocation = !address.city.isEmpty && !address.country.isEmpty
        let hasStreetAddress = !address.address1.isEmpty

        return hasMinimalLocation || hasStreetAddress
    }

    /// Action handler for when the map is tapped
    var onMapTapped: (() -> Void)?

    init(shippingAddress: Address?, onMapTapped: (() -> Void)? = nil) {
        self.shippingAddress = shippingAddress
        self.onMapTapped = onMapTapped

        if isValidAddress {
            geocodeAddress()
        }
    }

    private func geocodeAddress() {
        guard let address = shippingAddress else { return }

        isGeocoding = true

        let addressString = [
            address.address1,
            address.address2,
            address.city,
            address.state,
            address.postcode,
            address.country
        ].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")

        geocoder.geocodeAddressString(addressString) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isGeocoding = false

                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    // Fallback to a default coordinate if geocoding fails
                    self?.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                    self?.cameraPosition = .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                        latitudinalMeters: 10000,
                        longitudinalMeters: 10000
                    ))
                    return
                }
                let coordinate = location.coordinate
                self?.coordinate = coordinate
                self?.cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                ))
            }
        }
    }
}
