import Foundation
import Yosemite
import WooFoundation

/// This struct represents an analytics event. It is a combination of `WooAnalyticsStat` and
/// its properties.
///
/// This was mostly created to promote static-typing via constructors.
///
/// ## Adding New Events
///
/// 1. Add the event name (`String`) to `WooAnalyticsStat`.
/// 2. Create an `extension` of `WooAnalyticsStat` if necessary for grouping.
/// 3. Add a `static func` constructor.
///
/// Here is an example:
///
/// ~~~
/// extension WooAnalyticsEvent {
///     enum LoginStep: String {
///         case start
///         case success
///     }
///
///     static func login(step: LoginStep) -> WooAnalyticsEvent {
///         let properties = [
///             "step": step.rawValue
///         ]
///
///         return WooAnalyticsEvent(name: "login", properties: properties)
///     }
/// }
/// ~~~
///
/// Examples of tracking calls (in the client App or Pod):
///
/// ~~~
/// Analytics.track(event: .login(step: .start))
/// Analytics.track(event: .loginStart)
/// ~~~
///
struct WooAnalyticsEvent {
    init(statName: WooAnalyticsStat, properties: [String: WooAnalyticsEventPropertyType], error: Error? = nil) {
        self.statName = statName
        self.properties = properties
        self.error = error
    }

    let statName: WooAnalyticsStat
    let properties: [String: WooAnalyticsEventPropertyType]
    let error: Error?
}

// MARK: - In-app Feedback and Survey

extension WooAnalyticsEvent {

    /// The action performed on the In-app Feedback Card.
    public enum AppFeedbackPromptAction: String {
        case shown
        case liked
        case didntLike = "didnt_like"
    }

    /// Where the feedback was shown. This is shared by a couple of events.
    public enum FeedbackContext: String {
        /// Shown in Stats but is for asking general feedback.
        case general
        /// Shown in products banner for general feedback.
        case productsGeneral  = "products_general"
        /// Shown in shipping labels banner for Milestone 3 features.
        case shippingLabelsRelease3 = "shipping_labels_m3"
        /// Shown in beta feature banner for order add-ons.
        case addOnsI1 = "add-ons_i1"
        /// Shown in orders banner for order creation release.
        case orderCreation = "order_creation"
        /// Shown in beta feature banner for coupon management.
        case couponManagement = "coupon_management"
        /// Shown in store setup task list
        case storeSetup = "store_setup"
        /// Tap to Pay on iPhone feedback button shown in the Payments menu after the first payment with TTP
        case tapToPayFirstPaymentPaymentsMenu
        /// Shown in Product details form for a AI generated product
        case productCreationAI = "product_creation_ai"
        /// Shown in the order form after adding a shipping line
        case orderFormShippingLines = "order_form_shipping_lines"
    }

    /// The action performed on the survey screen.
    public enum SurveyScreenAction: String {
        case opened
        case canceled
        case completed
    }

    /// The action performed on "New Features" banners like in Products.
    public enum FeatureFeedbackBannerAction: String {
        case gaveFeedback = "gave_feedback"
        case dismissed
    }

    /// The action performed on a shipment tracking number like in a shipping label card in order details.
    public enum ShipmentTrackingMenuAction: String {
        case track
        case copy
    }

    /// The result of a shipping labels API GET request.
    public enum ShippingLabelsAPIRequestResult {
        case success
        case failed(error: Error)

        fileprivate var rawValue: String {
            switch self {
            case .success:
                return "success"
            case .failed:
                return "failed"
            }
        }
    }

    static func appFeedbackPrompt(action: AppFeedbackPromptAction) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .appFeedbackPrompt, properties: ["action": action.rawValue])
    }

    static func surveyScreen(context: FeedbackContext, action: SurveyScreenAction) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .surveyScreen, properties: ["context": context.rawValue, "action": action.rawValue])
    }

    static func featureFeedbackBanner(context: FeedbackContext, action: FeatureFeedbackBannerAction) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .featureFeedbackBanner, properties: ["context": context.rawValue, "action": action.rawValue])
    }

    static func shipmentTrackingMenu(action: ShipmentTrackingMenuAction) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .shipmentTrackingMenuAction, properties: ["action": action.rawValue])
    }

    static func shippingLabelsAPIRequest(result: ShippingLabelsAPIRequestResult) -> WooAnalyticsEvent {
        switch result {
        case .success:
            return WooAnalyticsEvent(statName: .shippingLabelsAPIRequest, properties: ["action": result.rawValue])
        case .failed(let error):
            return WooAnalyticsEvent(statName: .shippingLabelsAPIRequest, properties: [
                "action": result.rawValue,
                "error": error.localizedDescription
            ])
        }
    }

    static func ordersListLoaded(totalDuration: TimeInterval,
                                 pageNumber: Int,
                                 filters: FilterOrderListViewModel.Filters?,
                                 totalCompletedOrders: Int?) -> WooAnalyticsEvent {
        let properties: [String: WooAnalyticsEventPropertyType?] = [
            "status": (filters?.orderStatus ?? []).map { $0.rawValue }.joined(separator: ","),
            "page_number": Int64(pageNumber),
            "total_duration": Double(totalDuration),
            "date_range": filters?.dateRange?.analyticsDescription ?? String(),
            "total_completed_orders": totalCompletedOrders
        ]
        return WooAnalyticsEvent(statName: .ordersListLoaded, properties: properties.compactMapValues { $0 })
    }

    static func ordersListLoadError(_ error: Error) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .ordersListLoadError, properties: [:], error: error)
    }
}


// MARK: - Issue Refund
//
extension WooAnalyticsEvent {
    // Namespace
    enum IssueRefund {
        /// The state of the "refund shipping" button
        enum ShippingSwitchState: String {
            case on
            case off
        }

        // The method used for the refund
        enum RefundMethod: String {
            case items = "ITEMS"
            case amount = "AMOUNT"
        }

        static func createRefund(orderID: Int64, fullyRefunded: Bool, method: RefundMethod, gateway: String, amount: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .refundCreate, properties: [
                "order_id": "\(orderID)",
                "is_full": "\(fullyRefunded)",
                "method": method.rawValue,
                "gateway": gateway,
                "amount": amount
            ])
        }

        static func createRefundSuccess(orderID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .refundCreateSuccess, properties: ["order_id": "\(orderID)"])
        }

        static func createRefundFailed(orderID: Int64, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .refundCreateFailed, properties: [
                "order_id": "\(orderID)",
                "error_description": error.localizedDescription,
            ])
        }

        static func selectAllButtonTapped(orderID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createOrderRefundSelectAllItemsButtonTapped, properties: ["order_id": "\(orderID)"])
        }

        static func quantityDialogOpened(orderID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createOrderRefundItemQuantityDialogOpened, properties: ["order_id": "\(orderID)"])
        }

        static func nextButtonTapped(orderID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createOrderRefundNextButtonTapped, properties: ["order_id": "\(orderID)"])
        }

        static func summaryButtonTapped(orderID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createOrderRefundSummaryRefundButtonTapped, properties: ["order_id": "\(orderID)"])
        }

        static func shippingSwitchTapped(orderID: Int64, state: ShippingSwitchState) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createOrderRefundShippingOptionTapped, properties: ["order_id": "\(orderID)", "action": state.rawValue])
        }
    }
}

// MARK: - Variations
//
extension WooAnalyticsEvent {
    // Namespace
    enum Variations {
        /// Common event keys
        ///
        private enum Keys {
            static let productID = "product_id"
            static let variationID = "product_variation_id"
            static let serverTime = "time"
            static let errorDescription = "error_description"
            static let field = "field"
            static let variationsCount = "variations_count"
            static let hasChangedData = "has_changed_data"
        }

        enum BulkUpdateField: String {
            case regularPrice = "regular_price"
        }

        static func addFirstVariationButtonTapped(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addFirstVariationButtonTapped, properties: [Keys.productID: "\(productID)"])
        }

        static func addMoreVariationsButtonTapped(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addMoreVariationsButtonTapped, properties: [Keys.productID: "\(productID)"])
        }

        static func createVariation(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createProductVariation, properties: [Keys.productID: "\(productID)"])
        }

        static func createVariationSuccess(productID: Int64, time: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createProductVariationSuccess, properties: [Keys.productID: "\(productID)", Keys.serverTime: "\(time)"])
        }

        static func createVariationFail(productID: Int64, time: Double, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .createProductVariationFailed, properties: [Keys.productID: "\(productID)",
                                                                                    Keys.serverTime: "\(time)",
                                                                                    Keys.errorDescription: error.localizedDescription])
        }

        static func removeVariationButtonTapped(productID: Int64, variationID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .removeProductVariationButtonTapped, properties: [Keys.productID: "\(productID)", Keys.variationID: "\(variationID)"])
        }

        static func editAttributesButtonTapped(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .editProductAttributesButtonTapped, properties: [Keys.productID: "\(productID)"])
        }

        static func addAttributeButtonTapped(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductAttributeButtonTapped, properties: [Keys.productID: "\(productID)"])
        }

        static func updateAttribute(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .updateProductAttribute, properties: [Keys.productID: "\(productID)"])
        }

        static func updateAttributeSuccess(productID: Int64, time: Double) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .updateProductAttributeSuccess, properties: [Keys.productID: "\(productID)", Keys.serverTime: "\(time)"])
        }

        static func updateAttributeFail(productID: Int64, time: Double, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .updateProductAttributeFail, properties: [Keys.productID: "\(productID)",
                                                                                  Keys.serverTime: "\(time)",
                                                                                  Keys.errorDescription: error.localizedDescription])
        }

        static func renameAttributeButtonTapped(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .renameProductAttributeButtonTapped, properties: [Keys.productID: "\(productID)"])
        }

        static func removeAttributeButtonTapped(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .removeProductAttributeButtonTapped, properties: [Keys.productID: "\(productID)"])
        }

        static func editVariationAttributeOptionsRowTapped(productID: Int64, variationID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .editProductVariationAttributeOptionsRowTapped, properties: [Keys.productID: "\(productID)",
                                                                                                     Keys.variationID: "\(variationID)"])
        }

        static func editVariationAttributeOptionsDoneButtonTapped(productID: Int64, variationID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .editProductVariationAttributeOptionsDoneButtonTapped, properties: [Keys.productID: "\(productID)",
                                                                                                            Keys.variationID: "\(variationID)"])
        }

        static func bulkUpdateSectionTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationBulkUpdateSectionTapped, properties: [:])
        }

        static func bulkUpdateFieldTapped(field: BulkUpdateField) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationBulkUpdateFieldTapped, properties: [Keys.field: field.rawValue])
        }

        static func bulkUpdateFieldSuccess(field: BulkUpdateField) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationBulkUpdateFieldSuccess, properties: [Keys.field: field.rawValue])
        }

        static func bulkUpdateFieldFailed(field: BulkUpdateField, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationBulkUpdateFieldFail, properties: [Keys.field: field.rawValue], error: error)
        }

        static func productVariationGenerationRequested() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationGenerationRequested, properties: [:])
        }

        static func productVariationGenerationConfirmed(count: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationGenerationConfirmed, properties: [Keys.variationsCount: count])
        }

        static func productVariationGenerationLimitReached(count: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationGenerationLimitReached, properties: [Keys.variationsCount: count])
        }

        static func productVariationGenerationSuccess() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationGenerationSuccess, properties: [:])
        }

        static func productVariationGenerationFailure() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationGenerationFailure, properties: [:])
        }

        /// Tracks when the merchant taps the Quantity Rules row for a product variation.
        ///
        static func quantityRulesTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationDetailViewQuantityRulesTapped, properties: [:])
        }

        /// For Woo Subscriptions products, tracks when the subscription free trial setting is tapped.
        ///
        static func freeTrialSettingsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationViewSubscriptionFreeTrialTapped, properties: [:])
        }

        /// For Woo Subscriptions products, tracks when the subscription free trial setting is tapped.
        ///
        static func expirationDateSettingsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationViewSubscriptionExpirationDateTapped, properties: [:])
        }

        static func quantityRulesDoneButtonTapped(hasChangedData: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productVariationDetailsViewQuantityRulesDoneButtonTapped,
                              properties: [Keys.hasChangedData: hasChangedData])
        }
    }
}

