import XCTest
import Foundation
@testable import WooCommerce
@testable import Storage
@testable import Yosemite

final class LocallyStoredStateNameRetrieverTests: XCTestCase {
    private var storageManager: MockStorageManager!
    private var sut: LocallyStoredStateNameRetriever!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()

        storageManager = MockStorageManager()
        sut = LocallyStoredStateNameRetriever(storageManager: storageManager)
    }

    override func tearDown() {
        storageManager = nil
    }

    func test_retrieveLocallyStoredStateName_when_there_are_no_data_stored_then_it_returns_nil() {
        // Given
        let address = Address.fake()

        // When/Then
        XCTAssertNil(sut.retrieveLocallyStoredStateName(of: address))
    }

    func test_retrieveLocallyStoredStateName_when_there_are_a_state_name_for_that_code_but_the_country_is_not_the_same_returns_nil() {
        // Given
        let stateCode = "TS"
        let address = Address.fake().copy(state: stateCode, country: "A different country")
        let stateOfACountry = StateOfACountry(code: stateCode, name: "Test State")
        storageManager.insertSampleCountries(readOnlyCountries: [Country(code: "US",
                                                                         name: "United States",
                                                                         states: [StateOfACountry(code: stateCode, name: "Testland")])])

        // When/Then
        XCTAssertNil(sut.retrieveLocallyStoredStateName(of: address))
    }

    func test_retrieveLocallyStoredStateName_when_there_are_a_state_name_for_that_code_and_the_country_is_the_same_returns_the_stored_name() {
        // Given
        let stateCode = "TS"
        let stateName = "Test State"
        let countryCode = "CNTR"
        let address = Address.fake().copy(state: stateCode, country: countryCode)
        let stateOfACountry = StateOfACountry(code: stateCode, name: stateName)
        storageManager.insertSampleCountries(readOnlyCountries: [Country(code: countryCode,
                                                                         name: "Test Land",
                                                                         states: [stateOfACountry])])

        // When/Then
        XCTAssertEqual(sut.retrieveLocallyStoredStateName(of: address), stateName)
    }
}
