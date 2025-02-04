import MapKit
import Observation
import SwiftUI
import AsyncAlgorithms
import CoreLocation

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
    var showingSearchResults: Bool {
        searchResults.isEmpty == false
    }
    var hasValidSelection: Bool {
        selectedPlace != nil
    }

    private let (searchQueryStream, searchQueryContinuation) = AsyncStream.makeStream(of: String.self)
    private let searchCompleter: MKLocalSearchCompleter = .init()

    private var selectedPlace: CLPlacemark?

    init(fields: AddressFormFields) {
        super.init()
        configureLocationServices()
        configureSearchCompleter()
        configureMap(with: fields)
    }

    private func configureLocationServices() {
        let locationManager = CLLocationManager()
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    private func configureSearchCompleter() {
        searchCompleter.resultTypes = .address
        searchCompleter.delegate = self
    }

    private func configureMap(with fields: AddressFormFields) {
        // Try to geocode the address if we have enough information
        if !fields.address1.isEmpty && !fields.city.isEmpty {
            let addressString = [
                fields.address1,
                fields.address2,
                fields.city,
                fields.state,
                fields.postcode,
                fields.country
            ].filter { !$0.isEmpty }.joined(separator: ", ")
            
            CLGeocoder().geocodeAddressString(addressString) { [weak self] placemarks, error in
                guard let self = self,
                      let location = placemarks?.first?.location else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    self.annotations = [MapAnnotation(coordinate: location.coordinate)]
                    self.selectedPlace = placemarks?.first
                }
            }
        }
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

    @MainActor
    private func onSelectedPlacemark(_ placemark: MKPlacemark, result: MKLocalSearchCompletion) {
        withAnimation { [weak self] in
            guard let self else { return }
            self.searchResults = []
            self.region = MKCoordinateRegion(
                center: placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            self.annotations = [MapAnnotation(coordinate: placemark.coordinate)]
            self.selectedPlace = placemark
        }
    }

    func updateFields(_ fields: inout AddressFormFields) {
        guard let place = selectedPlace else { return }

        fields.address1 = [place.subThoroughfare, place.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")

        fields.city = place.locality ?? ""
        fields.state = place.administrativeArea ?? ""
        fields.postcode = place.postalCode ?? ""
        fields.country = place.isoCountryCode ?? ""
    }

    deinit {
        searchCompleter.delegate = nil
    }
}

@available(iOS 17, *)
extension AddressMapPickerViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