// MARK: - Order Detail Add-ons
//
extension WooAnalyticsEvent {
    // Namespace
    enum OrderDetailAddOns {
        /// Common event keys
        ///
        private enum Keys {
            static let state = "state"
            static let addOns = "add_ons"
        }

        static func betaFeaturesSwitchToggled(isOn: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .settingsBetaFeaturesOrderAddOnsToggled, properties: [Keys.state: isOn ? "on" : "off"])
        }

        static func orderAddOnsViewed(addOnNames: [String]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailAddOnsViewed, properties: [Keys.addOns: addOnNames.joined(separator: ",")])
        }
    }
}

// MARK: - Product Detail
//
extension WooAnalyticsEvent {
    /// Namespace
    enum ProductDetail {
        /// Common event keys
        ///
        private enum Keys {
            static let hasChangedData = "has_changed_data"
        }

        static func loaded(hasLinkedProducts: Bool, hasMinMaxQuantityRules: Bool, horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailLoaded, properties: ["has_linked_products": hasLinkedProducts,
                                                                           "has_minmax_quantity_rules": hasMinMaxQuantityRules,
                                                                           "horizontal_size_class": horizontalSizeClass.nameForAnalytics])
        }

        /// Tracks when the merchant previews a product draft.
        ///
        static func previewTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailPreviewTapped, properties: [:])
        }

        /// Tracks when the product preview fails due to a HTTP error.
        ///
        static func previewFailed(statusCode: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailPreviewFailed, properties: ["status_code": Int64(statusCode)])
        }

        /// Tracks when the merchant taps the Bundled Products row (applicable for bundle-type products only).
        ///
        static func bundledProductsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailViewBundledProductsTapped, properties: [:])
        }

        /// Tracks when the merchant taps the Components row (applicable for composite-type products only).
        ///
        static func componentsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailViewComponentsTapped, properties: [:])
        }

        /// Tracks when the merchant taps the Quantity Rules row.
        ///
        static func quantityRulesTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailViewQuantityRulesTapped, properties: [:])
        }

        /// For Woo Subscriptions products, tracks when the subscription free trial setting is tapped.
        ///
        static func freeTrialSettingsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailsViewSubscriptionFreeTrialTapped, properties: [:])
        }

        /// For Woo Subscriptions products, tracks when the subscription free trial setting is tapped.
        ///
        static func expirationDateSettingsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailsViewSubscriptionExpirationDateTapped, properties: [:])
        }

        static func quantityRulesDoneButtonTapped(hasChangedData: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailsViewQuantityRulesDoneButtonTapped,
                              properties: [Keys.hasChangedData: hasChangedData])
        }

        /// For Woo Subscriptions products, tracks when the subscription expiration details screen is closed.
        ///
        static func expirationDetailsScreenClosed(hasChangedData: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .productSubscriptionExpirationDoneButtonTapped,
                properties: [Keys.hasChangedData: hasChangedData]
            )
        }

        /// For Woo Subscriptions products, tracks when the subscription free trial screen is closed.
        ///
        static func freeTrialDetailsScreenClosed(hasChangedData: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .productSubscriptionFreeTrialDoneButtonTapped,
                properties: [Keys.hasChangedData: hasChangedData]
            )
        }
    }
}

// MARK: - Product Detail Add-ons
//
extension WooAnalyticsEvent {
    /// Common event keys
    ///
    private enum Keys {
        static let productID = "product_id"
    }

    // Namespace
    enum ProductDetailAddOns {
        static func productAddOnsButtonTapped(productID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailViewProductAddOnsTapped, properties: [Keys.productID: "\(productID)"])
        }
    }
}

// MARK: - Order General
//
extension WooAnalyticsEvent {
    // Namespace
    enum Orders {
        /// Possible Order Flows
        ///
        enum Flow: String {
            case creation
            case editing
            case list
            case orderDetails = "order_details"
        }

        /// Possible item types to add to an Order
        ///
        enum ProductType: String {
            case product
            case variation
        }

        enum OrderProductAdditionVia: String {
            case scanning
            case manually
        }

        enum GlobalKeys {
            static let millisecondsSinceOrderAddNew = "milliseconds_since_order_add_new"
        }

        /// The raw value is the analytics event property value.
        enum BundleProductConfigurationSource: String {
            case productCard = "product_card"
            case productSelector = "product_selector"
        }

        /// The raw value is the analytics event property value.
        enum BundleProductConfigurationChangedField: String {
            case quantity
            case variation
        }

        private enum Keys {
            static let changedField = "changed_field"
            static let flow = "flow"
            static let hasDifferentShippingDetails = "has_different_shipping_details"
            static let orderStatus = "order_status"
            static let productCount = "product_count"
            static let customAmountsCount = "custom_amounts_count"
            static let hasAddOns = "has_addons"
            static let hasBundleProductConfiguration = "has_bundle_configuration"
            static let hasCustomerDetails = "has_customer_details"
            static let hasFees = "has_fees"
            static let hasShippingMethod = "has_shipping_method"
            static let isGiftCardRemoved = "removed"
            static let errorContext = "error_context"
            static let errorDescription = "error_description"
            static let to = "to"
            static let from = "from"
            static let orderID = "id"
            static let productTypes = "product_types"
            static let hasMultipleShippingLines = "has_multiple_shipping_lines"
            static let shippingLinesCount = "shipping_lines_count"
            static let hasMultipleFeeLines = "has_multiple_fee_lines"
            static let itemType = "item_type"
            static let source = "source"
            static let addedVia = "added_via"
            static let isFilterActive = "is_filter_active"
            static let searchFilter = "search_filter"
            static let couponsCount = "coupons_count"
            static let type = "type"
            static let usesGiftCard = "use_gift_card"
            static let taxStatus = "tax_status"
            static let expanded = "expanded"
            static let horizontalSizeClass = "horizontal_size_class"
            static let shippingMethod = "shipping_method"
        }

        static func ordersSelected(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            return WooAnalyticsEvent(statName: .ordersSelected,
                                     properties: [
                                        Keys.horizontalSizeClass: horizontalSizeClass.nameForAnalytics
                                     ])
        }

        static func ordersReselected(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            return WooAnalyticsEvent(statName: .ordersReselected,
                                     properties: [
                                        Keys.horizontalSizeClass: horizontalSizeClass.nameForAnalytics
                                     ])
        }

        static func orderOpen(order: Order,
                              horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            let customFieldsSize = order.customFields.map { $0.value.utf8.count }.reduce(0, +) // Total byte size of custom field values
            return WooAnalyticsEvent(statName: .orderOpen,
                                     properties: [
                                        "id": order.orderID,
                                        "status": order.status.rawValue,
                                        "custom_fields_count": Int64(order.customFields.count),
                                        "custom_fields_size": Int64(customFieldsSize),
                                        Keys.horizontalSizeClass: horizontalSizeClass.nameForAnalytics
                                     ])
        }

