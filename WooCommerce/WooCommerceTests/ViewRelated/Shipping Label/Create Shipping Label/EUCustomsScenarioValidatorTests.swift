import XCTest
@testable import WooCommerce
@testable import Yosemite

final class EUCustomsScenarioValidatorTests: XCTestCase {

    func test_when_origin_country_is_US_and_destination_country_is_not_in_EU_new_custom_rules_then_return_false() {
        assertValidationFailsFor(origin: "US", destination: "BR")
        assertValidationFailsFor(origin: "USA", destination: "BR")
    }

    func test_when_origin_country_is_NOT_US_then_return_false() {
        assertValidationFailsFor(origin: "BR", destination: "AT")
    }

    func test_when_origin_country_is_US_and_destination_country_is_AT_and_AUT_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "AT")
        assertValidationSucceedsFor(origin: "US", destination: "AUT")
        assertValidationSucceedsFor(origin: "USA", destination: "AT")
        assertValidationSucceedsFor(origin: "USA", destination: "AUT")
    }

    func test_when_origin_country_is_US_and_destination_country_is_BE_and_BEL_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "BE")
        assertValidationSucceedsFor(origin: "US", destination: "BEL")
        assertValidationSucceedsFor(origin: "USA", destination: "BE")
        assertValidationSucceedsFor(origin: "USA", destination: "BEL")
    }

    func test_when_origin_country_is_US_and_destination_country_is_BG_and_BGR_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "BG")
        assertValidationSucceedsFor(origin: "US", destination: "BGR")
        assertValidationSucceedsFor(origin: "USA", destination: "BG")
        assertValidationSucceedsFor(origin: "USA", destination: "BGR")
    }

    func test_when_origin_country_is_US_and_destination_country_is_HR_and_HRV_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "HR")
        assertValidationSucceedsFor(origin: "US", destination: "HRV")
        assertValidationSucceedsFor(origin: "USA", destination: "HR")
        assertValidationSucceedsFor(origin: "USA", destination: "HRV")
    }

    func test_when_origin_country_is_US_and_destination_country_is_CY_and_CYP_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "CY")
        assertValidationSucceedsFor(origin: "US", destination: "CYP")
        assertValidationSucceedsFor(origin: "USA", destination: "CY")
        assertValidationSucceedsFor(origin: "USA", destination: "CYP")
    }

    func test_when_origin_country_is_US_and_destination_country_is_CZ_and_CZE_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "CZ")
        assertValidationSucceedsFor(origin: "US", destination: "CZE")
        assertValidationSucceedsFor(origin: "USA", destination: "CZ")
        assertValidationSucceedsFor(origin: "USA", destination: "CZE")
    }

    func test_when_origin_country_is_US_and_destination_country_is_DK_and_DNK_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "DK")
        assertValidationSucceedsFor(origin: "US", destination: "DNK")
        assertValidationSucceedsFor(origin: "USA", destination: "DK")
        assertValidationSucceedsFor(origin: "USA", destination: "DNK")
    }

    func test_when_origin_country_is_US_and_destination_country_is_EE_and_EST_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "EE")
        assertValidationSucceedsFor(origin: "US", destination: "EST")
        assertValidationSucceedsFor(origin: "USA", destination: "EE")
        assertValidationSucceedsFor(origin: "USA", destination: "EST")
    }

    func test_when_origin_country_is_US_and_destination_country_is_FI_and_FIN_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "FI")
        assertValidationSucceedsFor(origin: "US", destination: "FIN")
        assertValidationSucceedsFor(origin: "USA", destination: "FI")
        assertValidationSucceedsFor(origin: "USA", destination: "FIN")
    }

    func test_when_origin_country_is_US_and_destination_country_is_FR_and_FRA_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "FR")
        assertValidationSucceedsFor(origin: "US", destination: "FRA")
        assertValidationSucceedsFor(origin: "USA", destination: "FR")
        assertValidationSucceedsFor(origin: "USA", destination: "FRA")
    }

    func test_when_origin_country_is_US_and_destination_country_is_DE_and_DEU_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "DE")
        assertValidationSucceedsFor(origin: "US", destination: "DEU")
        assertValidationSucceedsFor(origin: "USA", destination: "DE")
        assertValidationSucceedsFor(origin: "USA", destination: "DEU")
    }

    func test_when_origin_country_is_US_and_destination_country_is_GR_and_GRC_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "GR")
        assertValidationSucceedsFor(origin: "US", destination: "GRC")
        assertValidationSucceedsFor(origin: "USA", destination: "GR")
        assertValidationSucceedsFor(origin: "USA", destination: "GRC")
    }

    func test_when_origin_country_is_US_and_destination_country_is_HU_and_HUN_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "HU")
        assertValidationSucceedsFor(origin: "US", destination: "HUN")
        assertValidationSucceedsFor(origin: "USA", destination: "HU")
        assertValidationSucceedsFor(origin: "USA", destination: "HUN")
    }

    func test_when_origin_country_is_US_and_destination_country_is_IE_and_IRL_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "IE")
        assertValidationSucceedsFor(origin: "US", destination: "IRL")
        assertValidationSucceedsFor(origin: "USA", destination: "IE")
        assertValidationSucceedsFor(origin: "USA", destination: "IRL")
    }

    func test_when_origin_country_is_US_and_destination_country_is_IT_and_ITA_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "IT")
        assertValidationSucceedsFor(origin: "US", destination: "ITA")
        assertValidationSucceedsFor(origin: "USA", destination: "IT")
        assertValidationSucceedsFor(origin: "USA", destination: "ITA")
    }

    func test_when_origin_country_is_US_and_destination_country_is_LV_and_LVA_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "LV")
        assertValidationSucceedsFor(origin: "US", destination: "LVA")
        assertValidationSucceedsFor(origin: "USA", destination: "LV")
        assertValidationSucceedsFor(origin: "USA", destination: "LVA")
    }

    func test_when_origin_country_is_US_and_destination_country_is_LT_and_LTU_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "LT")
        assertValidationSucceedsFor(origin: "US", destination: "LTU")
        assertValidationSucceedsFor(origin: "USA", destination: "LT")
        assertValidationSucceedsFor(origin: "USA", destination: "LTU")
    }

    func test_when_origin_country_is_US_and_destination_country_is_LU_and_LUX_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "LU")
        assertValidationSucceedsFor(origin: "US", destination: "LUX")
        assertValidationSucceedsFor(origin: "USA", destination: "LU")
        assertValidationSucceedsFor(origin: "USA", destination: "LUX")
    }

    func test_when_origin_country_is_US_and_destination_country_is_MT_and_MLT_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "MT")
        assertValidationSucceedsFor(origin: "US", destination: "MLT")
        assertValidationSucceedsFor(origin: "USA", destination: "MT")
        assertValidationSucceedsFor(origin: "USA", destination: "MLT")
    }

    func test_when_origin_country_is_US_and_destination_country_is_NL_and_NLD_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "NL")
        assertValidationSucceedsFor(origin: "US", destination: "NLD")
        assertValidationSucceedsFor(origin: "USA", destination: "NL")
        assertValidationSucceedsFor(origin: "USA", destination: "NLD")
    }

    func test_when_origin_country_is_US_and_destination_country_is_NO_and_NOR_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "NO")
        assertValidationSucceedsFor(origin: "US", destination: "NOR")
        assertValidationSucceedsFor(origin: "USA", destination: "NO")
        assertValidationSucceedsFor(origin: "USA", destination: "NOR")
    }

    func test_when_origin_country_is_US_and_destination_country_is_PL_and_POL_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "PL")
        assertValidationSucceedsFor(origin: "US", destination: "POL")
        assertValidationSucceedsFor(origin: "USA", destination: "PL")
        assertValidationSucceedsFor(origin: "USA", destination: "POL")
    }

    func test_when_origin_country_is_US_and_destination_country_is_PT_and_PRT_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "PT")
        assertValidationSucceedsFor(origin: "US", destination: "PRT")
        assertValidationSucceedsFor(origin: "USA", destination: "PT")
        assertValidationSucceedsFor(origin: "USA", destination: "PRT")
    }

    func test_when_origin_country_is_US_and_destination_country_is_RO_and_ROU_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "RO")
        assertValidationSucceedsFor(origin: "US", destination: "ROU")
        assertValidationSucceedsFor(origin: "USA", destination: "RO")
        assertValidationSucceedsFor(origin: "USA", destination: "ROU")
    }

    func test_when_origin_country_is_US_and_destination_country_is_SK_and_SVK_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "SK")
        assertValidationSucceedsFor(origin: "US", destination: "SVK")
        assertValidationSucceedsFor(origin: "USA", destination: "SK")
        assertValidationSucceedsFor(origin: "USA", destination: "SVK")
    }

    func test_when_origin_country_is_US_and_destination_country_is_SI_and_SVN_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "SI")
        assertValidationSucceedsFor(origin: "US", destination: "SVN")
        assertValidationSucceedsFor(origin: "USA", destination: "SI")
        assertValidationSucceedsFor(origin: "USA", destination: "SVN")
    }

    func test_when_origin_country_is_US_and_destination_country_is_ES_and_ESP_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "ES")
        assertValidationSucceedsFor(origin: "US", destination: "ESP")
        assertValidationSucceedsFor(origin: "USA", destination: "ES")
        assertValidationSucceedsFor(origin: "USA", destination: "ESP")
    }

    func test_when_origin_country_is_US_and_destination_country_is_SE_and_SWE_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "SE")
        assertValidationSucceedsFor(origin: "US", destination: "SWE")
        assertValidationSucceedsFor(origin: "USA", destination: "SE")
        assertValidationSucceedsFor(origin: "USA", destination: "SWE")
    }

    func test_when_origin_country_is_US_and_destination_country_is_CH_and_CHE_then_return_true() {
        assertValidationSucceedsFor(origin: "US", destination: "CH")
        assertValidationSucceedsFor(origin: "US", destination: "CHE")
        assertValidationSucceedsFor(origin: "USA", destination: "CH")
        assertValidationSucceedsFor(origin: "USA", destination: "CHE")
    }

    private func assertValidationSucceedsFor(origin: String, destination: String) {
        // Given
        let originAddress = createShippingLabelAddressWith(country: origin)
        let destinationAddress = createShippingLabelAddressWith(country: destination)

        // When
        let result = EUCustomsScenarioValidator.validate(origin: originAddress, destination: destinationAddress)

        // Then
        XCTAssertTrue(result)
    }

    private func assertValidationFailsFor(origin: String, destination: String) {
        // Given
        let originAddress = createShippingLabelAddressWith(country: origin)
        let destinationAddress = createShippingLabelAddressWith(country: destination)

        // When
        let result = EUCustomsScenarioValidator.validate(origin: originAddress, destination: destinationAddress)

        // Then
        XCTAssertFalse(result)
    }

    private func createShippingLabelAddressWith(country: String) -> ShippingLabelAddress {
        ShippingLabelAddress(company: "", name: "", phone: "", country: country, state: "", address1: "", address2: "", city: "", postcode: "")
    }
}
