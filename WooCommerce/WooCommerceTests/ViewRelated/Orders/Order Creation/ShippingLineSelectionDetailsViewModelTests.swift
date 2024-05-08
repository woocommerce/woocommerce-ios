import XCTest
import Combine
import WooFoundation
import Yosemite
import Storage
import struct SwiftUI.Color
@testable import WooCommerce

final class ShippingLineSelectionDetailsViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345
    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    func test_view_model_formats_amount_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })

        // When
        viewModel.formattableAmountViewModel.amount = "hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "11.30")
        XCTAssertTrue(viewModel.enableDoneButton)
    }

    func test_view_model_formats_negative_amount_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })

        // When
        viewModel.formattableAmountViewModel.amount = "-hi:11.3005.02-"

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "-11.30")
        XCTAssertTrue(viewModel.enableDoneButton)
    }

    func test_view_model_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ".",
                                              decimalSeparator: ",",
                                              numberOfDecimals: 3)

        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: customSettings,
                                                              didSelectSave: { _ in })

        // When
        viewModel.formattableAmountViewModel.amount = "12.203"

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "12,203")
        XCTAssertTrue(viewModel.formattableAmountViewModel.formattedAmount.contains("12,203"))
        XCTAssertEqual(viewModel.formattableAmountViewModel.formattedAmount.last, "£")
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let shippingMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
        insert(shippingMethod)
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: true,
                                                              initialMethodID: shippingMethod.methodID,
                                                              initialMethodTitle: "Flat Rate",
                                                              shippingTotal: "$11.30",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              storageManager: storageManager,
                                                              didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.shippingMethods.count, 2) // Provided method + placeholder method
        XCTAssertEqual(viewModel.selectedMethod, shippingMethod)
        XCTAssertEqual(viewModel.selectedMethodColor, Color(.text))
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_prefills_negative_input_data_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: true,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "Flat Rate",
                                                              shippingTotal: "-$11.30",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "-11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_does_not_prefill_zero_amount_without_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "0",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })

        // Then
        XCTAssertTrue(viewModel.formattableAmountViewModel.amount.isEmpty)
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_amount_input() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = "11.30"

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = ""

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_amount_changes() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: true,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "Flat Rate",
                                                              shippingTotal: "$11.30",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = "11.50"

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.amount = "11.30"

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_method_title_changes() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: true,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "Flat Rate",
                                                              shippingTotal: "$11.30",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.methodTitle = "Shipping"

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.methodTitle = "Flat Rate"

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_method_changes() {
        // Given
        let flatRateMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
        let localPickupMethod = ShippingMethod(siteID: sampleSiteID, methodID: "local_pickup", title: "Local pickup")
        insert([flatRateMethod, localPickupMethod])
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: true,
                                                              initialMethodID: flatRateMethod.methodID,
                                                              initialMethodTitle: "Flat Rate",
                                                              shippingTotal: "$11.30",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              storageManager: storageManager,
                                                              didSelectSave: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.selectedMethod = localPickupMethod

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.selectedMethod = flatRateMethod

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_creates_shippping_line_with_data_from_fields() {
        // Given
        var savedShippingLine: Yosemite.ShippingLine?
        let shippingMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
        insert(shippingMethod)
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "$11.30"
        viewModel.methodTitle = "Flat Rate"
        viewModel.selectedMethod = shippingMethod
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedShippingLine?.total, "11.30")
        XCTAssertEqual(savedShippingLine?.methodTitle, "Flat Rate")
        XCTAssertEqual(savedShippingLine?.methodID, shippingMethod.methodID)
    }

    func test_view_model_creates_shippping_line_with_negative_data_from_fields() {
        // Given
        var savedShippingLine: Yosemite.ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "-11.30"
        viewModel.methodTitle = "Flat Rate"
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedShippingLine?.total, "-11.30")
        XCTAssertEqual(savedShippingLine?.methodTitle, "Flat Rate")
    }

    func test_view_model_allows_saving_zero_amount_and_creates_correct_shippping_line() {
        // Given
        var savedShippingLine: Yosemite.ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "0"
        viewModel.saveData()

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)
        XCTAssertEqual(savedShippingLine?.total, "0")
    }

    func test_view_model_creates_shippping_line_with_placeholder_for_method_title() {
        // Given
        var savedShippingLine: Yosemite.ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        })

        // When
        viewModel.formattableAmountViewModel.amount = "$11.30"
        viewModel.methodTitle = ""

        // Then
        viewModel.saveData()
        XCTAssertEqual(savedShippingLine?.total, "11.30")
        XCTAssertNotEqual(savedShippingLine?.methodTitle, "") // "Shipping" placeholder string is localized -> not reliable for comparison here.
        XCTAssertEqual(savedShippingLine?.methodID, "")
    }

    func test_view_model_amount_placeholder_has_expected_value() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.formattedAmount, "$0.00")
    }

    func test_view_model_initializes_correctly_with_no_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              isExistingShippingLine: false,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.shippingMethods.count, 1) // Placeholder method
        XCTAssertEqual(viewModel.selectedMethod.methodID, "")
        XCTAssertEqual(viewModel.selectedMethodColor, Color(.placeholderText))
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "")
        XCTAssertEqual(viewModel.methodTitle, "")
    }
}

private extension ShippingLineSelectionDetailsViewModelTests {
    func insert(_ readOnlyShippingMethod: Yosemite.ShippingMethod) {
        let shippingMethod = storage.insertNewObject(ofType: StorageShippingMethod.self)
        shippingMethod.update(with: readOnlyShippingMethod)
    }

    func insert(_ readOnlyShippingMethods: [Yosemite.ShippingMethod]) {
        readOnlyShippingMethods.forEach { readOnlyShippingMethod in
            insert(readOnlyShippingMethod)
        }
    }
}