        static func orderAddNew() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderAddNew, properties: [:])
        }

        static func orderProductsLoaded(order: Order, products: [Product], addOnGroups: [AddOnGroup]) -> WooAnalyticsEvent {
            let productTypes = productTypes(order: order, products: products)
            let hasAddOns = hasAddOns(order: order, products: products, addOnGroups: addOnGroups)
            return WooAnalyticsEvent(statName: .orderProductsLoaded, properties: [Keys.orderID: order.orderID,
                                                                                  Keys.productTypes: productTypes,
                                                                                  Keys.hasAddOns: hasAddOns])
        }

        private static func hasAddOns(order: Order, products: [Product], addOnGroups: [AddOnGroup]) -> Bool {
            for item in order.items {
                guard let product = products.first(where: { $0.productID == item.productID }) else {
                    continue
                }
                if item.addOns.isNotEmpty {
                    return true
                }
                let itemHasAddOns = AddOnCrossreferenceUseCase(orderItemAttributes: item.attributes,
                                                               product: product,
                                                               addOnGroups: addOnGroups)
                    .addOns().isNotEmpty
                if itemHasAddOns {
                    return true
                }
            }
            return false
        }

        private static func productTypes(order: Order, products: [Product]) -> String {
            let productIDs = order.items.map { $0.productID }
            return productIDs.compactMap { productID in
                products.first(where: { $0.productID == productID })?.productType.rawValue
            }.uniqued().sorted().joined(separator: ",")
        }

        static func orderAddNewFromBarcodeScanningTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderListProductBarcodeScanningTapped, properties: [:])
        }

        static func productAddNewFromBarcodeScanningTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductBarcodeScanningTapped, properties: [:])
        }

        static func orderEditButtonTapped(hasMultipleShippingLines: Bool, hasMultipleFeeLines: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderEditButtonTapped, properties: [
                Keys.hasMultipleShippingLines: hasMultipleShippingLines,
                Keys.hasMultipleFeeLines: hasMultipleFeeLines
            ])
        }

        static func orderProductAdd(flow: Flow,
                                    source: BarcodeScanning.Source,
                                    addedVia: OrderProductAdditionVia,
                                    productCount: Int = 1,
                                    includesBundleProductConfiguration: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductAdd, properties: [
                Keys.flow: flow.rawValue,
                Keys.productCount: Int64(productCount),
                Keys.source: source.rawValue,
                Keys.addedVia: addedVia.rawValue,
                Keys.hasBundleProductConfiguration: includesBundleProductConfiguration
            ])
        }

        static func orderProductQuantityChange(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductQuantityChange, properties: [Keys.flow: flow.rawValue])
        }

        static func orderProductRemove(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductRemove, properties: [Keys.flow: flow.rawValue])
        }

        static func orderCustomerAdd(flow: Flow, hasDifferentShippingDetails: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCustomerAdd, properties: [
                Keys.flow: flow.rawValue,
                Keys.hasDifferentShippingDetails: hasDifferentShippingDetails
            ])
        }

        static func orderFeeAdd(flow: Flow, taxStatus: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFeeAdd, properties: [Keys.flow: flow.rawValue, Keys.taxStatus: taxStatus])
        }

        static func orderFeeUpdate(flow: Flow, taxStatus: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFeeUpdate, properties: [Keys.flow: flow.rawValue, Keys.taxStatus: taxStatus])
        }

        static func orderFeeRemove(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFeeRemove, properties: [Keys.flow: flow.rawValue])
        }

        static func orderCouponAdd(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCouponAdd, properties: [Keys.flow: flow.rawValue])
        }

        static func orderCouponRemove(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCouponRemove, properties: [Keys.flow: flow.rawValue])
        }

        static func orderGoToCouponsButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderGoToCouponsButtonTapped, properties: [:])
        }

        static func orderTaxHelpButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderTaxHelpButtonTapped, properties: [:])
        }

        static func taxEducationalDialogEditInAdminButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .taxEducationalDialogEditInAdminButtonTapped, properties: [:])
        }

        static func productDiscountAdd(type: FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductDiscountAdd, properties: [Keys.type: type.rawValue])
        }

        static func productDiscountRemove() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductDiscountRemove, properties: [:])
        }

        static func productDiscountAddButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductDiscountAddButtonTapped, properties: [:])
        }

        static func productDiscountEditButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductDiscountEditButtonTapped, properties: [:])
        }

        static func orderAddShippingTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderAddShippingTapped, properties: [:])
        }

        static func orderShippingMethodSelected(methodID: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderShippingMethodSelected, properties: [Keys.shippingMethod: methodID])
        }

        static func orderShippingMethodAdd(flow: Flow, methodID: String, shippingLinesCount: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderShippingMethodAdd, properties: [Keys.flow: flow.rawValue,
                                                                              Keys.shippingMethod: methodID,
                                                                              Keys.shippingLinesCount: shippingLinesCount])
        }

        static func orderShippingMethodRemove(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderShippingMethodRemove, properties: [Keys.flow: flow.rawValue])
        }

        static func orderCustomerNoteAdd(flow: Flow, orderID: Int64, orderStatus: OrderStatusEnum) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderNoteAdd, properties: [Keys.flow: flow.rawValue,
                                                                    "parent_id": orderID,
                                                                    "status": orderStatus.rawValue,
                                                                    "type": "customer"])
        }

        static func orderStatusChange(flow: Flow, orderID: Int64?, from oldStatus: OrderStatusEnum, to newStatus: OrderStatusEnum) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.flow: flow.rawValue,
                Keys.orderID: orderID,
                Keys.from: oldStatus.rawValue,
                Keys.to: newStatus.rawValue
            ]
            return WooAnalyticsEvent(statName: .orderStatusChange, properties: properties.compactMapValues { $0 })
        }

        static func orderTotalsExpansionChanged(flow: Flow,
                                                expanded: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormTotalsPanelToggled, properties: [
                Keys.flow: flow.rawValue,
                Keys.expanded: expanded
            ])
        }

        static func orderCreateButtonTapped(order: Order,
                                            status: OrderStatusEnum,
                                            productCount: Int,
                                            customAmountsCount: Int,
                                            hasCustomerDetails: Bool,
                                            hasFees: Bool,
                                            hasShippingMethod: Bool,
                                            products: [Product],
                                            horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreateButtonTapped, properties: [
                Keys.orderStatus: status.rawValue,
                Keys.productCount: Int64(productCount),
                Keys.customAmountsCount: Int64(customAmountsCount),
                Keys.hasCustomerDetails: hasCustomerDetails,
                Keys.hasFees: hasFees,
                Keys.hasShippingMethod: hasShippingMethod,
                Keys.productTypes: productTypes(order: order, products: products),
                Keys.horizontalSizeClass: horizontalSizeClass.nameForAnalytics
            ])
        }

        static func orderCreationCollectPaymentTapped(order: Order,
                                                      status: OrderStatusEnum,
                                                      productCount: Int,
                                                      customAmountsCount: Int,
                                                      hasCustomerDetails: Bool,
                                                      hasFees: Bool,
                                                      hasShippingMethod: Bool,
                                                      products: [Product],
                                                      horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentTapped, properties: [
                Keys.flow: Flow.creation.rawValue,
                Keys.orderStatus: status.rawValue,
                Keys.productCount: Int64(productCount),
                Keys.customAmountsCount: Int64(customAmountsCount),
                Keys.hasCustomerDetails: hasCustomerDetails,
                Keys.hasFees: hasFees,
                Keys.hasShippingMethod: hasShippingMethod,
                Keys.productTypes: productTypes(order: order, products: products),
                Keys.horizontalSizeClass: horizontalSizeClass.nameForAnalytics
            ])
        }

        static func orderCreationSuccess(millisecondsSinceSinceOrderAddNew: Int64?,
                                         couponsCount: Int64,
                                         usesGiftCard: Bool,
                                         shippingLinesCount: Int64) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [Keys.couponsCount: couponsCount,
                                                                       Keys.usesGiftCard: usesGiftCard,
                                                                       Keys.shippingLinesCount: shippingLinesCount]

            if let lapseSinceLastOrderAddNew = millisecondsSinceSinceOrderAddNew {
                properties[GlobalKeys.millisecondsSinceOrderAddNew] = lapseSinceLastOrderAddNew
            }

            return WooAnalyticsEvent(statName: .orderCreationSuccess, properties: properties)
        }

        static func orderCreationFailed(usesGiftCard: Bool, errorContext: String, errorDescription: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationFailed, properties: [
                Keys.usesGiftCard: usesGiftCard,
                Keys.errorContext: errorContext,
                Keys.errorDescription: errorDescription
            ])
        }

        static func orderSyncFailed(flow: Flow, usesGiftCard: Bool, errorContext: String, errorDescription: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderSyncFailed, properties: [
                Keys.flow: flow.rawValue,
                Keys.usesGiftCard: usesGiftCard,
                Keys.errorContext: errorContext,
                Keys.errorDescription: errorDescription
            ])
        }

        static func orderCreationProductSelectorItemSelected(productType: ProductType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductSelectorItemSelected, properties: [
                Keys.itemType: productType.rawValue
            ])
        }

        static func orderCreationProductSelectorItemUnselected(productType: ProductType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductSelectorItemUnselected, properties: [
                Keys.itemType: productType.rawValue
            ])
        }

        static func orderCreationProductSelectorConfirmButtonTapped(productCount: Int, sources: [String], isFilterActive: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductSelectorConfirmButtonTapped, properties: [
                Keys.productCount: Int64(productCount),
                Keys.source: sources.joined(separator: ","),
                Keys.isFilterActive: isFilterActive
            ])
        }

        static func orderCreationProductSelectorSearchTriggered(searchFilter: ProductSearchFilter) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductSelectorSearchTriggered, properties: [
                Keys.searchFilter: searchFilter.rawValue
            ])
        }

        static func orderCreationProductSelectorClearSelectionButtonTapped(productType: ProductType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductSelectorClearSelectionButtonTapped, properties: [
                Keys.source: productType.rawValue + "_selector"
            ])
        }

        static func orderFormAddGiftCardCTAShown(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormAddGiftCardCTAShown, properties: [Keys.flow: flow.rawValue])
        }

        static func orderFormAddGiftCardCTATapped(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormAddGiftCardCTATapped, properties: [Keys.flow: flow.rawValue])
        }

        static func orderFormGiftCardSet(flow: Flow, isRemoved: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormGiftCardSet, properties: [Keys.flow: flow.rawValue, Keys.isGiftCardRemoved: isRemoved])
        }

        /// Tracked when the user taps to collect a payment
        ///
        static func collectPaymentTapped(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentTapped,
                              properties: [Keys.flow: flow.rawValue])
        }

        /// Tracked when accessing the system plugin list without it being in sync.
        ///
        static func pluginsNotSyncedYet() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pluginsNotSyncedYet, properties: [:])
        }

        /// Tracked when subscriptions are displayed in order details.
        ///
        static func subscriptionsShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailsSubscriptionsShown, properties: [:])
        }

        /// Tracked when gift cards are displayed in order details.
        ///
        static func giftCardsShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailsGiftCardShown, properties: [:])
        }

        /// Tracks when shipping is displayed in order details.
        ///
        static func shippingShown(shippingLinesCount: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailsShippingMethodsShown, properties: [Keys.shippingLinesCount: shippingLinesCount])
        }

        /// Tracked when the Configure button is shown in the order form.
        ///
        static func orderFormBundleProductConfigureCTAShown(flow: Flow, source: BundleProductConfigurationSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormBundleProductConfigureCTAShown, properties: [
                Keys.flow: flow.rawValue,
                Keys.source: source.rawValue
            ])
        }

        /// Tracked when the Configure button is tapped in the order form.
        ///
        static func orderFormBundleProductConfigureCTATapped(flow: Flow, source: BundleProductConfigurationSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormBundleProductConfigureCTATapped, properties: [
                Keys.flow: flow.rawValue,
                Keys.source: source.rawValue
            ])
        }

        /// Tracked the user changes any field for any bundle item in the configuration form from the order form.
        ///
        static func orderFormBundleProductConfigurationChanged(changedField: BundleProductConfigurationChangedField) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormBundleProductConfigurationChanged, properties: [
                Keys.changedField: changedField.rawValue
            ])
        }

        /// Tracked when the user taps to save a valid bundle product configuration from the order form.
        ///
        static func orderFormBundleProductConfigurationSaveTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFormBundleProductConfigurationSaveTapped, properties: [:])
        }
    }
}

// MARK: - Order Details Edit
//
extension WooAnalyticsEvent {
    // Namespace
    enum OrderDetailsEdit {
        /// Possible types of edit
        ///
        enum Subject: String {
            fileprivate static let key = "subject"

            case customerNote = "customer_note"
            case shippingAddress = "shipping_address"
            case billingAddress = "billing_address"
        }

        static func orderDetailEditFlowStarted(subject: Subject) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailEditFlowStarted, properties: [Subject.key: subject.rawValue])
        }

        static func orderDetailEditFlowCompleted(subject: Subject) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailEditFlowCompleted, properties: [Subject.key: subject.rawValue])
        }

        static func orderDetailEditFlowFailed(subject: Subject) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailEditFlowFailed, properties: [Subject.key: subject.rawValue])
        }

        static func orderDetailEditFlowCanceled(subject: Subject) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailEditFlowCanceled, properties: [Subject.key: subject.rawValue])
        }

        static func orderDetailPaymentLinkShared() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderDetailPaymentLinkShared, properties: [:])
        }
    }
}

// MARK: - What's New Component
//
extension WooAnalyticsEvent {
    /// Possible sources for the What's New component
    ///
    enum Source: String {
        fileprivate static let key = "source"

        case appUpgrade = "app_upgrade"
        case appSettings = "app_settings"
    }

    static func featureAnnouncementShown(source: Source) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .featureAnnouncementShown, properties: [Source.key: source.rawValue])
    }
}

// MARK: - InPersonPayments Feedback Banner
extension WooAnalyticsEvent {
    enum InPersonPaymentsFeedbackBanner {
        /// Possible sources for the Feedback Banner
        ///
        enum Source: String {
            case orderList = "order_list"
        }

        /// Keys for the Feedback Banner properties
        ///
        private enum Keys {
            static let campaign = "campaign"
            static let source = "source"
            static let remindLater = "remind_later"
        }

        static func shown(source: Source, campaign: FeatureAnnouncementCampaign) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .inPersonPaymentsBannerShown,
                              properties: [
                                Keys.source: source.rawValue,
                                Keys.campaign: campaign.rawValue
                              ])
        }

        static func ctaTapped(source: Source, campaign: FeatureAnnouncementCampaign) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .inPersonPaymentsBannerTapped,
                              properties: [
                                Keys.source: source.rawValue,
                                Keys.campaign: campaign.rawValue
                              ])
        }

        static func dismissed(source: Source,
                              campaign: FeatureAnnouncementCampaign,
                              remindLater: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .inPersonPaymentsBannerDismissed,
                              properties: [
                                Keys.source: source.rawValue,
                                Keys.campaign: campaign.rawValue,
                                Keys.remindLater: remindLater
                              ])
        }
    }
}

