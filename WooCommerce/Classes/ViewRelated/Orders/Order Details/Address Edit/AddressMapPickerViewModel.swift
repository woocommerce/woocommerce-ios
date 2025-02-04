import Combine
import MapKit
import Observation
import SwiftUI
import AsyncAlgorithms

@available(iOS 17, *)
@Observable
final class AddressMapPickerViewModel: NSObject {
    var searchQuery = "" {
        didSet {
            debounceSearch()
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

    private var selectedPlace: CLPlacemark?
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchStream: AsyncStream<String>?
    private var searchStreamContinuation: AsyncStream<String>.Continuation?
    private var searchTask: Task<Void, Never>?

    override init() {
        super.init()
        searchCompleter.resultTypes = .address
        searchCompleter.delegate = self

        // Request location authorization when needed
        let locationManager = CLLocationManager()
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }

        setupSearchStream()
    }

    private func setupSearchStream() {
        let (stream, continuation) = AsyncStream.makeStream(of: String.self)
        searchStream = stream
        searchStreamContinuation = continuation

        // Start processing the debounced search queries
        searchTask = Task {
            for await query in stream.debounce(for: .milliseconds(300)) {
                if Task.isCancelled { break }
                if query.isEmpty {
                    await MainActor.run {
                        searchResults = []
                    }
                } else {
                    await MainActor.run {
                        searchCompleter.queryFragment = query
                    }
                }
            }
        }
    }

    private func debounceSearch() {
        searchStreamContinuation?.yield(searchQuery)
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
        withAnimation {
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

    func cleanup() {
        searchTask?.cancel()
        searchTask = nil
        searchStreamContinuation?.finish()
        searchStreamContinuation = nil
        searchStream = nil
    }

    deinit {
        cleanup()
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
