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
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("hi:11.3005.02-")

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "11.30")
        XCTAssertTrue(viewModel.enableDoneButton)
    }

    func test_view_model_formats_negative_amount_correctly() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("-hi:11.3005.02-")

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
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: customSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("12.203")

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "12,203")
        XCTAssertTrue(viewModel.formattableAmountViewModel.formattedAmount.contains("12,203"))
        XCTAssertEqual(viewModel.formattableAmountViewModel.formattedAmount.last, "£")
    }

    func test_view_model_prefills_input_data_correctly() {
        // Given
        let shippingMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
        insert(shippingMethod)
        let shippingLine = ShippingLine.fake().copy(shippingID: 1, methodTitle: "Flat Rate", methodID: shippingMethod.methodID, total: "$11.30")
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: shippingLine,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              storageManager: storageManager,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.selectedMethod, shippingMethod)
        XCTAssertEqual(viewModel.selectedMethodColor, Color(.text))
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "11.30")
        XCTAssertEqual(viewModel.methodTitle, shippingLine.methodTitle)
    }

    func test_view_model_prefills_negative_input_data_correctly() {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: 1, methodTitle: "Flat Rate", methodID: "", total: "-$11.30")
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: shippingLine,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // Then
        XCTAssertTrue(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "-11.30")
        XCTAssertEqual(viewModel.methodTitle, "Flat Rate")
    }

    func test_view_model_does_not_prefill_zero_amount_without_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingID: nil,
                                                              initialMethodID: "",
                                                              initialMethodTitle: "",
                                                              shippingTotal: "0",
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // Then
        XCTAssertTrue(viewModel.formattableAmountViewModel.amount.isEmpty)
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_amount_input() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.updateAmount("11.30")

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.updateAmount("")

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_amount_changes() {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: 1, methodTitle: "Flat Rate", methodID: "", total: "$11.30")
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: shippingLine,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.updateAmount("11.50")

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.formattableAmountViewModel.updateAmount("11.30")

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_method_title_changes() {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: 1, methodTitle: "Flat Rate", methodID: "", total: "$11.30")
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: shippingLine,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })
        XCTAssertFalse(viewModel.enableDoneButton)

        // When
        viewModel.methodTitle = "Shipping"

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)

        // When
        viewModel.methodTitle = shippingLine.methodTitle

        // Then
        XCTAssertFalse(viewModel.enableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_method_changes() {
        // Given
        let flatRateMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
        let localPickupMethod = ShippingMethod(siteID: sampleSiteID, methodID: "local_pickup", title: "Local pickup")
        insert([flatRateMethod, localPickupMethod])
        let shippingLine = ShippingLine.fake().copy(shippingID: 1, methodTitle: "Flat Rate", methodID: flatRateMethod.methodID, total: "$11.30")
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: shippingLine,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              storageManager: storageManager,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })
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
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        },
                                                              didSelectRemove: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("$11.30")
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
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        },
                                                              didSelectRemove: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("-11.30")
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
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        },
                                                              didSelectRemove: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("0")
        viewModel.saveData()

        // Then
        XCTAssertTrue(viewModel.enableDoneButton)
        XCTAssertEqual(savedShippingLine?.total, "0")
    }

    func test_view_model_creates_shippping_line_with_placeholder_for_method_title() {
        // Given
        var savedShippingLine: Yosemite.ShippingLine?
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { newShippingLine in
            savedShippingLine = newShippingLine
        },
                                                              didSelectRemove: { _ in })

        // When
        viewModel.formattableAmountViewModel.updateAmount("$11.30")
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
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // Then
        XCTAssertEqual(viewModel.formattableAmountViewModel.formattedAmount, "$0.00")
    }

    func test_view_model_initializes_correctly_with_no_existing_shipping_line() {
        // Given
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // Then
        XCTAssertFalse(viewModel.isExistingShippingLine)
        XCTAssertEqual(viewModel.selectedMethod.methodID, "")
        XCTAssertEqual(viewModel.selectedMethodColor, Color(.placeholderText))
        XCTAssertEqual(viewModel.formattableAmountViewModel.amount, "")
        XCTAssertEqual(viewModel.methodTitle, "")
    }

    func test_view_model_sets_expected_shipping_methods() {
        // Given
        let shippingMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
        insert(shippingMethod)
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              storageManager: storageManager,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // Then
        XCTAssertEqual(viewModel.shippingMethods.count, 3) // Placeholder method + provided method + "Other"
        XCTAssertTrue(viewModel.shippingMethods.contains(shippingMethod))
    }

    func test_view_model_tracks_selected_shipping_method() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: nil,
                                                              locale: usLocale,
                                                              storeCurrencySettings: usStoreSettings,
                                                              analytics: WooAnalytics(analyticsProvider: analytics),
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { _ in })

        // When
        let shippingMethod = ShippingMethod(siteID: sampleSiteID, methodID: "flat_rate", title: "Flat rate")
        viewModel.trackShippingMethodSelected(shippingMethod)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderShippingMethodSelected.rawValue])
        assertEqual(shippingMethod.methodID, analytics.receivedProperties.first?["shipping_method"] as? String)
    }

    func test_removeShippingLine_returns_shipping_line_with_expected_shipping_id() {
        // Given
        var removedShippingLine: Yosemite.ShippingLine?
        let existingShippingLine = ShippingLine.fake().copy(shippingID: 1)
        let viewModel = ShippingLineSelectionDetailsViewModel(siteID: sampleSiteID,
                                                              shippingLine: existingShippingLine,
                                                              didSelectSave: { _ in },
                                                              didSelectRemove: { shippingLine in
            removedShippingLine = shippingLine
        })

        // When
        viewModel.removeShippingLine()

        // Then
        assertEqual(existingShippingLine.shippingID, removedShippingLine?.shippingID)
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
