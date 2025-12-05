import MapKit
import Observation
import SwiftUI
import AsyncAlgorithms
import CoreLocation
import struct Yosemite.Country

/// Protocol for providing local search functionality for address map picker.
/// Abstracts MKLocalSearch to enable testing with mock implementations.
protocol AddressMapLocalSearchProviding {
    /// Performs a local search based on the provided search completion.
    /// - Parameter completion: The search completion containing location query information.
    /// - Returns: A search response containing map items with placemarks.
    /// - Throws: MapKit errors if the search fails.
    func search(for completion: MKLocalSearchCompletion) async throws -> MKLocalSearch.Response
}

/// Default implementation of AddressMapLocalSearchProviding that uses MKLocalSearch.
/// This is the production implementation that makes real network requests to MapKit services.
final class DefaultAddressMapLocalSearchProvider: AddressMapLocalSearchProviding {
    func search(for completion: MKLocalSearchCompletion) async throws -> MKLocalSearch.Response {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        return try await search.start()
    }
}

@Observable
final class AddressMapPickerViewModel: NSObject {
    var searchQuery = "" {
        willSet {
            searchQueryContinuation.yield(newValue)
        }
    }
    private(set) var searchResults: [MKLocalSearchCompletion] = []
    var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3361, longitude: -122.0380),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    var annotations: [MapAnnotation] = []
    var showsSearchResults: Bool {
        searchResults.isEmpty == false
    }
    var hasValidSelection: Bool {
        selectedPlace != nil
    }
    var showsNoResultsMessage: Bool {
        searchCompleter.isSearching == false && searchQuery.count >= 2 && searchResults.isEmpty && selectedPlace == nil
    }
    var selectedPlaceAddress: String {
        selectedPlace?.postalAddress?.formatted(as: .mailingAddress) ?? ""
    }

    private let (searchQueryStream, searchQueryContinuation) = AsyncStream.makeStream(of: String.self)
    private let searchCompleter: MKLocalSearchCompleter = .init()
    private var selectedPlace: MKPlacemark?

    private let countryByCode: (_ countryCode: String) -> Country?
    private let searchProvider: AddressMapLocalSearchProviding

    init(fields: AddressFormFields,
         countryByCode: @escaping (_ countryCode: String) -> Country?,
         searchProvider: AddressMapLocalSearchProviding = DefaultAddressMapLocalSearchProvider()) {
        self.countryByCode = countryByCode
        self.searchProvider = searchProvider
        super.init()
        configureSearchCompleter()
        configureMap(with: fields)
    }

    deinit {
        searchQueryContinuation.finish()
        searchCompleter.delegate = nil
    }

    @MainActor
    func startObservingSearchQuery() async {
        for await query in searchQueryStream.debounce(for: .seconds(0.3)) {
            if query.isEmpty {
                searchResults = []
            } else {
                searchCompleter.queryFragment = query
            }
        }
    }

    /// Selects a location from the local map search results.
    /// - Parameter result: The selected search completion result.
    @MainActor
    func selectLocation(_ result: MKLocalSearchCompletion) async {
        do {
            let response = try await searchProvider.search(for: result)
            guard let firstPlacemark = response.mapItems.first?.placemark else {
                return
            }
            await onSelectedPlacemark(firstPlacemark)
        } catch {
            DDLogError("⛔️ Map search error from selecting a search result: \(error)")
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
                    position = .region(
                        MKCoordinateRegion(
                            center: currentLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
                return
            }
        }

        // Tries to geocode the existing address if possible.
        let addressString = formatAddressString(fields: fields)
        if addressString.isNotEmpty {
            Task { @MainActor in
                do {
                    let placemarks = try await CLGeocoder().geocodeAddressString(addressString)
                    guard let location = placemarks.first?.location else {
                        return
                    }

                    position = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                    annotations = [MapAnnotation(coordinate: location.coordinate)]
                } catch {
                    DDLogError("⛔️ Error geocoding initial address: \(error)")
                }
            }
        }
    }

    @MainActor
    func onSelectedPlacemark(_ placemark: MKPlacemark) async {
        await withCheckedContinuation { continuation in
            withAnimation { [weak self] in
                guard let self else { return }
                searchResults = []
                position = .region(
                    MKCoordinateRegion(
                        center: placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                )
                annotations = [MapAnnotation(coordinate: placemark.coordinate)]
                selectedPlace = placemark
            } completion: {
                continuation.resume()
            }
        }
    }

    func formatAddressString(fields: AddressFormFields) -> String {
        [fields.address1, fields.address2, fields.city, fields.state, fields.postcode, fields.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

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
