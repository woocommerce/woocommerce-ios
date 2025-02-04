import Combine
import MapKit
import Observation
import SwiftUI

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
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

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
    }

    private func debounceSearch() {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create a new search task
        searchTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(300))
                
                // Check if the task was cancelled during the sleep
                try Task.checkCancellation()
                
                if searchQuery.isEmpty {
                    searchResults = []
                } else {
                    searchCompleter.queryFragment = searchQuery
                }
            } catch {
                // Task was cancelled or other error occurred
                return
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
