import Testing
import UIKit
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider
@testable import WooCommerce

@MainActor
struct ProductFormSettingsRowActionHandlerTests {
    @Test func test_actionable_rows_when_handled_then_log_and_navigate_in_existing_order() {
        // Given
        let scenarios: [(row: ProductFormSection.SettingsRow, calls: [String])] = [
            (.price(viewModel: rowViewModel(), isEditable: true), ["event:price", "navigate:price"]),
            (.customFields(viewModel: rowViewModel()), analyticsScenario(.productDetailCustomFieldsTapped, destination: "customFields")),
            (.reviews(viewModel: rowViewModel(), ratingCount: 0, averageRating: ""),
             analyticsScenario(.productDetailViewReviewsTapped, destination: "reviews")),
            (.downloadableFiles(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewDownloadableFilesTapped, destination: "downloadableFiles")),
            (.linkedProducts(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewLinkedProductsTapped, destination: "linkedProducts")),
            (.productType(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewProductTypeTapped, destination: "productType")),
            (.shipping(viewModel: rowViewModel(), isEditable: true), ["event:shipping", "navigate:shipping"]),
            (.inventory(viewModel: rowViewModel(), isEditable: true), ["event:inventory", "navigate:inventory"]),
            (.addOns(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewProductAddOnsTapped, destination: "addOns")),
            (.categories(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewCategoriesTapped, destination: "categories")),
            (.tags(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewTagsTapped, destination: "tags")),
            (.shortDescription(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewShortDescriptionTapped, destination: "shortDescription")),
            (.externalURL(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewExternalProductLinkTapped, destination: "externalURL")),
            (.simplifiedInventory(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewSKUTapped, destination: "simplifiedInventory")),
            (.groupedProducts(viewModel: rowViewModel(), isEditable: true),
             analyticsScenario(.productDetailViewGroupedProductsTapped, destination: "groupedProducts")),
            (.variations(viewModel: rowViewModel()),
             analyticsScenario(.productDetailViewVariationsTapped, destination: "variations")),
            (.noPriceWarning(viewModel: warningViewModel()),
             analyticsScenario(.productDetailViewVariationsTapped, destination: "variations")),
            (.attributes(viewModel: rowViewModel(), isEditable: true), ["navigate:attributes"]),
            (.bundledProducts(viewModel: rowViewModel(), isActionable: true),
             analyticsScenario(.productDetailViewBundledProductsTapped, destination: "bundledProducts")),
            (.components(viewModel: rowViewModel(), isActionable: true),
             analyticsScenario(.productDetailViewComponentsTapped, destination: "components")),
            (.subscriptionFreeTrial(viewModel: rowViewModel(), isEditable: true),
             ["event:subscriptionFreeTrial", "navigate:subscriptionFreeTrial"]),
            (.subscriptionExpiry(viewModel: rowViewModel(), isEditable: true),
             ["event:subscriptionExpiry", "navigate:subscriptionExpiry"]),
            (.quantityRules(viewModel: rowViewModel()), ["event:quantityRules", "navigate:quantityRules"])
        ]

        for scenario in scenarios {
            let recorder = CallRecorder()
            let navigator = MockNavigator(recorder: recorder)
            let handler = makeHandler(recorder: recorder, navigator: navigator)

            // When
            handler.handle(scenario.row, sourceView: UIView(), productID: 123)

            // Then
            #expect(recorder.calls == scenario.calls)
        }
    }

    @Test func test_non_actionable_rows_when_handled_then_do_not_log_or_navigate() {
        // Given
        let rows: [ProductFormSection.SettingsRow] = [
            .price(viewModel: rowViewModel(), isEditable: false),
            .downloadableFiles(viewModel: rowViewModel(), isEditable: false),
            .linkedProducts(viewModel: rowViewModel(), isEditable: false),
            .productType(viewModel: rowViewModel(), isEditable: false),
            .shipping(viewModel: rowViewModel(), isEditable: false),
            .inventory(viewModel: rowViewModel(), isEditable: false),
            .addOns(viewModel: rowViewModel(), isEditable: false),
            .categories(viewModel: rowViewModel(), isEditable: false),
            .tags(viewModel: rowViewModel(), isEditable: false),
            .shortDescription(viewModel: rowViewModel(), isEditable: false),
            .externalURL(viewModel: rowViewModel(), isEditable: false),
            .simplifiedInventory(viewModel: rowViewModel(), isEditable: false),
            .groupedProducts(viewModel: rowViewModel(), isEditable: false),
            .variations(viewModel: rowViewModel(isActionable: false)),
            .noPriceWarning(viewModel: warningViewModel(isActionable: false)),
            .attributes(viewModel: rowViewModel(), isEditable: false),
            .bundledProducts(viewModel: rowViewModel(), isActionable: false),
            .components(viewModel: rowViewModel(), isActionable: false),
            .subscriptionFreeTrial(viewModel: rowViewModel(), isEditable: false),
            .subscriptionExpiry(viewModel: rowViewModel(), isEditable: false),
            .status(viewModel: switchableViewModel(), isEditable: true),
            .noVariationsWarning(viewModel: warningViewModel())
        ]
        let recorder = CallRecorder()
        let navigator = MockNavigator(recorder: recorder)
        let handler = makeHandler(recorder: recorder, navigator: navigator)

        // When
        rows.forEach { handler.handle($0, sourceView: nil, productID: 123) }

        // Then
        #expect(recorder.calls.isEmpty)
    }