// MARK: - Feature Announcement Card

extension WooAnalyticsEvent {
    enum FeatureCard {
        /// Possible sources for the Feature Card
        ///
        enum Source: String {
            fileprivate static let key = "source"

            case orderList = "order_list"
            case paymentMethods = "payment_methods"
            case productDetail = "product_detail"
            case settings
            case myStore = "my_store"
        }

        /// Keys for the Feature Card properties
        ///
        private enum Keys {
            static let campaign = "campaign"
            static let source = "source"
            static let remindLater = "remind_later"
        }

        static func shown(source: Source, campaign: FeatureAnnouncementCampaign) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .featureCardShown,
                              properties: [
                                Keys.source: source.rawValue,
                                Keys.campaign: campaign.rawValue
                              ])
        }

        static func dismissed(source: Source,
                              campaign: FeatureAnnouncementCampaign,
                              remindLater: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .featureCardDismissed,
                              properties: [
                                Keys.source: source.rawValue,
                                Keys.campaign: campaign.rawValue,
                                Keys.remindLater: remindLater
                              ])
        }

        static func ctaTapped(source: Source, campaign: FeatureAnnouncementCampaign) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .featureCardCtaTapped,
                              properties: [
                                Keys.source: source.rawValue,
                                Keys.campaign: campaign.rawValue
                              ])
        }
    }
}

// MARK: - Just In Time Messages
//
extension WooAnalyticsEvent {
    enum JustInTimeMessage {
        private enum Keys {
            static let source = "source"
            static let justInTimeMessage = "jitm"
            static let justInTimeMessageID = "jitm_id"
            static let justInTimeMessageGroup = "jitm_group"
            static let count = "count"
        }

        static func fetchSuccess(source: String,
                                 messageID: String,
                                 count: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .justInTimeMessageFetchSuccess,
                              properties: [
                                Keys.source: source,
                                Keys.justInTimeMessage: messageID,
                                Keys.count: count
                              ])
        }

        static func fetchFailure(source: String,
                                 error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .justInTimeMessageFetchFailure,
                              properties: [Keys.source: source],
                              error: error)
        }

        static func messageDisplayed(source: String,
                                     messageID: String,
                                     featureClass: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .justInTimeMessageDisplayed,
                              properties: [
                                Keys.source: source,
                                Keys.justInTimeMessageID: messageID,
                                Keys.justInTimeMessageGroup: featureClass
                              ])
        }

        static func callToActionTapped(source: String,
                                       messageID: String,
                                       featureClass: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .justInTimeMessageCallToActionTapped,
                              properties: [
                                Keys.source: source,
                                Keys.justInTimeMessageID: messageID,
                                Keys.justInTimeMessageGroup: featureClass
                              ])
        }

        static func dismissTapped(source: String,
                                  messageID: String,
                                  featureClass: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .justInTimeMessageDismissTapped,
                              properties: [
                                Keys.source: source,
                                Keys.justInTimeMessageID: messageID,
                                Keys.justInTimeMessageGroup: featureClass
                              ])
        }

        static func dismissSuccess(source: String,
                                  messageID: String,
                                  featureClass: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .justInTimeMessageDismissSuccess, properties: [
                Keys.source: source,
                Keys.justInTimeMessageID: messageID,
                Keys.justInTimeMessageGroup: featureClass
              ])
        }

        static func dismissFailure(source: String,
                                   messageID: String,
                                   featureClass: String,
                                   error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .justInTimeMessageDismissFailure,
                              properties: [
                                Keys.source: source,
                                Keys.justInTimeMessageID: messageID,
                                Keys.justInTimeMessageGroup: featureClass
                              ],
                              error: error)
        }
    }
}

// MARK: - Simple Payments
//
extension WooAnalyticsEvent {
    // Namespace
    enum SimplePayments {
        /// Common event keys
        ///
        private enum Keys {
            static let state = "state"
        }

        static func simplePaymentsFlowNoteAdded() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowNoteAdded, properties: [:])
        }

        static func simplePaymentsFlowTaxesToggled(isOn: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowTaxesToggled, properties: [Keys.state: isOn ? "on" : "off"])
        }

        static func simplePaymentsMigrationSheetAddCustomAmount() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsMigrationSheetAddCustomAmount, properties: [:])
        }

        static func simplePaymentsMigrationSheetShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsMigrationSheetShown, properties: [:])
        }
    }
}


// MARK: - Payments Flow Methods
//
extension WooAnalyticsEvent {
    // Namespace
    enum PaymentsFlow {
        /// Possible Payment Methods
        ///
        enum PaymentMethod: String {
            case card
            case cash
            case paymentLink = "payment_link"
            case scanToPay = "scan_to_pay"
        }

        /// Possible view sources
        ///
        enum Source: String {
            case amount
            case summary
            case paymentMethod = "payment_method"
            case tapToPayTryAPaymentPrompt = "tap_to_pay_try_a_payment_prompt"
        }

        /// Possible flows
        ///
        enum Flow: String {
            case simplePayment = "simple_payment"
            case orderPayment = "order_payment"
            case orderCreation = "creation"
            case tapToPayTryAPayment = "tap_to_pay_try_a_payment"
        }

        enum CardReaderType: String {
            case external
            case builtIn = "built_in"
        }

        /// Common event keys
        ///
        private enum Keys {
            static let state = "state"
            static let amount = "amount"
            static let amountNormalized = "amount_normalized"
            static let country = "country"
            static let currency = "currency"
            static let paymentMethod = "payment_method"
            static let source = "source"
            static let flow = "flow"
            static let cardReaderType = "card_reader_type"
            static let orderID = "order_id"
        }

        static func paymentsFlowCompleted(flow: Flow,
                                          amount: String,
                                          amountNormalized: Int,
                                          country: CountryCode,
                                          currency: String,
                                          method: PaymentMethod,
                                          orderID: Int64,
                                          cardReaderType: CardReaderType?) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [Keys.flow: flow.rawValue,
                                                                       Keys.amount: amount,
                                                                       Keys.amountNormalized: amountNormalized,
                                                                       Keys.country: country.rawValue,
                                                                       Keys.currency: currency,
                                                                       Keys.paymentMethod: method.rawValue,
                                                                       Keys.orderID: orderID]

            if let cardReaderType = cardReaderType {
                properties[Keys.cardReaderType] = cardReaderType.rawValue
            }

            return WooAnalyticsEvent(statName: .paymentsFlowCompleted, properties: properties)
        }

        static func paymentsFlowCanceled(flow: Flow, country: CountryCode, currency: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsFlowCanceled, properties: [
                Keys.flow: flow.rawValue,
                Keys.country: country.rawValue,
                Keys.currency: currency
            ])
        }

        static func paymentsFlowFailed(flow: Flow, source: Source, country: CountryCode, currency: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsFlowFailed, properties: [
                Keys.flow: flow.rawValue,
                Keys.source: source.rawValue,
                Keys.country: country.rawValue,
                Keys.currency: currency
            ])
        }

        static func paymentsFlowCollect(flow: Flow,
                                        method: PaymentMethod,
                                        orderID: Int64,
                                        cardReaderType: CardReaderType?,
                                        millisecondsSinceOrderAddNew: Int64?,
                                        country: CountryCode,
                                        currency: String) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.flow: flow.rawValue,
                Keys.paymentMethod: method.rawValue,
                Keys.orderID: orderID,
                Keys.country: country.rawValue,
                Keys.currency: currency
            ]

            if let cardReaderType = cardReaderType {
                properties[Keys.cardReaderType] = cardReaderType.rawValue
            }

            if let lapseSinceLastOrderAddNew = millisecondsSinceOrderAddNew {
                properties[Orders.GlobalKeys.millisecondsSinceOrderAddNew] = lapseSinceLastOrderAddNew
            }

            return WooAnalyticsEvent(statName: .paymentsFlowCollect, properties: properties)
        }
    }
}



// MARK: - Jetpack Benefits Banner
//
extension WooAnalyticsEvent {
    /// The action performed on the Jetpack benefits banner.
    enum JetpackBenefitsBannerAction: String {
        case shown
        case dismissed
        case tapped
    }

    /// Tracked on various states of the Jetpack benefits banner in dashboard.
    static func jetpackBenefitsBanner(action: JetpackBenefitsBannerAction) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .jetpackBenefitsBanner, properties: ["action": action.rawValue])
    }
}

// MARK: - Jetpack Install
//
extension WooAnalyticsEvent {
    /// The source that presents the Jetpack install screen.
    enum JetpackInstallSource: String {
        case settings
        case benefitsModal = "benefits_modal"
    }

    /// Tracked when the user taps to install Jetpack.
    static func jetpackInstallButtonTapped(source: JetpackInstallSource) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .jetpackInstallButtonTapped, properties: ["source": source.rawValue])
    }
}

// MARK: - In Person Payments
//
extension WooAnalyticsEvent {

    enum InPersonPayments {

        enum Keys {
            static let batteryLevel = "battery_level"
            static let cardReaderModel = "card_reader_model"
            static let countryCode = "country"
            static let reason = "reason"
            static let remindLater = "remind_later"
            static let gatewayID = "plugin_slug"
            static let errorDescription = "error_description"
            static let paymentMethodType = "payment_method_type"
            static let softwareUpdateType = "software_update_type"
            static let source = "source"
            static let enabled = "enabled"
            static let cancellationSource = "cancellation_source"
            static let millisecondsSinceCardCollectPaymentFlow = "milliseconds_since_card_collect_payment_flow"
            static let siteID = "site_id"
            static let connectionType = "connection_type"
            static let receiptSource = "source"
        }

        static let unknownGatewayID = "unknown"

        private static func safeGatewayID(for gatewayID: String?) -> String {
            gatewayID ?? unknownGatewayID
        }

        static let noReaderConnected = "none_connected"

        static func readerModel(for connectedReaderModel: String?) -> String {
            connectedReaderModel ?? noReaderConnected
        }

