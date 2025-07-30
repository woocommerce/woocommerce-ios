import Foundation
import SwiftUI
import MapKit
import CoreLocation
import struct Yosemite.Address

@available(iOS 17.0, *)
@Observable
final class OrderDetailsShippingAddressMapViewModel {
    enum MapState {
        case loading
        case loaded(coordinate: CLLocationCoordinate2D, cameraPosition: MapCameraPosition)
        case failed
    }
    private(set) var mapState: MapState?

    /// The height of the map view - 150px if valid address, 0 if invalid.
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

    private let shippingAddress: Address?
    private let geocoder = CLGeocoder()

    init(shippingAddress: Address?, onMapTapped: (() -> Void)? = nil) {
        self.shippingAddress = shippingAddress
        self.onMapTapped = onMapTapped

        if isValidAddress {
            Task {
                await geocodeAddress()
            }
        }
    }
}

@available(iOS 17.0, *)
private extension OrderDetailsShippingAddressMapViewModel {
    @MainActor
    func geocodeAddress() async {
        guard let address = shippingAddress else { return }

        mapState = .loading

        let addressString = [
            address.address1,
            address.address2,
            address.city,
            address.state,
            address.postcode,
            address.country
        ].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")

        do {
            let placemarks = try await geocoder.geocodeAddressString(addressString)

            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                mapState = .failed
                return
            }

            let coordinate = location.coordinate
            let cameraPosition = MapCameraPosition.region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            ))

            mapState = .loaded(coordinate: coordinate, cameraPosition: cameraPosition)
        } catch {
            mapState = .failed
        }
    }
}