    @Test func test_product_type_when_handled_then_forwards_source_view() {
        // Given
        let sourceView = UIView()
        let recorder = CallRecorder()
        let navigator = MockNavigator(recorder: recorder)
        let handler = makeHandler(recorder: recorder, navigator: navigator)

        // When
        handler.handle(.productType(viewModel: rowViewModel(), isEditable: true), sourceView: sourceView, productID: 123)

        // Then
        #expect(navigator.productTypeSourceView === sourceView)
    }

    @Test func test_add_ons_when_handled_then_tracks_product_id() {
        // Given
        let recorder = CallRecorder()
        let analytics = RecordingAnalytics(recorder: recorder)
        let navigator = MockNavigator(recorder: recorder)
        let handler = makeHandler(recorder: recorder, navigator: navigator, analytics: analytics)

        // When
        handler.handle(.addOns(viewModel: rowViewModel(), isEditable: true), sourceView: nil, productID: 123)

        // Then
        #expect(analytics.lastProperties?["product_id"] as? String == "123")
    }
}

private extension ProductFormSettingsRowActionHandlerTests {
    func rowViewModel(isActionable: Bool = true) -> ProductFormSection.SettingsRow.ViewModel {
        .init(icon: .product, title: nil, details: nil, isActionable: isActionable)
    }

    func warningViewModel(isActionable: Bool = true) -> ProductFormSection.SettingsRow.WarningViewModel {
        .init(icon: .information, title: nil, isActionable: isActionable)
    }

    func switchableViewModel() -> ProductFormSection.SettingsRow.SwitchableViewModel {
        .init(viewModel: rowViewModel(), isSwitchOn: false, isActionable: true)
    }

    func analyticsScenario(_ stat: WooAnalyticsStat, destination: String) -> [String] {
        ["analytics:\(stat.rawValue)", "navigate:\(destination)"]
    }

    func makeHandler(recorder: CallRecorder,
                     navigator: MockNavigator,
                     analytics: RecordingAnalytics? = nil) -> ProductFormSettingsRowActionHandler {
        ProductFormSettingsRowActionHandler(navigator: navigator,
                                            eventLogger: MockEventLogger(recorder: recorder),
                                            analytics: analytics ?? RecordingAnalytics(recorder: recorder))
    }
}

private final class CallRecorder {
    var calls: [String] = []
}

@MainActor
private final class MockNavigator: ProductFormNavigating {
    private let recorder: CallRecorder
    private(set) weak var productTypeSourceView: UIView?

    init(recorder: CallRecorder) {
        self.recorder = recorder
    }

    func navigate(to destination: ProductFormDestination) {
        let name: String
        switch destination {
        case .privacySettings: name = "privacySettings"
        case .productDescription: name = "productDescription"
        case .blaze: name = "blaze"
        case .reloadLinkedProductsPromo: name = "reloadLinkedProductsPromo"
        case .descriptionAI: name = "descriptionAI"
        case .aiLegalPage: name = "aiLegalPage"
        case .productNameChanged: name = "productNameChanged"
        case .productStatusChanged: name = "productStatusChanged"
        case .productImages: name = "productImages"
        case .imageUploadFailure: name = "imageUploadFailure"
        case .price: name = "price"
        case .customFields: name = "customFields"
        case .reviews: name = "reviews"
        case .downloadableFiles: name = "downloadableFiles"
        case .linkedProducts: name = "linkedProducts"
        case .productType(let sourceView):
            name = "productType"
            productTypeSourceView = sourceView
        case .shipping: name = "shipping"
        case .inventory: name = "inventory"
        case .addOns: name = "addOns"
        case .categories: name = "categories"
        case .tags: name = "tags"
        case .shortDescription: name = "shortDescription"
        case .externalURL: name = "externalURL"
        case .simplifiedInventory: name = "simplifiedInventory"
        case .groupedProducts: name = "groupedProducts"
        case .variations: name = "variations"
        case .attributes: name = "attributes"
        case .bundledProducts: name = "bundledProducts"
        case .components: name = "components"
        case .subscriptionFreeTrial: name = "subscriptionFreeTrial"
        case .subscriptionExpiry: name = "subscriptionExpiry"
        case .quantityRules: name = "quantityRules"
        case .addAttribute: name = "addAttribute"
        }
        recorder.calls.append("navigate:\(name)")
    }
}

private final class MockEventLogger: ProductFormEventLoggerProtocol {
    private let recorder: CallRecorder

    init(recorder: CallRecorder) {
        self.recorder = recorder
    }

    func logPriceSettingsTapped() { recorder.calls.append("event:price") }
    func logInventorySettingsTapped() { recorder.calls.append("event:inventory") }
    func logShippingSettingsTapped() { recorder.calls.append("event:shipping") }
    func logQuantityRulesTapped() { recorder.calls.append("event:quantityRules") }
    func logSubscriptionsFreeTrialTapped() { recorder.calls.append("event:subscriptionFreeTrial") }
    func logSubscriptionsExpirationDateTapped() { recorder.calls.append("event:subscriptionExpiry") }
    func logDescriptionTapped() {}
    func logImageTapped() {}
    func logUpdateButtonTapped() {}
    func logQuantityRulesDoneButtonTapped(hasUnsavedChanges: Bool) {}
}

private final class RecordingAnalytics: Analytics, @unchecked Sendable {
    private let recorder: CallRecorder
    private(set) var lastProperties: [AnyHashable: Any]?
    var userHasOptedIn = true
    let analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()

    init(recorder: CallRecorder) {
        self.recorder = recorder
    }

    func track(_ eventName: String, properties: [AnyHashable: Any]?, error: Error?) {
        lastProperties = properties
        recorder.calls.append("analytics:\(eventName)")
    }

    func initialize() {}
    func refreshUserData() {}
    func setUserHasOptedOut(_ optedOut: Bool) { userHasOptedIn = !optedOut }
}