        /// Tracked when we ask the user to choose between Built In and Bluetooth readers
        /// at the start of the connection flow
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///
        static func cardReaderSelectTypeShown(forGatewayID: String?, countryCode: CountryCode) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSelectTypeShown,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID)
                              ]
            )
        }

        /// Tracked when the user to chooses the Built In reader
        /// at the start of the connection flow
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///
        static func cardReaderSelectTypeBuiltInTapped(forGatewayID: String?, countryCode: CountryCode) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSelectTypeBuiltInTapped,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID)
                              ]
            )
        }

        /// Tracked when the user to chooses the Bluetooth reader
        /// at the start of the connection flow
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///
        static func cardReaderSelectTypeBluetoothTapped(forGatewayID: String?, countryCode: CountryCode) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSelectTypeBluetoothTapped,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID)
                              ]
            )
        }

        /// Tracked when we automatically disconnect a Built In reader, when Manage Card Reader is opened
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///
        static func manageCardReadersBuiltInReaderAutoDisconnect(forGatewayID: String?, countryCode: CountryCode) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .manageCardReadersBuiltInReaderAutoDisconnect,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID)
                              ]
            )
        }

        /// Tracked when we automatically disconnect a Built In reader, when setting up Tap to Pay
        ///
        /// - Parameters:
        ///   - cardReaderModel: the model type of the card reader.
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///
        static func cardReaderAutomaticDisconnect(cardReaderModel: String?,
                                                  forGatewayID: String?, countryCode: CountryCode,
                                                  connectionType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderAutomaticDisconnect,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.connectionType: connectionType
                              ]
            )
        }

        /// Tracked when card reader discovery fails
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///
        static func cardReaderDiscoveryFailed(forGatewayID: String?,
                                              error: Error,
                                              countryCode: CountryCode,
                                              siteID: Int64,
                                              connectionType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderDiscoveryFailed,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.errorDescription: error.localizedDescription,
                                Keys.siteID: siteID,
                                Keys.connectionType: connectionType
                              ]
            )
        }

        /// Tracked when connecting to a card reader
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - batteryLevel: the battery level (if available) to be included in the event properties in Tracks, e.g. 0.75 = 75%.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderConnectionSuccess(forGatewayID: String?,
                                                batteryLevel: Float?,
                                                countryCode: CountryCode,
                                                cardReaderModel: String?,
                                                connectionType: String) -> WooAnalyticsEvent {
            var properties = [
                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                Keys.countryCode: countryCode.rawValue,
                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                Keys.connectionType: connectionType
            ]

            if let batteryLevel = batteryLevel {
                properties[Keys.batteryLevel] = String(format: "%.2f", batteryLevel)
            }

            return WooAnalyticsEvent(statName: .cardReaderConnectionSuccess, properties: properties)
        }

        /// Tracked when connecting to a card reader fails
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderConnectionFailed(forGatewayID: String?,
                                               error: Error,
                                               countryCode: CountryCode,
                                               cardReaderModel: String?,
                                               siteID: Int64,
                                               connectionType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderConnectionFailed,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.errorDescription: error.localizedDescription,
                                Keys.siteID: siteID,
                                Keys.connectionType: connectionType
                              ]
            )
        }


        /// Tracked when disconnecting from a card reader
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderDisconnectTapped(forGatewayID: String?, countryCode: CountryCode, cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderDisconnectTapped,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID)
                              ]
            )
        }

        /// Tracked when a software update is initiated manually
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - updateType: `.required` or `.optional`.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderSoftwareUpdateTapped(forGatewayID: String?,
                                                   updateType: SoftwareUpdateTypeProperty,
                                                   countryCode: CountryCode,
                                                   cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateTapped,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.softwareUpdateType: updateType.rawValue
                              ]
            )
        }

        /// Tracked when a card reader update starts
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - updateType: `.required` or `.optional`.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderSoftwareUpdateStarted(forGatewayID: String?,
                                                    updateType: SoftwareUpdateTypeProperty,
                                                    countryCode: CountryCode,
                                                    cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateStarted,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.softwareUpdateType: updateType.rawValue
                              ]
            )
        }

        /// Tracked when a card reader update fails
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - updateType: `.required` or `.optional`.
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderSoftwareUpdateFailed(forGatewayID: String?,
                                                   updateType: SoftwareUpdateTypeProperty,
                                                   error: Error,
                                                   countryCode: CountryCode,
                                                   cardReaderModel: String
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateFailed,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.softwareUpdateType: updateType.rawValue,
                                Keys.errorDescription: error.localizedDescription
                              ]
            )
        }

        /// Tracked when a software update completes successfully
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - updateType: `.required` or `.optional`.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderSoftwareUpdateSuccess(forGatewayID: String?,
                                                    updateType: SoftwareUpdateTypeProperty,
                                                    countryCode: CountryCode,
                                                    cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateSuccess,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.softwareUpdateType: updateType.rawValue
                              ]
            )
        }

        /// Tracked when an update cancel button is tapped
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - updateType: `.required` or `.optional`.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderSoftwareUpdateCancelTapped(forGatewayID: String?,
                                                         updateType: SoftwareUpdateTypeProperty,
                                                         countryCode: CountryCode,
                                                         cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateCancelTapped,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.softwareUpdateType: updateType.rawValue
                              ]
            )
        }

        /// Tracked when an update is cancelled
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - updateType: `.required` or `.optional`.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func cardReaderSoftwareUpdateCanceled(forGatewayID: String?,
                                                     updateType: SoftwareUpdateTypeProperty,
                                                     countryCode: CountryCode,
                                                     cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateCanceled,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.softwareUpdateType: updateType.rawValue
                              ]
            )
        }

        /// Tracked when the payment collection fails
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader, if available.
        ///
        static func collectPaymentFailed(forGatewayID: String?,
                                         error: Error,
                                         countryCode: CountryCode,
                                         cardReaderModel: String?,
                                         siteID: Int64) -> WooAnalyticsEvent {
            let paymentMethod: PaymentMethod? = {
                guard case let CardReaderServiceError.paymentCaptureWithPaymentMethod(_, paymentMethod) = error else {
                    return nil
                }
                return paymentMethod
            }()
            let errorDescription: String? = {
                guard case let CardReaderServiceError.paymentCaptureWithPaymentMethod(underlyingError, paymentMethod) = error else {
                    return error.localizedDescription
                }
                switch paymentMethod {
                case let .cardPresent(details):
                    return ([
                        "underlyingError": underlyingError,
                        "cardBrand": details.brand
                    ] as [String: Any]).description
                case let .interacPresent(details):
                    return ([
                        "underlyingError": underlyingError,
                        "cardBrand": details.brand
                    ] as [String: Any]).description
                default:
                    return underlyingError.localizedDescription
                }
            }()
            let properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.cardReaderModel: cardReaderModel,
                Keys.countryCode: countryCode.rawValue,
                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                Keys.paymentMethodType: paymentMethod?.analyticsValue,
                Keys.errorDescription: errorDescription,
                Keys.siteID: String(siteID)
            ].compactMapValues { $0 }
            return WooAnalyticsEvent(statName: .collectPaymentFailed,
                                     properties: properties)
        }

        /// Tracked when the payment collection is cancelled
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func collectPaymentCanceled(forGatewayID: String?,
                                           countryCode: CountryCode,
                                           cardReaderModel: String?,
                                           cancellationSource: CancellationSource,
                                           siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentCanceled,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                                Keys.cancellationSource: cancellationSource.rawValue,
                                Keys.siteID: siteID
                              ]
            )
        }

        enum CancellationSource: String {
            case appleTOSAcceptance = "apple_tap_to_pay_terms_acceptance"
            case reader = "card_reader"
            case selectReaderType = "preflight_select_reader_type"
            case searchingForReader = "searching_for_reader"
            case foundReader = "found_reader"
            case foundSeveralReaders = "found_several_readers"
            case paymentValidatingOrder = "payment_validating_order"
            case paymentPreparingReader = "payment_preparing_reader"
            case paymentWaitingForInput = "payment_waiting_for_input"
            case connectionError = "connection_error"
            case readerSoftwareUpdate = "reader_software_update"
            case other = "unknown"
        }

        /// Tracked when payment collection succeeds
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///   - paymentMethod: the payment method of the captured payment.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func collectPaymentSuccess(forGatewayID: String?,
                                          countryCode: CountryCode,
                                          paymentMethod: PaymentMethod,
                                          cardReaderModel: String?,
                                          millisecondsSinceOrderAddNew: Int64?,
                                          millisecondsSinceCardPaymentStarted: Int64?,
                                          siteID: Int64) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                Keys.countryCode: countryCode.rawValue,
                Keys.gatewayID: safeGatewayID(for: forGatewayID),
                Keys.paymentMethodType: paymentMethod.analyticsValue,
                Keys.siteID: siteID
            ]

            if let lapseSinceLastOrderAddNew = millisecondsSinceOrderAddNew {
                properties[Orders.GlobalKeys.millisecondsSinceOrderAddNew] = lapseSinceLastOrderAddNew
            }

            if let timeIntervalSinceCardCollectPaymentFlow = millisecondsSinceCardPaymentStarted {
                properties[Keys.millisecondsSinceCardCollectPaymentFlow] = timeIntervalSinceCardCollectPaymentFlow
            }

            return WooAnalyticsEvent(statName: .collectPaymentSuccess,
                              properties: properties
            )
        }

        /// Tracked when an Interac payment collection succeeds after processing on the client side
        ///
        /// - Parameters:
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func collectInteracPaymentSuccess(gatewayID: String?,
                                                 countryCode: CountryCode,
                                                 cardReaderModel: String?,
                                                 siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectInteracPaymentSuccess,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: gatewayID),
                                Keys.siteID: siteID
                              ])
        }

        /// Tracked when an Interac client-side refund succeeds
        ///
        /// - Parameters:
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func interacRefundSuccess(gatewayID: String?,
                                         countryCode: CountryCode,
                                         cardReaderModel: String?,
                                         siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .interacRefundSuccess,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: gatewayID),
                                Keys.siteID: siteID
                              ])
        }

        /// Tracked when an Interac client-side refund fails
        ///
        /// - Parameters:
        ///   - error: the error to be included in the event properties.
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func interacRefundFailed(error: Error,
                                        gatewayID: String?,
                                        countryCode: CountryCode,
                                        cardReaderModel: String?,
                                        siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .interacRefundFailed,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: gatewayID),
                                Keys.siteID: siteID
                              ],
                              error: error)
        }

        /// Tracked when an Interac client-side refund is canceled
        ///
        /// - Parameters:
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func interacRefundCanceled(gatewayID: String?,
                                          countryCode: CountryCode,
                                          cardReaderModel: String?,
                                          siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .interacRefundCanceled,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode.rawValue,
                                Keys.gatewayID: safeGatewayID(for: gatewayID),
                                Keys.siteID: siteID
                              ])
        }

        /// Tracked when the "learn more" button in the In-Person Payments onboarding is tapped.
        ///
        /// - Parameters:
        ///   - reason: the reason for viewing the learn more page.
        ///   - countryCode: the country code of the store.
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///
        static func cardPresentOnboardingLearnMoreTapped(reason: String,
                                                         countryCode: CountryCode,
                                                         gatewayID: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingLearnMoreTapped,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.reason: reason,
                                Keys.gatewayID: safeGatewayID(for: gatewayID)
                              ])
        }

        /// Tracked when the In-Person Payments onboarding completes.
        ///
        /// - Parameters:
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///
        static func cardPresentOnboardingCompleted(gatewayID: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingCompleted,
                              properties: [
                                Keys.gatewayID: safeGatewayID(for: gatewayID)
                              ])
        }

        /// Tracked when the In-Person Payments onboarding cannot be completed for some reason.
        ///
        /// - Parameters:
        ///   - reason: the reason why the onboarding is not completed.
        ///   - countryCode: the country code of the store.
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///
        static func cardPresentOnboardingNotCompleted(reason: String, countryCode: CountryCode, gatewayID: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingNotCompleted,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.reason: reason,
                                Keys.gatewayID: safeGatewayID(for: gatewayID)
                              ])
        }

        /// Tracked when a In-Person Payments onboarding step is skipped by the user.
        ///
        /// - Parameters:
        ///   - reason: the reason why the onboarding step was shown (effectively the name of the step.)
        ///   - remindLater: whether the user will see this onboarding step again
        ///   - countryCode: the country code of the store.
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///
        static func cardPresentOnboardingStepSkipped(reason: String,
                                                     remindLater: Bool,
                                                     countryCode: CountryCode,
                                                     gatewayID: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingStepSkipped,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.reason: reason,
                                Keys.remindLater: remindLater,
                                Keys.gatewayID: safeGatewayID(for: gatewayID)
                              ])
        }

        /// Tracked when a In-Person Payments onboarding step's CTA is tapped by the user.
        ///
        /// - Parameters:
        ///   - reason: the reason why the onboarding step was shown (effectively the name of the step.)
        ///   - countryCode: the country code of the store.
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///
        static func cardPresentOnboardingCtaTapped(reason: String,
                                                   countryCode: CountryCode,
                                                   gatewayID: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingCtaTapped,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.reason: reason,
                                Keys.gatewayID: safeGatewayID(for: gatewayID)
                              ])
        }

        /// Tracked when a In-Person Payments onboarding step's CTA is tapped by the user and the expected action fails
        ///
        /// - Parameters:
        ///   - reason: the reason why the onboarding step was shown (effectively the name of the step)
        ///   - countryCode: the country code of the store
        ///   - error: the logged error response from the API, if any.
        ///   - gatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///
        static func cardPresentOnboardingCtaFailed(reason: String,
                                                   countryCode: CountryCode,
                                                   error: Error? = nil,
                                                   gatewayID: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingCtaFailed,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.reason: reason,
                                Keys.gatewayID: safeGatewayID(for: gatewayID)
                              ], error: error)
        }

        enum CashOnDeliverySource: String {
            case onboarding
            case paymentsHub = "payments_hub"
        }

        /// Tracked when the Cash on Delivery Payment Gateway is successfully enabled, e.g. from the IPP onboarding flow.
        ///
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - source: the screen which the enable attempt was made on
        ///
        static func enableCashOnDeliverySuccess(countryCode: CountryCode, source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .enableCashOnDeliverySuccess,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.source: source.rawValue
                              ])
        }

        /// Tracked when the Cash on Delivery Payment Gateway enabling fails, e.g. from the IPP onboarding flow.
        ///
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - source: the screen which the enable attempt was made on
        ///
        static func enableCashOnDeliveryFailed(countryCode: CountryCode,
                                               error: Error?,
                                               source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .enableCashOnDeliveryFailed,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.source: source.rawValue
                              ],
                              error: error)
        }

        /// Tracked when the Cash on Delivery Payment Gateway is successfully disabled, e.g. from the toggle on the Payments hub menu.
        ///
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - source: the screen which the disable attempt was made on
        ///
        static func disableCashOnDeliverySuccess(countryCode: CountryCode, source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .disableCashOnDeliverySuccess,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.source: source.rawValue
                              ])
        }

        static func cashOnDeliveryToggleLearnMoreTapped(countryCode: CountryCode,
                                                        source: CashOnDeliverySource) -> WooAnalyticsEvent {
            return WooAnalyticsEvent(statName: .paymentsHubCashOnDeliveryToggleLearnMoreTapped,
                                     properties: [
                                        Keys.countryCode: countryCode.rawValue,
                                        Keys.source: source.rawValue
                                     ])
        }

        /// Tracked when the Cash on Delivery Payment Gateway disabling fails, e.g. from the toggle on the Payments hub menu.
        ///
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - source: the screen which the disable attempt was made on
        ///
        static func disableCashOnDeliveryFailed(countryCode: CountryCode,
                                               error: Error?,
                                               source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .disableCashOnDeliveryFailed,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.source: source.rawValue
                              ],
                              error: error)
        }

        /// Tracked when the Cash on Delivery Payment Gateway toggle is changed from the toggle on the Payments hub menu.
        ///
        /// - Parameters:
        ///   - enabled: the reason why the onboarding step was shown (effectively the name of the step.)
        ///   - countryCode: the country code of the store.
        ///
        static func paymentsHubCashOnDeliveryToggled(enabled: Bool, countryCode: CountryCode) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsHubCashOnDeliveryToggled,
                              properties: [
                                Keys.countryCode: countryCode.rawValue,
                                Keys.enabled: enabled
                              ])
        }

        /// Tracked when the user taps on the "See Receipt" button to view a receipt.
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptViewTapped(countryCode: CountryCode, source: ReceiptSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptViewTapped,
                              properties: [Keys.countryCode: countryCode.rawValue,
                                           Keys.receiptSource: source.rawValue])
        }

        /// Tracked when the user taps on the "Email receipt" button after successfully collecting a payment to email a receipt.
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptEmailTapped(countryCode: CountryCode?, cardReaderModel: String?, source: ReceiptSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailTapped,
                              properties: [
                                Keys.countryCode: countryCode?.rawValue,
                                Keys.cardReaderModel: cardReaderModel,
                                Keys.receiptSource: source.rawValue
                              ].compactMapValues { $0 })
        }

        /// Tracked when sending or saving the receipt email failed.
        /// - Parameters:
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptEmailFailed(error: Error, countryCode: CountryCode? = nil, cardReaderModel: String? = nil, source: ReceiptSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailFailed,
                              properties: [
                                Keys.countryCode: countryCode?.rawValue,
                                Keys.cardReaderModel: cardReaderModel,
                                Keys.receiptSource: source.rawValue
                              ].compactMapValues { $0 },
                              error: error)
        }

        /// Tracked when the user canceled sending the receipt by email.
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func receiptEmailCanceled(countryCode: CountryCode?, cardReaderModel: String?, source: ReceiptSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailCanceled,
                              properties: [
                                Keys.countryCode: countryCode?.rawValue,
                                Keys.cardReaderModel: cardReaderModel,
                                Keys.receiptSource: source.rawValue
                              ].compactMapValues { $0 })
        }

        /// Tracked when the receipt was sent by email.
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptEmailSuccess(countryCode: CountryCode?, cardReaderModel: String?, source: ReceiptSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailSuccess,
                              properties: [
                                Keys.countryCode: countryCode?.rawValue,
                                Keys.cardReaderModel: cardReaderModel,
                                Keys.receiptSource: source.rawValue
                              ].compactMapValues { $0 })
        }

        /// Tracked when the user tapped on the button to print a receipt.
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptPrintTapped(countryCode: CountryCode?, cardReaderModel: String?, source: ReceiptSource) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode?.rawValue,
                Keys.cardReaderModel: cardReaderModel,
                Keys.receiptSource: source.rawValue
            ]
            return WooAnalyticsEvent(statName: .receiptPrintTapped,
                                     properties: properties.compactMapValues { $0 })
        }

        /// Tracked when printing the receipt failed.
        /// - Parameters:
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the country code of the store.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptPrintFailed(error: Error, countryCode: CountryCode? = nil, cardReaderModel: String? = nil, source: ReceiptSource) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode?.rawValue,
                Keys.cardReaderModel: cardReaderModel,
                Keys.receiptSource: source.rawValue
            ]
            return WooAnalyticsEvent(statName: .receiptPrintFailed,
                                     properties: properties.compactMapValues { $0 },
                                     error: error)
        }

        /// Tracked when the user canceled printing the receipt.
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the country code of the store.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptPrintCanceled(countryCode: CountryCode?, cardReaderModel: String?, source: ReceiptSource) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode?.rawValue,
                Keys.cardReaderModel: cardReaderModel,
                Keys.receiptSource: source.rawValue
            ]
            return WooAnalyticsEvent(statName: .receiptPrintCanceled,
                                     properties: properties.compactMapValues { $0 })
        }

        /// Tracked when the receipt was successfully sent to the printer. iOS won't guarantee that the receipt has actually printed.
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the country code of the store.
        ///   - source: whether is a local-generated, or backend-generated receipt.
        ///
        static func receiptPrintSuccess(countryCode: CountryCode?, cardReaderModel: String?, source: ReceiptSource) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode?.rawValue,
                Keys.cardReaderModel: cardReaderModel,
                Keys.receiptSource: source.rawValue
            ]
            return WooAnalyticsEvent(statName: .receiptPrintSuccess,
                                     properties: properties.compactMapValues { $0 })
        }

        /// Tracked when the backend-receipt fails to be fetched.
        ///   - Parameters:
        ///     - error: the error to be included in the event properties.
        ///
        static func receiptFetchFailed(error: Error) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.receiptSource: ReceiptSource.backend.rawValue
            ]
            return WooAnalyticsEvent(statName: .receiptFetchFailed, properties: properties, error: error)
        }

        enum ReceiptSource: String {
            case local
            case backend
        }

        enum LearnMoreLinkSource {
            case paymentsMenu
            case paymentMethods
            case tapToPaySummary
            case manageCardReader
            case aboutTapToPay

            var trackingValue: String {
                switch self {
                case .paymentsMenu:
                    return "payments_menu"
                case .paymentMethods:
                    return "payment_methods"
                case .tapToPaySummary:
                    return "tap_to_pay_summary"
                case .manageCardReader:
                    return "manage_card_reader"
                case .aboutTapToPay:
                    return "about_tap_to_pay"
                }
            }
        }

        static func learnMoreTapped(source: LearnMoreLinkSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .inPersonPaymentsLearnMoreTapped, properties: ["source": source.trackingValue])
        }
    }
}

