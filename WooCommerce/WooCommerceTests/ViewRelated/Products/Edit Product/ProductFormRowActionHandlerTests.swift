import Testing
import UIKit
import Yosemite
import protocol WooFoundation.Analytics
@testable import WooCommerce

/// Tests for `ProductFormRowActionHandler`, the routing seam extracted from
/// `ProductFormViewController.tableView(_:didSelectRowAt:)`.
///
/// The handler operates on `ProductFormSection` rows, which are identical for `Product` and
/// `ProductVariation` (the concrete model only affects how the navigation destinations are built,
/// which is out of the handler's scope). Its behavior is therefore model-agnostic by construction
/// and a single suite covers both.
///
/// Coverage is exhaustive at the routing layer: every settings row, every primary-field row, and
/// every "Add more details" action is asserted for its guard, analytics, and navigation — this is
/// the completeness guarantee that live E2E (which is product-type-conditional) cannot give.
struct ProductFormRowActionHandlerTests {

    // MARK: - Settings rows — happy path (every case)

    @Test func every_settings_row_routes_navigation_and_analytics_correctly() {
        // Each case is exercised in its actionable/editable state and asserts the exact ordered
        // sequence of event-logger + navigation calls and the exact analytics events.
        let cases: [SettingsCase] = [
            .init("price",
                  .price(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["log:price", "editPriceSettings"], analytics: []),
            .init("customFields",
                  .customFields(viewModel: settingsViewModel()),
                  recorder: ["showCustomFields"], analytics: [stat(.productDetailCustomFieldsTapped)]),
            .init("reviews",
                  .reviews(viewModel: settingsViewModel(), ratingCount: 0, averageRating: ""),
                  recorder: ["showReviews"], analytics: [stat(.productDetailViewReviewsTapped)]),
            .init("productType",
                  .productType(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editProductType"], analytics: [stat(.productDetailViewProductTypeTapped)]),
            .init("shipping",
                  .shipping(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["log:shipping", "editShippingSettings"], analytics: []),
            .init("inventory",
                  .inventory(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["log:inventory", "editInventorySettings"], analytics: []),
            .init("addOns",
                  .addOns(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["navigateToAddOns"], analytics: [stat(.productDetailViewProductAddOnsTapped)]),
            .init("categories",
                  .categories(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editCategories"], analytics: [stat(.productDetailViewCategoriesTapped)]),
            .init("tags",
                  .tags(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editTags"], analytics: [stat(.productDetailViewTagsTapped)]),
            .init("shortDescription",
                  .shortDescription(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editShortDescription"], analytics: [stat(.productDetailViewShortDescriptionTapped)]),
            .init("externalURL",
                  .externalURL(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editExternalLink"], analytics: [stat(.productDetailViewExternalProductLinkTapped)]),
            .init("simplifiedInventory",
                  .simplifiedInventory(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editSimplifiedInventory"], analytics: [stat(.productDetailViewSKUTapped)]),
            .init("groupedProducts",
                  .groupedProducts(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editGroupedProducts"], analytics: [stat(.productDetailViewGroupedProductsTapped)]),
            .init("downloadableFiles",
                  .downloadableFiles(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["showDownloadableFiles"], analytics: [stat(.productDetailViewDownloadableFilesTapped)]),
            .init("linkedProducts",
                  .linkedProducts(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editLinkedProducts"], analytics: [stat(.productDetailViewLinkedProductsTapped)]),
            .init("variations",
                  .variations(viewModel: settingsViewModel(isActionable: true)),
                  recorder: ["showVariations"], analytics: [stat(.productDetailViewVariationsTapped)]),
            .init("noPriceWarning",
                  .noPriceWarning(viewModel: warningViewModel(isActionable: true)),
                  recorder: ["showVariations"], analytics: [stat(.productDetailViewVariationsTapped)]),
            .init("attributes",
                  .attributes(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["editAttributes"], analytics: []),
            .init("bundledProducts",
                  .bundledProducts(viewModel: settingsViewModel(), isActionable: true),
                  recorder: ["showBundledProducts"],
                  analytics: [WooAnalyticsEvent.ProductDetail.bundledProductsTapped().statName.rawValue]),
            .init("components",
                  .components(viewModel: settingsViewModel(), isActionable: true),
                  recorder: ["showCompositeComponents"],
                  analytics: [WooAnalyticsEvent.ProductDetail.componentsTapped().statName.rawValue]),
            .init("subscriptionFreeTrial",
                  .subscriptionFreeTrial(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["log:freeTrial", "showSubscriptionFreeTrialSettings"], analytics: []),
            .init("subscriptionExpiry",
                  .subscriptionExpiry(viewModel: settingsViewModel(), isEditable: true),
                  recorder: ["log:expiry", "showSubscriptionExpirySettings"], analytics: []),
            .init("quantityRules",
                  .quantityRules(viewModel: settingsViewModel()),
                  recorder: ["log:quantityRules", "showQuantityRules"], analytics: []),
            // Non-navigating rows.
            .init("status",
                  .status(viewModel: .init(viewModel: settingsViewModel(), isSwitchOn: true, isActionable: true), isEditable: true),
                  recorder: [], analytics: []),
            .init("noVariationsWarning",
                  .noVariationsWarning(viewModel: warningViewModel(isActionable: true)),
                  recorder: [], analytics: [])
        ]

        for testCase in cases {
            // Given
            let (handler, env) = makeHandler()

            // When
            handler.handleSettingsRowSelection(testCase.row, productID: 1, sourceView: nil)

            // Then
            #expect(env.recorder.events == testCase.expectedRecorder, "row: \(testCase.name)")
            #expect(env.analyticsProvider.receivedEvents == testCase.expectedAnalytics, "row: \(testCase.name)")
        }
    }

    // MARK: - Settings rows — guards (every guarded case is a no-op when blocked)

    @Test func every_guarded_settings_row_is_a_no_op_when_not_actionable() {
        // Rows blocked either by `isEditable: false` or `isActionable: false` must not log,
        // track, or navigate.
        let blockedRows: [(String, ProductFormSection.SettingsRow)] = [
            ("price", .price(viewModel: settingsViewModel(), isEditable: false)),
            ("productType", .productType(viewModel: settingsViewModel(), isEditable: false)),
            ("shipping", .shipping(viewModel: settingsViewModel(), isEditable: false)),
            ("inventory", .inventory(viewModel: settingsViewModel(), isEditable: false)),
            ("addOns", .addOns(viewModel: settingsViewModel(), isEditable: false)),
            ("categories", .categories(viewModel: settingsViewModel(), isEditable: false)),
            ("tags", .tags(viewModel: settingsViewModel(), isEditable: false)),
            ("shortDescription", .shortDescription(viewModel: settingsViewModel(), isEditable: false)),
            ("externalURL", .externalURL(viewModel: settingsViewModel(), isEditable: false)),
            ("simplifiedInventory", .simplifiedInventory(viewModel: settingsViewModel(), isEditable: false)),
            ("groupedProducts", .groupedProducts(viewModel: settingsViewModel(), isEditable: false)),
            ("downloadableFiles", .downloadableFiles(viewModel: settingsViewModel(), isEditable: false)),
            ("linkedProducts", .linkedProducts(viewModel: settingsViewModel(), isEditable: false)),
            ("attributes", .attributes(viewModel: settingsViewModel(), isEditable: false)),
            ("subscriptionFreeTrial", .subscriptionFreeTrial(viewModel: settingsViewModel(), isEditable: false)),
            ("subscriptionExpiry", .subscriptionExpiry(viewModel: settingsViewModel(), isEditable: false)),
            ("variations", .variations(viewModel: settingsViewModel(isActionable: false))),
            ("noPriceWarning", .noPriceWarning(viewModel: warningViewModel(isActionable: false))),
            ("bundledProducts", .bundledProducts(viewModel: settingsViewModel(), isActionable: false)),
            ("components", .components(viewModel: settingsViewModel(), isActionable: false))
        ]

        for (name, row) in blockedRows {
            // Given
            let (handler, env) = makeHandler()

            // When
            handler.handleSettingsRowSelection(row, productID: 1, sourceView: nil)

            // Then
            #expect(env.recorder.events.isEmpty, "row: \(name)")
            #expect(env.analyticsProvider.receivedEvents.isEmpty, "row: \(name)")
        }
    }

    @Test func settings_productType_forwards_source_view_anchor() {
        // Given
        let (handler, env) = makeHandler()
        let anchor = UIView()

        // When
        handler.handleSettingsRowSelection(.productType(viewModel: settingsViewModel(), isEditable: true),
                                           productID: 1,
                                           sourceView: anchor)

        // Then — the tapped cell is forwarded so the product-type selector popover can anchor to it.
        #expect(env.navigator.lastProductTypeSourceView === anchor)
    }

    @Test func settings_addOns_forwards_product_id_in_tracked_properties() {
        // Given
        let (handler, env) = makeHandler()

        // When
        handler.handleSettingsRowSelection(.addOns(viewModel: settingsViewModel(), isEditable: true),
                                           productID: 42,
                                           sourceView: nil)

        // Then
        #expect(env.analyticsProvider.receivedProperties.contains { properties in
            properties.values.contains { "\($0)" == "42" }
        })
    }

    // MARK: - Primary field rows (every actionable case)

    @Test func primary_description_respects_editability_and_logs_before_navigating() {
        // Given
        let (editableHandler, editableEnv) = makeHandler()
        let (blockedHandler, blockedEnv) = makeHandler()

        // When
        editableHandler.handlePrimaryFieldRowSelection(.description(description: "x", isEditable: true, isDescriptionAIEnabled: false),
                                                       shouldShowBlazeIntroView: false)
        blockedHandler.handlePrimaryFieldRowSelection(.description(description: "x", isEditable: false, isDescriptionAIEnabled: false),
                                                      shouldShowBlazeIntroView: false)

        // Then — editable logs then navigates; non-editable is a no-op.
        #expect(editableEnv.recorder.events == ["log:description", "editProductDescription"])
        #expect(blockedEnv.recorder.events.isEmpty)
        #expect(blockedEnv.analyticsProvider.receivedEvents.isEmpty)
    }

    @Test func primary_images_opens_privacy_settings_only_on_private_store() {
        // Given
        let (privateStoreHandler, privateStoreEnv) = makeHandler()
        let (publicStoreHandler, publicStoreEnv) = makeHandler()

        // When
        privateStoreHandler.handlePrimaryFieldRowSelection(
            .images(isEditable: true, isStorePublic: false, allowsMultiple: true, isVariation: false),
            shouldShowBlazeIntroView: false)
        publicStoreHandler.handlePrimaryFieldRowSelection(
            .images(isEditable: true, isStorePublic: true, allowsMultiple: true, isVariation: false),
            shouldShowBlazeIntroView: false)

        // Then — a private store's images row opens privacy settings; a public store's is not selectable.
        #expect(privateStoreEnv.recorder.events == ["openPrivacySettings"])
        #expect(publicStoreEnv.recorder.events.isEmpty)
    }

    @Test func primary_promoteWithBlaze_tracks_entry_point_only_when_intro_is_not_shown() {
        // Given
        let (introHandler, introEnv) = makeHandler()
        let (directHandler, directEnv) = makeHandler()

        // When
        introHandler.handlePrimaryFieldRowSelection(.promoteWithBlaze, shouldShowBlazeIntroView: true)
        directHandler.handlePrimaryFieldRowSelection(.promoteWithBlaze, shouldShowBlazeIntroView: false)

        // Then — the intro path navigates without tracking; the direct path tracks the entry-point event, then navigates.
        #expect(introEnv.recorder.events == ["displayBlaze"])
        #expect(introEnv.analyticsProvider.receivedEvents.isEmpty)
        #expect(directEnv.recorder.events == ["displayBlaze"])
        #expect(directEnv.analyticsProvider.receivedEvents ==
                [WooAnalyticsEvent.Blaze.blazeEntryPointTapped(source: .productDetailPromoteButton).statName.rawValue])
    }

    @Test func primary_non_actionable_rows_do_nothing() {
        // Rows handled by the `default` branch (name, variationName, descriptionAI, learnMoreAboutAI,
        // linkedProductsPromo, separator) are not row-selection actions.
        let (handler, env) = makeHandler()

        handler.handlePrimaryFieldRowSelection(.name(name: "n", isEditable: true, productStatus: .published),
                                               shouldShowBlazeIntroView: false)
        handler.handlePrimaryFieldRowSelection(.separator, shouldShowBlazeIntroView: false)

        #expect(env.recorder.events.isEmpty)
        #expect(env.analyticsProvider.receivedEvents.isEmpty)
    }

    // MARK: - "Add more details" bottom sheet (every action)

    @Test func every_more_details_action_routes_navigation_and_analytics_correctly() {
        let cases: [(String, ProductFormBottomSheetAction, [String], [String])] = [
            ("editInventorySettings", .editInventorySettings, ["log:inventory", "editInventorySettings"], []),
            ("editShippingSettings", .editShippingSettings, ["log:shipping", "editShippingSettings"], []),
            ("editCategories", .editCategories, ["editCategories"], [stat(.productDetailViewCategoriesTapped)]),
            ("editTags", .editTags, ["editTags"], [stat(.productDetailViewTagsTapped)]),
            ("editShortDescription", .editShortDescription, ["editShortDescription"], [stat(.productDetailViewShortDescriptionTapped)]),
            ("editSimplifiedInventory", .editSimplifiedInventory, ["editSimplifiedInventory"], [stat(.productDetailViewSKUTapped)]),
            ("editLinkedProducts", .editLinkedProducts, ["editLinkedProducts"], [stat(.productDetailViewLinkedProductsTapped)]),
            ("editReviews", .editReviews, ["showReviews"], [stat(.productDetailViewReviewsTapped)]),
            ("editDownloadableFiles", .editDownloadableFiles, ["showDownloadableFiles"], [stat(.productDetailViewDownloadableFilesTapped)]),
            ("editCustomFields", .editCustomFields, ["showCustomFields"], [])
        ]

        for (name, action, expectedRecorder, expectedAnalytics) in cases {
            // Given
            let (handler, env) = makeHandler()

            // When
            handler.handleMoreDetailsAction(action)

            // Then
            #expect(env.recorder.events == expectedRecorder, "action: \(name)")
            #expect(env.analyticsProvider.receivedEvents == expectedAnalytics, "action: \(name)")
        }
    }

    // MARK: - Inline cell actions

    @Test func addImageTapped_logs_then_navigates() {
        // Given
        let (handler, env) = makeHandler()

        // When
        handler.handleAddImageTapped()

        // Then
        #expect(env.recorder.events == ["log:image", "showProductImages"])
    }

    @Test func descriptionAITapped_navigates_without_tracking() {
        // Given
        let (handler, env) = makeHandler()

        // When
        handler.handleDescriptionAITapped()

        // Then
        #expect(env.recorder.events == ["showProductDescriptionAI"])
        #expect(env.analyticsProvider.receivedEvents.isEmpty)
    }

    @Test func linkedProductsPromoTapped_navigates_without_tracking() {
        // Given
        let (handler, env) = makeHandler()

        // When
        handler.handleLinkedProductsPromoTapped()

        // Then
        #expect(env.recorder.events == ["editLinkedProducts"])
        #expect(env.analyticsProvider.receivedEvents.isEmpty)
    }

    @Test func aiLegalPageTapped_navigates_without_tracking() {
        // Given
        let (handler, env) = makeHandler()

        // When
        handler.handleAILegalPageTapped(url: URL(string: "https://automattic.com/ai-guidelines/")!)

        // Then
        #expect(env.recorder.events == ["openAILegalPage"])
        #expect(env.analyticsProvider.receivedEvents.isEmpty)
    }
}

// MARK: - Test helpers

private extension ProductFormRowActionHandlerTests {
    struct SettingsCase {
        let name: String
        let row: ProductFormSection.SettingsRow
        let expectedRecorder: [String]
        let expectedAnalytics: [String]

        init(_ name: String,
             _ row: ProductFormSection.SettingsRow,
             recorder: [String],
             analytics: [String]) {
            self.name = name
            self.row = row
            self.expectedRecorder = recorder
            self.expectedAnalytics = analytics
        }
    }

    struct Environment {
        let recorder: Recorder
        let navigator: SpyProductFormNavigator
        let analyticsProvider: MockAnalyticsProvider
    }

    func makeHandler() -> (ProductFormRowActionHandler, Environment) {
        let recorder = Recorder()
        let navigator = SpyProductFormNavigator(recorder: recorder)
        let eventLogger = SpyProductFormEventLogger(recorder: recorder)
        let analyticsProvider = MockAnalyticsProvider()
        // Isolated opt-in defaults so events are not dropped by `WooAnalytics`'s opt-in gate,
        // regardless of the simulator's ambient analytics setting. The suite name is fixed and
        // wiped before use so runs don't accumulate persistent domains.
        let suiteName = "ProductFormRowActionHandlerTests"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults[.userOptedInAnalytics] = true
        let handler = ProductFormRowActionHandler(analytics: WooAnalytics(analyticsProvider: analyticsProvider,
                                                                          userDefaults: userDefaults),
                                                  eventLogger: eventLogger,
                                                  navigator: navigator)
        return (handler, Environment(recorder: recorder, navigator: navigator, analyticsProvider: analyticsProvider))
    }

    func settingsViewModel(isActionable: Bool = true) -> ProductFormSection.SettingsRow.ViewModel {
        .init(icon: UIImage(), title: "title", details: "details", isActionable: isActionable)
    }

    func warningViewModel(isActionable: Bool) -> ProductFormSection.SettingsRow.WarningViewModel {
        .init(icon: UIImage(), title: "title", isActionable: isActionable)
    }

    func stat(_ stat: WooAnalyticsStat) -> String {
        stat.rawValue
    }
}

/// Ordered sink shared by the navigator and event-logger spies so tests can assert the
/// guard → log → navigate sequence within a single `handle` call.
private final class Recorder {
    private(set) var events: [String] = []
    func record(_ event: String) {
        events.append(event)
    }
}

private final class SpyProductFormEventLogger: ProductFormEventLoggerProtocol {
    private let recorder: Recorder
    init(recorder: Recorder) {
        self.recorder = recorder
    }

    func logDescriptionTapped() { recorder.record("log:description") }
    func logImageTapped() { recorder.record("log:image") }
    func logPriceSettingsTapped() { recorder.record("log:price") }
    func logInventorySettingsTapped() { recorder.record("log:inventory") }
    func logShippingSettingsTapped() { recorder.record("log:shipping") }
    func logUpdateButtonTapped() { recorder.record("log:update") }
    func logQuantityRulesTapped() { recorder.record("log:quantityRules") }
    func logSubscriptionsFreeTrialTapped() { recorder.record("log:freeTrial") }
    func logSubscriptionsExpirationDateTapped() { recorder.record("log:expiry") }
    func logQuantityRulesDoneButtonTapped(hasUnsavedChanges: Bool) { recorder.record("log:quantityRulesDone") }
}

private final class SpyProductFormNavigator: ProductFormNavigating {
    private let recorder: Recorder
    private(set) var lastProductTypeSourceView: UIView?

    init(recorder: Recorder) {
        self.recorder = recorder
    }

    func openPrivacySettings() { recorder.record("openPrivacySettings") }
    func editProductDescription() { recorder.record("editProductDescription") }
    func showProductDescriptionAI() { recorder.record("showProductDescriptionAI") }
    func openAILegalPage(url: URL) { recorder.record("openAILegalPage") }
    func displayBlaze() { recorder.record("displayBlaze") }
    func showProductImages() { recorder.record("showProductImages") }
    func editPriceSettings() { recorder.record("editPriceSettings") }
    func showCustomFields() { recorder.record("showCustomFields") }
    func showReviews() { recorder.record("showReviews") }
    func showDownloadableFiles() { recorder.record("showDownloadableFiles") }
    func editLinkedProducts() { recorder.record("editLinkedProducts") }
    func editProductType(sourceView: UIView?) {
        lastProductTypeSourceView = sourceView
        recorder.record("editProductType")
    }
    func editShippingSettings() { recorder.record("editShippingSettings") }
    func editInventorySettings() { recorder.record("editInventorySettings") }
    func navigateToAddOns() { recorder.record("navigateToAddOns") }
    func editCategories() { recorder.record("editCategories") }
    func editTags() { recorder.record("editTags") }
    func editShortDescription() { recorder.record("editShortDescription") }
    func editExternalLink() { recorder.record("editExternalLink") }
    func editSimplifiedInventory() { recorder.record("editSimplifiedInventory") }
    func editGroupedProducts() { recorder.record("editGroupedProducts") }
    func showVariations() { recorder.record("showVariations") }
    func editAttributes() { recorder.record("editAttributes") }
    func showBundledProducts() { recorder.record("showBundledProducts") }
    func showCompositeComponents() { recorder.record("showCompositeComponents") }
    func showSubscriptionFreeTrialSettings() { recorder.record("showSubscriptionFreeTrialSettings") }
    func showSubscriptionExpirySettings() { recorder.record("showSubscriptionExpirySettings") }
    func showQuantityRules() { recorder.record("showQuantityRules") }
}
