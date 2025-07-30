import MapKit
import Observation
import SwiftUI
import AsyncAlgorithms
import CoreLocation
import struct Yosemite.Country

@available(iOS 17, *)
@Observable
final class AddressMapPickerViewModel: NSObject {
    var searchQuery = "" {
        willSet {
            searchQueryContinuation.yield(newValue)
        }
    }
    var searchResults: [MKLocalSearchCompletion] = []
    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3361, longitude: -122.0380),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    var annotations: [MapAnnotation] = []
    var showsSearchResults: Bool {
        searchResults.isEmpty == false
    }
    var hasValidSelection: Bool {
        selectedPlace != nil
    }
    var showsNoResultsMessage: Bool {
        searchCompleter.isSearching == false && !searchQuery.isEmpty && searchResults.isEmpty && selectedPlace == nil
    }

    private(set) var selectedPlaceAddress: String = ""

    private let (searchQueryStream, searchQueryContinuation) = AsyncStream.makeStream(of: String.self)
    private let searchCompleter: MKLocalSearchCompleter = .init()
    private var selectedPlace: MKPlacemark?

    private let countryByCode: (_ countryCode: String) -> Country?

    init(fields: AddressFormFields, countryByCode: @escaping (_ countryCode: String) -> Country?) {
        self.countryByCode = countryByCode
        super.init()
        configureSearchCompleter()
        configureMap(with: fields)
    }

    deinit {
        searchCompleter.delegate = nil
    }

    @MainActor
    func startStream() async {
        for await query in searchQueryStream.debounce(for: .seconds(0.3)) {
            if query.isEmpty {
                searchResults = []
            } else {
                searchCompleter.queryFragment = query
            }
        }
    }

    @MainActor
    func selectLocation(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)

        search.start { [weak self] (response, error) in
            guard let self,
                  let firstPlacemark = response?.mapItems.first?.placemark else {
                return
            }
            self.onSelectedPlacemark(firstPlacemark, result: result)
        }
    }

    func updateFields(_ fields: inout AddressFormFields) {
        guard let place = selectedPlace,
              let address = place.postalAddress else {
            return
        }

        fields.address1 = address.street
        fields.city = address.city
        fields.postcode = address.postalCode
        fields.country = address.isoCountryCode
        if let country = countryByCode(address.isoCountryCode) {
            fields.selectedCountry = country
            if let state = country.states.first(where: { $0.code == address.state }) {
                fields.selectedState = state
            } else {
                fields.state = address.state
            }
        } else {
            fields.country = address.isoCountryCode
            fields.state = address.state
        }
    }
}

@available(iOS 17, *)
private extension AddressMapPickerViewModel {
    func configureSearchCompleter() {
        searchCompleter.resultTypes = .address
        searchCompleter.delegate = self
    }

    func configureMap(with fields: AddressFormFields) {
        // If fields are empty and we have location permission, use current location for the initial map region.
        if fields.address1.isEmpty && fields.address2.isEmpty && fields.city.isEmpty {
            let locationManager = CLLocationManager()
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways,
               let currentLocation = locationManager.location {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    region = MKCoordinateRegion(
                        center: currentLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
                return
            }
        }

        // Try to geocode the address if we have enough information
        if !fields.address1.isEmpty && !fields.city.isEmpty {
            let addressString = formatAddressString(
                address1: fields.address1,
                address2: fields.address2,
                city: fields.city,
                state: fields.state,
                postcode: fields.postcode,
                country: fields.country
            )

            CLGeocoder().geocodeAddressString(addressString) { [weak self] placemarks, error in
                guard let self,
                      let location = placemarks?.first?.location else {
                    return
                }

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    annotations = [MapAnnotation(coordinate: location.coordinate)]
                    selectedPlaceAddress = addressString
                }
            }
        }
    }

    @MainActor
    func onSelectedPlacemark(_ placemark: MKPlacemark, result: MKLocalSearchCompletion) {
        withAnimation { [weak self] in
            guard let self else { return }
            self.searchResults = []
            self.region = MKCoordinateRegion(
                center: placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            self.annotations = [MapAnnotation(coordinate: placemark.coordinate)]
            self.selectedPlace = placemark
            self.selectedPlaceAddress = formatPlacemarkAddress(placemark)
        }
    }

    func formatAddressString(
        address1: String = "",
        address2: String = "",
        city: String = "",
        state: String = "",
        postcode: String = "",
        country: String = ""
    ) -> String {
        [address1, address2, city, state, postcode, country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    func formatPlacemarkAddress(_ placemark: MKPlacemark) -> String {
        placemark.postalAddress?.formatted(as: .mailingAddress) ?? ""
    }
}

@available(iOS 17, *)
extension AddressMapPickerViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DDLogError("⛔️ Address map search error: \(error)")
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