// MARK: - Deposit Summary
//
extension WooAnalyticsEvent {
    enum DepositSummary {
        enum Keys {
            static let numberOfCurrencies = "number_of_currencies"
            static let currency = "currency"
        }

        static func depositSummaryShown(numberOfCurrencies: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsMenuDepositSummaryShown,
                              properties: [Keys.numberOfCurrencies: numberOfCurrencies])
        }

        static func depositSummaryError(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsMenuDepositSummaryError, properties: [:], error: error)
        }

        static func depositSummaryCurrencySelected(currency: CurrencyCode) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsMenuDepositSummaryCurrencySelected,
                              properties: [Keys.currency: currency.rawValue])
        }
    }
}

// MARK: - Close Account
//
extension WooAnalyticsEvent {
    /// The source that presents the Jetpack install screen.
    enum CloseAccountSource: String {
        case settings
        case emptyStores = "empty_stores"
    }

    /// Tracked when the user taps to close their WordPress.com account.
    static func closeAccountTapped(source: CloseAccountSource) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .closeAccountTapped, properties: ["source": source.rawValue])
    }

    /// Tracked when the WordPress.com account closure succeeds.
    static func closeAccountSuccess() -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .closeAccountSuccess, properties: [:])
    }

    /// Tracked when the WordPress.com account closure fails.
    static func closeAccountFailed(error: Error) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .closeAccountFailed, properties: [:], error: error)
    }
}

private extension PaymentMethod {
    var analyticsValue: String {
        switch self {
        case .card, .cardPresent:
            return "card"
        case .interacPresent:
            return "card_interac"
        case .unknown:
            return "unknown"
        }
    }
}

// MARK: - Login Jetpack Setup
//
extension WooAnalyticsEvent {
    enum LoginJetpackSetup {
        /// The source that user sets up Jetpack: on the web or natively on the app.
        enum Source: String {
            case web
            case native
        }

