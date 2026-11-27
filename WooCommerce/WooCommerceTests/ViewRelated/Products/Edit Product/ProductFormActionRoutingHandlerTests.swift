import Testing
import UIKit
import Yosemite
import protocol WooFoundation.Analytics
import protocol WooFoundation.AnalyticsProvider
@testable import WooCommerce

@MainActor
struct ProductFormActionRoutingHandlerTests {
    @Test func test_primary_rows_when_handled_then_preserve_guards_logging_and_navigation() {
        // Given
        let scenarios: [(row: ProductFormSection.PrimaryFieldRow, showsBlazeIntro: Bool, calls: [String])] = [
            (.images(isEditable: true, isStorePublic: false, allowsMultiple: true, isVariation: false),
             false,
             ["navigate:privacySettings"]),
            (.images(isEditable: true, isStorePublic: true, allowsMultiple: true, isVariation: false), false, []),
            (.description(description: nil, isEditable: false, isDescriptionAIEnabled: false), false, []),
            (.description(description: nil, isEditable: true, isDescriptionAIEnabled: false),
             false,
             ["event:description", "navigate:productDescription"]),
            (.promoteWithBlaze, false, ["analytics:blaze_entry_point_tapped", "navigate:blaze"]),
            (.promoteWithBlaze, true, ["navigate:blaze"])
        ]

        for scenario in scenarios {
            let recorder = RoutingCallRecorder()
            let navigator = RoutingMockNavigator(recorder: recorder)
            let handler = makeHandler(recorder: recorder, navigator: navigator)

            // When
            handler.handle(scenario.row, shouldShowBlazeIntroView: scenario.showsBlazeIntro)

            // Then
            #expect(recorder.calls == scenario.calls)
        }
    }

    @Test func test_inline_actions_when_handled_then_route_and_log() {
        // Given
        let recorder = RoutingCallRecorder()
        let navigator = RoutingMockNavigator(recorder: recorder)
        let handler = makeHandler(recorder: recorder, navigator: navigator)
        let url = URL(string: "https://woocommerce.com")!
        let asset = ProductImageAssetType.uiImage(image: UIImage(), filename: nil, altText: nil)
        let error = NSError(domain: "test", code: 1)

        // When
        handler.handle(.openLinkedProducts)
        handler.handle(.reloadLinkedProductsPromo)
        handler.handle(.descriptionAI)
        handler.handle(.openAILegalPage(url))
        handler.handle(.nameChanged("Name"))
        handler.handle(.statusChanged(true))
        handler.handle(.addImage)
        handler.handle(.failedImageUpload(asset: asset, error: error))

        // Then
        #expect(recorder.calls == [
            "navigate:linkedProducts",
            "navigate:reloadLinkedProductsPromo",
            "navigate:descriptionAI",
            "navigate:aiLegalPage",
            "navigate:productNameChanged",
            "navigate:productStatusChanged",
            "event:image",
            "navigate:productImages",
            "navigate:imageUploadFailure"
        ])
        #expect(navigator.legalPageURL == url)
        #expect(navigator.productName == "Name")
        #expect(navigator.productStatus == true)
        #expect(navigator.imageAsset == asset)
        #expect(navigator.imageError as NSError? == error)
    }

    @Test func test_bottom_sheet_actions_when_handled_then_log_and_navigate_in_existing_order() {
        // Given
        let scenarios: [(action: ProductFormBottomSheetAction, calls: [String])] = [
            (.editInventorySettings, ["event:inventory", "navigate:inventory"]),
            (.editShippingSettings, ["event:shipping", "navigate:shipping"]),
            (.editCategories, analyticsScenario(.productDetailViewCategoriesTapped, destination: "categories")),
            (.editTags, analyticsScenario(.productDetailViewTagsTapped, destination: "tags")),
            (.editShortDescription, analyticsScenario(.productDetailViewShortDescriptionTapped, destination: "shortDescription")),
            (.editSimplifiedInventory, analyticsScenario(.productDetailViewSKUTapped, destination: "simplifiedInventory")),
            (.editLinkedProducts, analyticsScenario(.productDetailViewLinkedProductsTapped, destination: "linkedProducts")),
            (.editReviews, analyticsScenario(.productDetailViewReviewsTapped, destination: "reviews")),
            (.editDownloadableFiles, analyticsScenario(.productDetailViewDownloadableFilesTapped, destination: "downloadableFiles")),
            (.editCustomFields, ["navigate:customFields"]),
            (.editAttributes, analyticsScenario(.addProductAttributeButtonTapped, destination: "addAttribute"))
        ]

        for scenario in scenarios {
            let recorder = RoutingCallRecorder()
            let navigator = RoutingMockNavigator(recorder: recorder)
            let handler = makeHandler(recorder: recorder, navigator: navigator)

            // When
            handler.handle(scenario.action, productID: 123)

            // Then
            #expect(recorder.calls == scenario.calls)
        }
    }

    @Test func test_add_attribute_when_handled_then_tracks_product_id() {
        // Given
        let recorder = RoutingCallRecorder()
        let analytics = RoutingRecordingAnalytics(recorder: recorder)
        let navigator = RoutingMockNavigator(recorder: recorder)
        let handler = makeHandler(recorder: recorder, navigator: navigator, analytics: analytics)

        // When
        handler.handle(.editAttributes, productID: 123)

        // Then
        #expect(analytics.lastProperties?["product_id"] as? String == "123")
    }
}

