import XCTest
@testable import WooCommerce
import Yosemite

class ShippingLabelCustomsFormListViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    func test_done_button_is_enabled_when_all_fields_are_valid() {
        // Given
        let item = ShippingLabelCustomsForm.Item.fake().copy(quantity: 1)
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let customsForm = ShippingLabelCustomsForm(packageID: "Custom package", packageName: "Custom package", items: [item])

        // When
        let viewModel = ShippingLabelCustomsFormListViewModel(order: order,
                                                              customsForms: [customsForm],
                                                              destinationCountry: Country.fake(),
                                                              countries: [])

        let firstInputModel = viewModel.inputViewModels.first
        firstInputModel?.returnOnNonDelivery = true
        firstInputModel?.contentsType = .documents
        firstInputModel?.contentExplanation = ""
        firstInputModel?.restrictionType = .quarantine
        firstInputModel?.restrictionComments = ""
        firstInputModel?.itn = ""
        let firstItem = firstInputModel?.itemViewModels.first
        firstItem?.description = "Lorem Ipsum"
        firstItem?.value = "15"
        firstItem?.weight = "2.0"
        firstItem?.originCountry = Yosemite.Country(code: "VN", name: "Vietnam", states: [])
        firstItem?.hsTariffNumber = ""

        // Then
        XCTAssertTrue(viewModel.doneButtonEnabled)
    }

    func test_done_button_is_disable_when_not_all_fields_are_valid() {
        // Given
        let item = ShippingLabelCustomsForm.Item.fake().copy(quantity: 1)
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let customsForm = ShippingLabelCustomsForm(packageID: "Custom package", packageName: "Custom package", items: [item])

        // When
        let viewModel = ShippingLabelCustomsFormListViewModel(order: order,
                                                              customsForms: [customsForm],
                                                              destinationCountry: Country.fake(),
                                                              countries: [])

        let firstInputModel = viewModel.inputViewModels.first
        firstInputModel?.returnOnNonDelivery = true
        firstInputModel?.contentsType = .documents
        firstInputModel?.contentExplanation = ""
        firstInputModel?.restrictionType = .quarantine
        firstInputModel?.restrictionComments = ""
        // missing ITN when total value of tariff number 111111 is 2600
        firstInputModel?.itn = ""
        let firstItem = firstInputModel?.itemViewModels.first
        firstItem?.description = "Lorem Ipsum"
        firstItem?.value = "2600"
        firstItem?.weight = "2.0"
        firstItem?.originCountry = Yosemite.Country(code: "VN", name: "Vietnam", states: [])
        firstItem?.hsTariffNumber = "111111"

        // Then
        XCTAssertFalse(viewModel.doneButtonEnabled)
    }
}