        enum Step: String {
            case automaticInstall = "automatic_install"
            case wpcomLogin = "wpcom_login"
            case authorize
            case siteLogin = "site_login"
            case pluginDetail = "plugin_detail"
            case pluginInstallation = "plugin_installation"
            case pluginActivation = "plugin_activation"
            case pluginSetup = "plugin_setup"
        }

        enum Key: String {
            case source
            case step
        }

        /// Tracks when the user dismisses Jetpack Setup flow.
        static func setupDismissed(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginJetpackSetupDismissed, properties: [Key.source.rawValue: source.rawValue])
        }

        /// Tracks when the user completes Jetpack Setup flow.
        static func setupCompleted(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginJetpackSetupCompleted, properties: [Key.source.rawValue: source.rawValue])
        }

        /// Tracks when the user reaches a new step in the setup flow
        static func setupFlow(source: Source, step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginJetpackSetupFlow, properties: [Key.source.rawValue: source.rawValue,
                                                                             Key.step.rawValue: step.rawValue])
        }
    }
}

// MARK: - Login WooCommerce Setup
//
extension WooAnalyticsEvent {
    enum LoginWooCommerceSetup {
        /// The source that user sets up WooCommerce: on the web or natively on the app.
        enum Source: String {
            case web
            case native
        }

        enum Key: String {
            case source
        }

        /// Tracks when the user dismisses the WooCommerce Setup flow.
        static func setupDismissed(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginWooCommerceSetupDismissed, properties: [Key.source.rawValue: source.rawValue])
        }

        /// Tracks when the user completes the WooCommerce Setup flow.
        static func setupCompleted(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginWooCommerceSetupCompleted, properties: [Key.source.rawValue: source.rawValue])
        }
    }
}


// MARK: - Waiting Time measurement
//
extension WooAnalyticsEvent {
    enum WaitingTime {
        /// Possible Waiting time scenarios
        enum Scenario {
            case orderDetails
            case dashboardTopPerformers
            case dashboardMainStats
            case analyticsHub
            case appStartup
        }

        private enum Keys {
            static let waitingTime = "waiting_time"
        }

        static func waitingFinished(scenario: Scenario, elapsedTime: TimeInterval) -> WooAnalyticsEvent {
            switch scenario {
            case .orderDetails:
                return WooAnalyticsEvent(statName: .orderDetailWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .dashboardTopPerformers:
                return WooAnalyticsEvent(statName: .dashboardTopPerformersWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .dashboardMainStats:
                return WooAnalyticsEvent(statName: .dashboardMainStatsWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .analyticsHub:
                return WooAnalyticsEvent(statName: .analyticsHubWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            case .appStartup:
                return WooAnalyticsEvent(statName: .applicationOpenedWaitingTimeLoaded, properties: [Keys.waitingTime: elapsedTime])
            }
        }
    }
}

// MARK: - Site picker
//
extension WooAnalyticsEvent {
    enum SitePicker {

        enum Key: String {
            case hasWordPress = "has_wordpress"
            case isWPCom = "is_wpcom"
            case isJetpackInstalled = "is_jetpack_installed"
            case isJetpackActive = "is_jetpack_active"
            case isJetpackConnected = "is_jetpack_connected"
        }

        /// Tracks when the result for site discovery is returned
        static func siteDiscovery(hasWordPress: Bool,
                                  isWPCom: Bool,
                                  isJetpackInstalled: Bool,
                                  isJetpackActive: Bool,
                                  isJetpackConnected: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .sitePickerSiteDiscovery, properties: [Key.hasWordPress.rawValue: hasWordPress,
                                                                               Key.isWPCom.rawValue: isWPCom,
                                                                               Key.isJetpackInstalled.rawValue: isJetpackInstalled,
                                                                               Key.isJetpackActive.rawValue: isJetpackActive,
                                                                               Key.isJetpackConnected.rawValue: isJetpackConnected])
        }

        /// Tracks when the user taps the New To WooCommerce button
        ///
        static func newToWooTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .sitePickerNewToWooTapped, properties: [:])
        }
    }
}

// MARK: - Universal Links
//
extension WooAnalyticsEvent {
    enum Key: String {
        case path = "path"
        case url = "url"
    }

    static func universalLinkOpened(with path: String) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .universalLinkOpened, properties: [Key.path.rawValue: path])
    }

    static func universalLinkFailed(with url: URL) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .universalLinkFailed, properties: [Key.url.rawValue: url.absoluteString])
    }
}

// MARK: - Jetpack connection
//
extension WooAnalyticsEvent {
    enum LoginJetpackConnection {
        enum Key: String {
            case selfHosted = "is_selfhosted_site"
        }

        static func jetpackConnectionErrorShown(selfHostedSite: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginJetpackConnectionErrorShown, properties: [Key.selfHosted.rawValue: selfHostedSite])
        }
    }
}

// MARK: - Widgets {
extension WooAnalyticsEvent {
    enum Widgets {
        enum Key: String {
            case name = "name"
        }

        enum Name: String {
            case todayStats = "today-stats"
            case appLink = "app-link"
        }

        /// Event when a widget is tapped and opens the app.
        ///
        static func widgetTapped(name: Name, family: String? = nil) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType]
            if let family {
                properties = [Key.name.rawValue: "\(name.rawValue)-\(family)"]
            } else {
                properties = [Key.name.rawValue: name.rawValue]
            }
            return WooAnalyticsEvent(statName: .widgetTapped, properties: properties)
        }
    }
}

// MARK: - Products Onboarding
//
extension WooAnalyticsEvent {
    enum ProductsOnboarding {
        enum Keys: String {
            case type
            case horizontalSizeClass = "horizontal_size_class"
        }

        static func productListAddProductButtonTapped(horizontalSizeClass: UIUserInterfaceSizeClass) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListAddProductTapped, properties: [Keys.horizontalSizeClass.rawValue: horizontalSizeClass.nameForAnalytics])
        }
    }
}

// MARK: - Products List
//
extension WooAnalyticsEvent {
    enum ProductsList {
        enum Keys: String {
            case property
            case selectedProductsCount = "selected_products_count"
            case isEligibleForSubscriptions = "is_eligible_for_subscriptions"
        }

        enum BulkUpdateField: String {
            case price
            case status
        }

        static func productListLoaded(isEligibleForSubscriptions: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListLoaded,
                              properties: [Keys.isEligibleForSubscriptions.rawValue: isEligibleForSubscriptions]
            )
        }

        static func bulkUpdateRequested(field: BulkUpdateField, selectedProductsCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListBulkUpdateRequested, properties: [Keys.property.rawValue: field.rawValue,
                                                                                      Keys.selectedProductsCount.rawValue: Int64(selectedProductsCount)])
        }

        static func bulkUpdateConfirmed(field: BulkUpdateField, selectedProductsCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListBulkUpdateConfirmed, properties: [Keys.property.rawValue: field.rawValue,
                                                                                      Keys.selectedProductsCount.rawValue: Int64(selectedProductsCount)])
        }

        static func bulkUpdateSuccess(field: BulkUpdateField) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListBulkUpdateSuccess, properties: [Keys.property.rawValue: field.rawValue])
        }

        static func bulkUpdateFailure(field: BulkUpdateField) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListBulkUpdateFailure, properties: [Keys.property.rawValue: field.rawValue])
        }

        static func bulkUpdateSelectAllTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListBulkUpdateSelectAllTapped, properties: [:])
        }
    }
}

// MARK: - Analytics Hub
//
extension WooAnalyticsEvent {
    enum AnalyticsHub {
        enum Keys: String {
            case option
            case calendar
            case timezone
            case report
            case period
            case compare
            case enabledCards = "enabled_cards"
            case disabledCards = "disabled_cards"
            case card
            case selectedMetric = "selected_metric"
        }

        /// Tracks when the "See more" button is tapped in My Store, to open the Analytics Hub.
        ///
        static func seeMoreAnalyticsTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .dashboardSeeMoreAnalyticsTapped, properties: [:])
        }

        /// Tracks when the date range selector button is tapped.
        ///
        static func dateRangeButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubDateRangeButtonTapped, properties: [:])
        }

        /// Tracks when a date range option is selected like “today”, “yesterday”, or “custom”.
        ///
        static func dateRangeOptionSelected(_ option: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubDateRangeOptionSelected, properties: [Keys.option.rawValue: option])
        }

        /// Tracks when the date range selection fails, due to an error generating the date range from the selection.
        /// Includes the current device calendar and timezone, for debugging the failure.
        ///
        static func dateRangeSelectionFailed(for option: AnalyticsHubTimeRangeSelection.SelectionType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubDateRangeSelectionFailed, properties: [Keys.option.rawValue: option.tracksIdentifier,
                                                                                            Keys.calendar.rawValue: Locale.current.calendar.debugDescription,
                                                                                            Keys.timezone.rawValue: TimeZone.current.debugDescription])
        }

        /// Tracks when the "Enable Jetpack Stats" call to action is shown.
        ///
        static func jetpackStatsCTAShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubEnableJetpackStatsShown, properties: [:])
        }

        /// Tracks when the "Enable Jetpack Stats" call to action is tapped.
        ///
        static func jetpackStatsCTATapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubEnableJetpackStatsTapped, properties: [:])
        }

        /// Tracks when the Jetpack Stats module is successfully enabled remotely.
        ///
        static func enableJetpackStatsSuccess() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubEnableJetpackStatsSuccess, properties: [:])
        }

        /// Tracks when the Jetpack Stats module fails to be enabled remotely.
        ///
        static func enableJetpackStatsFailed(error: Error?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubEnableJetpackStatsFailed, properties: [:], error: error)
        }

        /// Tracks when the link to view a full analytics report is tapped on a card in the Analytics Hub.
        ///
        static func viewFullReportTapped(for report: AnalyticsWebReport.ReportType,
                                         period: AnalyticsHubTimeRangeSelection.SelectionType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubViewFullReportTapped, properties: [
                Keys.report.rawValue: report.rawValue,
                Keys.period.rawValue: period.tracksIdentifier,
                Keys.compare.rawValue: "previous_period" // For now this is the only compare option in the app
            ])
        }

        /// Tracks when the Analytics Hub settings ("Customize Analytics") are opened.
        ///
        static func customizeAnalyticsOpened() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubSettingsOpened, properties: [:])
        }

        /// Tracks when the Analytics Hub settings ("Customize Analytics) are saved.
        ///
        static func customizeAnalyticsSaved(cards: [AnalyticsCard]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubSettingsSaved, properties: [
                Keys.enabledCards.rawValue: cards.filter { $0.enabled }.map { $0.type.rawValue }.joined(separator: ","),
                Keys.disabledCards.rawValue: cards.filter { !$0.enabled }.map { $0.type.rawValue }.joined(separator: ",")
            ])
        }

        /// Tracks when a new metric is selected on a card in the Analytics Hub.
        ///
        static func selectedMetric(_ selectedMetric: String, for cardType: AnalyticsCard.CardType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .analyticsHubCardMetricSelected, properties: [
                Keys.card.rawValue: cardType.rawValue,
                Keys.selectedMetric.rawValue: selectedMetric
            ])
        }
    }
}

// MARK: - REST API Login
//
extension WooAnalyticsEvent {
    enum Login {
        enum Key: String {
            case step
            case currentRoles = "current_roles"
            case exists
            case hasWordPress = "is_wordpress"
            case isWPCom = "is_wp_com"
            case isJetpackInstalled = "has_jetpack"
            case isJetpackActive = "is_jetpack_active"
            case isJetpackConnected = "is_jetpack_connected"
            case urlAfterRedirects = "url_after_redirects"
        }