private extension ProductFormActionRoutingHandlerTests {
    func analyticsScenario(_ stat: WooAnalyticsStat, destination: String) -> [String] {
        ["analytics:\(stat.rawValue)", "navigate:\(destination)"]
    }

    func makeHandler(recorder: RoutingCallRecorder,
                     navigator: RoutingMockNavigator,
                     analytics: RoutingRecordingAnalytics? = nil) -> ProductFormActionRoutingHandler {
        ProductFormActionRoutingHandler(navigator: navigator,
                                        eventLogger: RoutingMockEventLogger(recorder: recorder),
                                        analytics: analytics ?? RoutingRecordingAnalytics(recorder: recorder))
    }
}

private final class RoutingCallRecorder {
    var calls: [String] = []
}

@MainActor
private final class RoutingMockNavigator: ProductFormNavigating {
    private let recorder: RoutingCallRecorder
    private(set) var legalPageURL: URL?
    private(set) var productName: String?
    private(set) var productStatus: Bool?
    private(set) var imageAsset: ProductImageAssetType?
    private(set) var imageError: Error?

    init(recorder: RoutingCallRecorder) {
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
        case .aiLegalPage(let url):
            name = "aiLegalPage"
            legalPageURL = url
        case .productNameChanged(let value):
            name = "productNameChanged"
            productName = value
        case .productStatusChanged(let value):
            name = "productStatusChanged"
            productStatus = value
        case .productImages: name = "productImages"
        case .imageUploadFailure(let asset, let error):
            name = "imageUploadFailure"
            imageAsset = asset
            imageError = error
        case .price: name = "price"
        case .customFields: name = "customFields"
        case .reviews: name = "reviews"
        case .downloadableFiles: name = "downloadableFiles"
        case .linkedProducts: name = "linkedProducts"
        case .productType: name = "productType"
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

private final class RoutingMockEventLogger: ProductFormEventLoggerProtocol {
    private let recorder: RoutingCallRecorder

    init(recorder: RoutingCallRecorder) {
        self.recorder = recorder
    }

    func logDescriptionTapped() { recorder.calls.append("event:description") }
    func logImageTapped() { recorder.calls.append("event:image") }
    func logInventorySettingsTapped() { recorder.calls.append("event:inventory") }
    func logShippingSettingsTapped() { recorder.calls.append("event:shipping") }
    func logPriceSettingsTapped() {}
    func logQuantityRulesTapped() {}
    func logSubscriptionsFreeTrialTapped() {}
    func logSubscriptionsExpirationDateTapped() {}
    func logUpdateButtonTapped() {}
    func logQuantityRulesDoneButtonTapped(hasUnsavedChanges: Bool) {}
}

private final class RoutingRecordingAnalytics: Analytics, @unchecked Sendable {
    private let recorder: RoutingCallRecorder
    private(set) var lastProperties: [AnyHashable: Any]?
    var userHasOptedIn = true
    let analyticsProvider: AnalyticsProvider = MockAnalyticsProvider()

    init(recorder: RoutingCallRecorder) {
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
