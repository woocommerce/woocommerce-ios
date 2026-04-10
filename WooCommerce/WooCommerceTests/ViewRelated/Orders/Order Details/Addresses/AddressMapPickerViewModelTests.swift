import Testing
import MapKit
import Contacts
import Yosemite
@testable import WooCommerce

struct AddressMapPickerViewModelTests {
    private let mockCountryByCode: (String) -> Country?

    init() {
        mockCountryByCode = { countryCode in
            switch countryCode {
            case "US":
                return Country(code: "US", name: "USA", states: [
                    StateOfACountry(code: "CA", name: "Cali")
                ])
            default:
                return nil
            }
        }
    }

    // MARK: - Initialization Tests
    @Test func initialization_with_empty_fields_sets_properties_with_default_values() {
        // Given
        let emptyFields = AddressFormFields()

        // When
        let sut = AddressMapPickerViewModel(fields: emptyFields, countryByCode: mockCountryByCode)

        // Then
        #expect(sut.searchResults.isEmpty)
        #expect(sut.annotations.isEmpty)
        #expect(!sut.hasValidSelection)
    }

    // MARK: - Selection Tests

    @Test func selectLocation_updates_annotations_and_hasValidSelection() async {
        // Given
        let fields = AddressFormFields()
        let mockSearchProvider = MockAddressMapLocalSearchProvider.withBasicCoordinates()
        let sut = AddressMapPickerViewModel(fields: fields, countryByCode: mockCountryByCode, searchProvider: mockSearchProvider)
        let searchCompletion = MockMKLocalSearchCompletion()

        // When
        await sut.selectLocation(searchCompletion)

        // Then
        #expect(sut.annotations.count == 1)
        #expect(sut.hasValidSelection == true)
    }

    // MARK: - Address Field Updates Tests

    @Test func updateFields_with_no_selected_place_does_not_modify_fields() {
        // Given
        let sut = AddressMapPickerViewModel(fields: .init(), countryByCode: mockCountryByCode)
        var updatedFields = AddressFormFields()
        updatedFields.address1 = "Original Address"
        updatedFields.city = "Original City"

        // When
        sut.updateFields(&updatedFields)

        // Then
        #expect(updatedFields.address1 == "Original Address")
        #expect(updatedFields.city == "Original City")
    }

    @Test func updateFields_when_country_not_found_in_countryByCode_sets_country_and_state_as_strings() async {
        // Given
        let mockSearchProvider = MockAddressMapLocalSearchProvider.withFrenchAddress()
        let sut = AddressMapPickerViewModel(fields: .init(), countryByCode: mockCountryByCode, searchProvider: mockSearchProvider)
        let searchCompletion = MockMKLocalSearchCompletion()

        await sut.selectLocation(searchCompletion)

        // When
        var updatedFields = AddressFormFields()
        sut.updateFields(&updatedFields)

        // Then
        #expect(updatedFields.address1 == "Tour Eiffel")
        #expect(updatedFields.city == "Paris")
        #expect(updatedFields.postcode == "75007")
        #expect(updatedFields.country == "FR")
        #expect(updatedFields.state == "Île-de-France")
        #expect(updatedFields.selectedCountry == nil) // Country is not found in countryByCode dictionary
        #expect(updatedFields.selectedState == nil)
    }

   @Test func updateFields_when_country_is_found_in_countryByCode_sets_selected_country_and_state() async {
       // Given
       let mockSearchProvider = MockAddressMapLocalSearchProvider.withUSAddress()
       let sut = AddressMapPickerViewModel(fields: .init(), countryByCode: mockCountryByCode, searchProvider: mockSearchProvider)
       let searchCompletion = MockMKLocalSearchCompletion()

       await sut.selectLocation(searchCompletion)

       // When
       var updatedFields = AddressFormFields()
       sut.updateFields(&updatedFields)

       // Then
       #expect(updatedFields.address1 == "1 Apple Park Way")
       #expect(updatedFields.city == "Cupertino")
       #expect(updatedFields.postcode == "95014")
       #expect(updatedFields.country == "USA")
       #expect(updatedFields.state == "Cali")
       #expect(updatedFields.selectedCountry?.code == "US")
       #expect(updatedFields.selectedState?.code == "CA")
   }
}

// MARK: - Mock Classes

final private class MockMKLocalSearchCompletion: MKLocalSearchCompletion {}

final private class MockAddressMapLocalSearchProvider: AddressMapLocalSearchProviding {
    private let mockPlacemark: MKPlacemark

    init(mockPlacemark: MKPlacemark) {
        self.mockPlacemark = mockPlacemark
    }

    func search(for completion: MKLocalSearchCompletion) async throws -> MKLocalSearch.Response {
        let mockMapItem = MKMapItem(placemark: mockPlacemark)
        let mockResponse = MockMKLocalSearchResponse(mapItems: [mockMapItem])
        return mockResponse
    }
}

final private class MockMKLocalSearchResponse: MKLocalSearch.Response {
    private let _mapItems: [MKMapItem]

    init(mapItems: [MKMapItem]) {
        self._mapItems = mapItems
        super.init()
    }

    override var mapItems: [MKMapItem] { _mapItems }
}

private extension MockAddressMapLocalSearchProvider {
    static func withFrenchAddress() -> MockAddressMapLocalSearchProvider {
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = "Tour Eiffel"
        postalAddress.city = "Paris"
        postalAddress.postalCode = "75007"
        postalAddress.country = "France"
        postalAddress.isoCountryCode = "FR"
        postalAddress.state = "Île-de-France"

        let placemark = MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
            postalAddress: postalAddress
        )

        return MockAddressMapLocalSearchProvider(mockPlacemark: placemark)
    }

    static func withUSAddress() -> MockAddressMapLocalSearchProvider {
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = "1 Apple Park Way"
        postalAddress.city = "Cupertino"
        postalAddress.postalCode = "95014"
        postalAddress.country = "United States"
        postalAddress.isoCountryCode = "US"
        postalAddress.state = "CA"

        let placemark = MKPlacemark(
            coordinate: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            postalAddress: postalAddress
        )

        return MockAddressMapLocalSearchProvider(mockPlacemark: placemark)
    }

    static func withBasicCoordinates() -> MockAddressMapLocalSearchProvider {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
        return MockAddressMapLocalSearchProvider(mockPlacemark: placemark)
    }
}