        enum LoginSiteCredentialStep: String {
            case authentication
            case applicationPasswordGeneration = "application_password_generation"
            case wooStatus = "woo_status"
            case userRole = "user_role"
        }

        /// Tracks when the user attempts to log in with insufficient roles.
        ///
        static func insufficientRole(currentRoles: [String]) -> WooAnalyticsEvent {
            let roles = String(currentRoles.sorted().joined(by: ","))
            return WooAnalyticsEvent(statName: .loginInsufficientRole,
                                     properties: [Key.currentRoles.rawValue: roles])
        }

        /// Tracks when the login with site credentials failed.
        ///
        static func siteCredentialFailed(step: LoginSiteCredentialStep, error: Error?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginSiteCredentialsFailed,
                              properties: [Key.step.rawValue: step.rawValue],
                              error: error)
        }

        /// Tracks when site info is fetched during site address login.
        ///
        static func siteInfoFetched(exists: Bool,
                                    hasWordPress: Bool,
                                    isWPCom: Bool,
                                    isJetpackInstalled: Bool,
                                    isJetpackActive: Bool,
                                    isJetpackConnected: Bool,
                                    urlAfterRedirects: String) -> WooAnalyticsEvent {
            .init(statName: .loginSiteAddressSiteInfoFetched, properties: [
                Key.exists.rawValue: exists,
                Key.hasWordPress.rawValue: hasWordPress,
                Key.isWPCom.rawValue: isWPCom,
                Key.isJetpackInstalled.rawValue: isJetpackInstalled,
                Key.isJetpackActive.rawValue: isJetpackActive,
                Key.isJetpackConnected.rawValue: isJetpackConnected,
                Key.urlAfterRedirects.rawValue: urlAfterRedirects
            ])
        }
    }
}

// MARK: - Application password authorization in web view
//
extension WooAnalyticsEvent {
    enum ApplicationPasswordAuthorization {
        enum Key: String {
            case step
        }

        enum Step: String {
            case initial
            case login
            case authorization
        }

        static func webViewShown(step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .applicationPasswordAuthorizationWebViewShown,
                              properties: [Key.step.rawValue: step.rawValue])
        }

        static func invalidLoginPageDetected() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginSiteCredentialsInvalidLoginPageDetected, properties: [:])
        }

        static func explanationDismissed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginSiteCredentialsAppPasswordExplanationDismissed, properties: [:])
        }

        static func explanationContactSupportTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginSiteCredentialsAppPasswordExplanationContactSupportTapped, properties: [:])
        }

        static func explanationContinueButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginSiteCredentialsAppPasswordExplanationContinueButtonTapped, properties: [:])
        }

        static func loginExitConfirmation() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginSiteCredentialsAppPasswordLoginExitConfirmation, properties: [:])
        }

        static func loginDismissed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginSiteCredentialsAppPasswordLoginDismissed, properties: [:])
        }

    }
}

// MARK: - In-App Purchases
extension WooAnalyticsEvent {
    enum InAppPurchases {
        enum Keys: String {
            case productID = "product_id"
            case source
            case step
            case error
        }

        enum Source: String {
            case banner
        }

        enum Step: String {
            case planDetails = "plan_details"
            case prePurchaseError = "pre_purchase_error"
            case purchaseUpgradeError = "purchase_upgrade_error"
            case processing
            case completed
        }

        static func planUpgradePurchaseButtonTapped(_ productID: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .planUpgradePurchaseButtonTapped,
                              properties: [Keys.productID.rawValue: productID])
        }

        static func planUpgradeScreenLoaded(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .planUpgradeScreenLoaded,
                              properties: [Keys.source.rawValue: source.rawValue])
        }

        static func planUpgradeScreenDismissed(step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .planUpgradeScreenDismissed,
                              properties: [Keys.step.rawValue: step.rawValue])
        }

        static func planUpgradePrePurchaseFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .planUpgradePurchaseFailed,
                              properties: [Keys.error.rawValue: error.localizedDescription],
                              error: error)
        }

        static func planUpgradePurchaseFailed(error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .planUpgradePurchaseFailed,
                              properties: [Keys.error.rawValue: error.localizedDescription],
                              error: error)
        }
    }
}

// MARK: - EU Shipping Notice Banner
//
extension WooAnalyticsEvent {
    enum EUShippingNotice {
        static func onEUShippingNoticeBannerShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .euShippingNoticeShown, properties: [:])
        }

        static func onEUShippingNoticeBannerDismissed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .euShippingNoticeDismissed, properties: [:])
        }

        static func onEUShippingNoticeLearnMoreTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .euShippingNoticeLearnMoreTapped, properties: [:])
        }
    }
}


// MARK: - Privacy Choices Banner
//
extension WooAnalyticsEvent {
    enum PrivacyChoicesBanner {
        static func bannerPresented() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .privacyChoicesBannerPresented, properties: [:])
        }

        static func settingsButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .privacyChoicesSettingsButtonTapped, properties: [:])
        }

        static func saveButtonTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .privacyChoicesSaveButtonTapped, properties: [:])
        }
    }
}

// MARK: - Shipping Label Hazmat Declaration
//
extension WooAnalyticsEvent {
    enum ShippingLabelHazmatDeclaration {
        enum Keys: String {
            case orderID = "order_id"
            case category
        }

        static func hazmatCategorySelectorOpened() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .hazmatCategorySelectorOpened, properties: [:])
        }

        static func hazmatCategorySelected(orderID: Int64, selectedCategory: ShippingLabelHazmatCategory) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .hazmatCategorySelected, properties: [Keys.orderID.rawValue: orderID,
                                                                              Keys.category.rawValue: selectedCategory.rawValue])
        }

        static func containsHazmatChecked() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .containsHazmatChecked, properties: [:])
        }
    }
}

// MARK: - App Login Deep Link
//
extension WooAnalyticsEvent {
    enum AppLoginDeepLink {
        enum Keys: String {
            case flow
            case url
        }

        enum Flows: String {
            case wpCom = "wp_com"
            case noWpCom = "no_wp_com"
        }

        static func appLoginLinkSuccess(flow: Flows) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginAppLoginLinkSuccess, properties: [Keys.flow.rawValue: flow.rawValue])
        }

        static func appLoginLinkMalformed(url: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .loginMalformedAppLoginLink, properties: [Keys.url.rawValue: url])
        }
    }
}

// MARK: - Remote Requests
//
extension WooAnalyticsEvent {
    enum RemoteRequest {
        enum Keys: String {
            case path
            case entityName = "entity"
            case debugDecodingPath = "debug_decoding_path"
            case debugDecodingDescription = "debug_decoding_description"
        }

        static func jsonParsingError(_ error: Error, path: String?, entityName: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .apiJSONParsingError,
                              properties: [
                                Keys.path.rawValue: path,
                                Keys.entityName.rawValue: entityName,
                                Keys.debugDecodingPath.rawValue: (error as? DecodingError)?.debugPath,
                                Keys.debugDecodingDescription.rawValue: (error as? DecodingError)?.debugDescription
                              ].compactMapValues { $0 },
                              error: error)
        }
    }
}

// MARK: - Barcode Scanning
//
extension WooAnalyticsEvent {
    enum BarcodeScanning {
        private enum Keys {
            static let barcodeFormat = "barcode_format"
            static let reason = "reason"
            static let source = "source"
        }

        enum Source: String {
            case orderCreation = "order_creation"
            case orderList = "order_list"
            case productList = "product_list"
            case scanToUpdateInventory = "scan_to_update_inventory"
        }

        enum BarcodeScanningFailureReason: String {
            case cameraAccessNotPermitted = "camera_access_not_permitted"
        }

        static func barcodeScanningSuccess(from source: BarcodeScanning.Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .barcodeScanningSuccess, properties: [Keys.source: source.rawValue])
        }

        static func barcodeScanningFailure(from source: BarcodeScanning.Source, reason: BarcodeScanningFailureReason) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .barcodeScanningFailure, properties: [Keys.source: source.rawValue,
                                                                              Keys.reason: reason.rawValue])
        }

        static func productSearchViaSKUSuccess(from source: String, stockManaged: Bool? = nil) -> WooAnalyticsEvent {
            var properties = [Keys.source: source]

            if let stockManaged = stockManaged {
                properties["stock_managed"] = "\(stockManaged)"
            }
            return WooAnalyticsEvent(statName: .orderProductSearchViaSKUSuccess, properties: properties)
        }

        static func productSearchViaSKUFailure(from source: String,
                                                    symbology: BarcodeSymbology? = nil,
                                                    reason: String) -> WooAnalyticsEvent {

            var properties = [Keys.source: source,
                              Keys.reason: reason]

            if let symbology = symbology {
                properties[Keys.barcodeFormat] = symbology.rawValue
            }

            return WooAnalyticsEvent(statName: .orderProductSearchViaSKUFailure, properties: properties)
        }
    }
}

// MARK: - Customers in Hub Menu

extension WooAnalyticsEvent {
    enum CustomersHub {
        private enum Keys {
            static let searchFilter = "filter"
            static let registered = "registered"
            static let hasEmail = "has_email_address"
        }

        /// Possible actions to take in customer details
        enum Action: String {
            fileprivate static let key = "action"

            case call = "phone_call"
            case message = "text_message"
            case copyPhone = "copy_phone_number"
            case whatsapp = "whatsapp"
            case telegram = "telegram"
        }

        /// Possible addresses in customer details
        enum Address: String {
            fileprivate static let key = "address"

            case shipping = "shipping_address"
            case billing = "billing_address"
        }

        static func customerListLoaded() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customerHubLoaded, properties: [:])
        }

        static func customerListLoadFailed(withError error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customerHubLoadFailed, properties: [:], error: error)
        }

        static func customerListSearched(withFilter filter: CustomerSearchFilter) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubSearch, properties: [Keys.searchFilter: filter.rawValue])
        }

        static func customerDetailOpened(registered: Bool, hasEmail: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailOpen, properties: [Keys.registered: registered,
                                                                              Keys.hasEmail: hasEmail])
        }

        static func customerDetailEmailMenuTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailEmailMenuTapped, properties: [:])
        }

        static func customerDetailEmailOptionTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailEmailOptionTapped, properties: [:])
        }

        static func customerDetailCopyEmailOptionTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailCopyEmailOptionTapped, properties: [:])
        }

        static func customerDetailPhoneMenuTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailPhoneMenuTapped, properties: [:])
        }

        static func customerDetailActionTapped(_ action: Action) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailPhoneActionTapped, properties: [Action.key: action.rawValue])
        }

        static func customerDetailAddressCopied(_ address: Address) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailAddressCopied, properties: [Address.key: address.rawValue])
        }

        static func customerDetailNewOrder() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customersHubDetailNewOrderTapped, properties: [:])
        }
    }
}

// MARK: - Plugin events
//
extension WooAnalyticsEvent {
    static func logOutOfDatePlugins(_ outOfDatePluginCount: Int, _ pluginList: String) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .outOfDatePluginList, properties: [
            "out_of_date_plugin_count": outOfDatePluginCount,
            "plugins": "\(pluginList)"
        ])
    }
}
