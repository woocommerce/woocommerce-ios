import Combine
import MapKit

@MainActor
class AddressMapPickerViewModel: NSObject, ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3361, longitude: -122.0380),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var annotations: [MapAnnotation] = []
    var showingSearchResults: Bool {
        searchResults.isEmpty == false
    }
    var hasValidSelection: Bool {
        selectedPlace != nil
    }

    private var selectedPlace: CLPlacemark?
    private let searchCompleter = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        searchCompleter.delegate = self

        // Start observing search query changes
        $searchQuery
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.searchResults = []
                } else {
                    self?.searchCompleter.queryFragment = query
                }
            }
            .store(in: &cancellables)

        // Request location authorization when needed
        let locationManager = CLLocationManager()
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

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
        self.searchResults = []
//        self.searchQuery = result.title
        self.region = MKCoordinateRegion(
            center: placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        self.annotations = [MapAnnotation(coordinate: placemark.coordinate)]
        self.selectedPlace = placemark
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

extension AddressMapPickerViewModel: MKLocalSearchCompleterDelegate {
    @MainActor
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
