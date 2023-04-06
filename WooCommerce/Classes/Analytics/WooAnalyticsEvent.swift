import Foundation
import Yosemite

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
public struct WooAnalyticsEvent {
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
        /// Shown in IPP banner for eligible merchants with no IPP transactions.
        case inPersonPaymentsCashOnDeliveryBanner
        /// Shown in IPP banner for eligible merchants with a few IPP transactions.
        case inPersonPaymentsFirstTransactionBanner
        /// Shown in IPP banner for eligible merchants with a significant number of IPP transactions.
        case inPersonPaymentsPowerUsersBanner
        /// Shown in store setup task list
        case storeSetup = "store_setup"
        /// Tap to Pay on iPhone feedback button shown in the Payments menu after the first payment with TTP
        case tapToPayFirstPaymentPaymentsMenu
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

    static func ordersListLoaded(totalDuration: TimeInterval, pageNumber: Int, filters: FilterOrderListViewModel.Filters?) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .ordersListLoaded, properties: [
            "status": (filters?.orderStatus ?? []).map { $0.rawValue }.joined(separator: ","),
            "page_number": Int64(pageNumber),
            "total_duration": Double(totalDuration),
            "date_range": filters?.dateRange?.analyticsDescription ?? String()
        ])
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
        static func loaded(hasLinkedProducts: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productDetailLoaded, properties: ["has_linked_products": hasLinkedProducts])
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
        }

        /// Possible item types to add to an Order
        ///
        enum ProductType: String {
            case product
            case variation
        }

        enum GlobalKeys {
            static let millisecondsSinceOrderAddNew = "milliseconds_since_order_add_new"
        }

        private enum Keys {
            static let flow = "flow"
            static let hasDifferentShippingDetails = "has_different_shipping_details"
            static let orderStatus = "order_status"
            static let productCount = "product_count"
            static let hasCustomerDetails = "has_customer_details"
            static let hasFees = "has_fees"
            static let hasShippingMethod = "has_shipping_method"
            static let errorContext = "error_context"
            static let errorDescription = "error_description"
            static let to = "to"
            static let from = "from"
            static let orderID = "id"
            static let hasMultipleShippingLines = "has_multiple_shipping_lines"
            static let hasMultipleFeeLines = "has_multiple_fee_lines"
            static let itemType = "item_type"
            static let source = "source"
        }

        static func orderOpen(order: Order) -> WooAnalyticsEvent {
            let customFieldsSize = order.customFields.map { $0.value.utf8.count }.reduce(0, +) // Total byte size of custom field values
            return WooAnalyticsEvent(statName: .orderOpen, properties: ["id": order.orderID,
                                                                        "status": order.status.rawValue,
                                                                        "custom_fields_count": Int64(order.customFields.count),
                                                                        "custom_fields_size": Int64(customFieldsSize)])
        }

        static func orderAddNew() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderAddNew, properties: [:])
        }

        static func orderEditButtonTapped(hasMultipleShippingLines: Bool, hasMultipleFeeLines: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderEditButtonTapped, properties: [
                Keys.hasMultipleShippingLines: hasMultipleShippingLines,
                Keys.hasMultipleFeeLines: hasMultipleFeeLines
            ])
        }

        static func orderProductAdd(flow: Flow, productCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductAdd, properties: [
                Keys.flow: flow.rawValue,
                Keys.productCount: Int64(productCount)
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

        static func orderFeeAdd(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderFeeAdd, properties: [Keys.flow: flow.rawValue])
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

        static func orderShippingMethodAdd(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderShippingMethodAdd, properties: [Keys.flow: flow.rawValue])
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

        static func orderCreateButtonTapped(status: OrderStatusEnum,
                                            productCount: Int,
                                            hasCustomerDetails: Bool,
                                            hasFees: Bool,
                                            hasShippingMethod: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreateButtonTapped, properties: [
                Keys.orderStatus: status.rawValue,
                Keys.productCount: Int64(productCount),
                Keys.hasCustomerDetails: hasCustomerDetails,
                Keys.hasFees: hasFees,
                Keys.hasShippingMethod: hasShippingMethod
            ])
        }

        static func orderCreationSuccess(millisecondsSinceSinceOrderAddNew: Int64?) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [:]

            if let lapseSinceLastOrderAddNew = millisecondsSinceSinceOrderAddNew {
                properties[GlobalKeys.millisecondsSinceOrderAddNew] = lapseSinceLastOrderAddNew
            }

            return WooAnalyticsEvent(statName: .orderCreationSuccess, properties: properties)
        }

        static func orderCreationFailed(errorContext: String, errorDescription: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationFailed, properties: [
                Keys.errorContext: errorContext,
                Keys.errorDescription: errorDescription
            ])
        }

        static func orderSyncFailed(flow: Flow, errorContext: String, errorDescription: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderSyncFailed, properties: [
                Keys.flow: flow.rawValue,
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

        static func orderCreationProductSelectorConfirmButtonTapped(productCount: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductSelectorConfirmButtonTapped, properties: [
                Keys.productCount: Int64(productCount)
            ])
        }

        static func orderCreationProductSelectorClearSelectionButtonTapped(productType: ProductType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationProductSelectorClearSelectionButtonTapped, properties: [
                Keys.source: productType.rawValue + "_selector"
            ])
        }

        /// Tracked when the user taps to collect a payment
        ///
        static func collectPaymentTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentTapped,
                              properties: [:])
        }

        /// Tracked when accessing the system plugin list without it being in sync.
        ///
        static func pluginsNotSyncedYet() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pluginsNotSyncedYet, properties: [:])
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
        /// Possible Payment Methods
        ///
        enum PaymentMethod: String {
            case card
            case cash
            case paymentLink = "payment_link"
        }

        /// Possible view sources
        ///
        enum Source: String {
            case amount
            case summary
            case paymentMethod = "payment_method"
        }

        /// Common event keys
        ///
        private enum Keys {
            static let state = "state"
            static let amount = "amount"
            static let paymentMethod = "payment_method"
            static let source = "source"
        }

        static func simplePaymentsFlowStarted() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowStarted, properties: [:])
        }

        static func simplePaymentsFlowNoteAdded() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowNoteAdded, properties: [:])
        }

        static func simplePaymentsFlowTaxesToggled(isOn: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowTaxesToggled, properties: [Keys.state: isOn ? "on" : "off"])
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
            static let paymentMethod = "payment_method"
            static let source = "source"
            static let flow = "flow"
            static let cardReaderType = "card_reader_type"
        }

        static func paymentsFlowCompleted(flow: Flow,
                                          amount: String,
                                          method: PaymentMethod,
                                          cardReaderType: CardReaderType?) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [Keys.flow: flow.rawValue,
                                                                       Keys.amount: amount,
                                                                       Keys.paymentMethod: method.rawValue]

            if let cardReaderType = cardReaderType {
                properties[Keys.cardReaderType] = cardReaderType.rawValue
            }

            return WooAnalyticsEvent(statName: .paymentsFlowCompleted, properties: properties)
        }

        static func paymentsFlowCanceled(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsFlowCanceled, properties: [Keys.flow: flow.rawValue])
        }

        static func paymentsFlowFailed(flow: Flow, source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsFlowFailed, properties: [Keys.flow: flow.rawValue,
                                                                          Keys.source: source.rawValue])
        }

        static func paymentsFlowCollect(flow: Flow,
                                        method: PaymentMethod,
                                        cardReaderType: CardReaderType?,
                                        millisecondsSinceOrderAddNew: Int64?) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [Keys.flow: flow.rawValue,
                              Keys.paymentMethod: method.rawValue]

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
        }

        static let unknownGatewayID = "unknown"

        static func gatewayID(forGatewayID gatewayID: String?) -> String {
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
        static func cardReaderSelectTypeShown(forGatewayID: String?, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSelectTypeShown,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID)
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
        static func cardReaderSelectTypeBuiltInTapped(forGatewayID: String?, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSelectTypeBuiltInTapped,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID)
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
        static func cardReaderSelectTypeBluetoothTapped(forGatewayID: String?, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSelectTypeBluetoothTapped,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID)
                              ]
            )
        }

        /// Tracked when we automatically disconnect a Built In reader, when Manage Card Reader is opened
        ///
        /// - Parameters:
        ///   - forGatewayID: the plugin (e.g. "woocommerce-payments" or "woocommerce-gateway-stripe") to be included in the event properties in Tracks.
        ///   - countryCode: the country code of the store.
        ///
        static func manageCardReadersBuiltInReaderAutoDisconnect(forGatewayID: String?, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .manageCardReadersBuiltInReaderAutoDisconnect,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID)
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
        static func cardReaderAutomaticDisconnect(cardReaderModel: String?, forGatewayID: String?, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderAutomaticDisconnect,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID)
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
                                              countryCode: String,
                                              siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderDiscoveryFailed,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
                                Keys.errorDescription: error.localizedDescription,
                                Keys.siteID: siteID
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
                                                countryCode: String,
                                                cardReaderModel: String?) -> WooAnalyticsEvent {
            var properties = [
                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                Keys.countryCode: countryCode,
                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID)
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
                                               countryCode: String,
                                               cardReaderModel: String?,
                                               siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderConnectionFailed,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
                                Keys.errorDescription: error.localizedDescription,
                                Keys.siteID: siteID
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
        static func cardReaderDisconnectTapped(forGatewayID: String?, countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderDisconnectTapped,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID)
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
                                                   countryCode: String,
                                                   cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateTapped,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                                    countryCode: String,
                                                    cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateStarted,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                                   countryCode: String,
                                                   cardReaderModel: String
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateFailed,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                                    countryCode: String,
                                                    cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateSuccess,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                                         countryCode: String,
                                                         cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateCancelTapped,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                                     countryCode: String,
                                                     cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardReaderSoftwareUpdateCanceled,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                         countryCode: String,
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
                Keys.countryCode: countryCode,
                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                           countryCode: String,
                                           cardReaderModel: String?,
                                           cancellationSource: CancellationSource,
                                           siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectPaymentCanceled,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                          countryCode: String,
                                          paymentMethod: PaymentMethod,
                                          cardReaderModel: String?,
                                          millisecondsSinceOrderAddNew: Int64?,
                                          millisecondsSinceCardPaymentStarted: Int64?,
                                          siteID: Int64) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                Keys.countryCode: countryCode,
                Keys.gatewayID: gatewayID(forGatewayID: forGatewayID),
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
                                                 countryCode: String,
                                                 cardReaderModel: String?,
                                                 siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .collectInteracPaymentSuccess,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: self.gatewayID(forGatewayID: gatewayID),
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
                                         countryCode: String,
                                         cardReaderModel: String?,
                                         siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .interacRefundSuccess,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: self.gatewayID(forGatewayID: gatewayID),
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
                                        countryCode: String,
                                        cardReaderModel: String?,
                                        siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .interacRefundFailed,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: self.gatewayID(forGatewayID: gatewayID),
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
                                          countryCode: String,
                                          cardReaderModel: String?,
                                          siteID: Int64) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .interacRefundCanceled,
                              properties: [
                                Keys.cardReaderModel: readerModel(for: cardReaderModel),
                                Keys.countryCode: countryCode,
                                Keys.gatewayID: self.gatewayID(forGatewayID: gatewayID),
                                Keys.siteID: siteID
                              ])
        }

        /// Tracked when the "learn more" button in the In-Person Payments onboarding is tapped.
        ///
        /// - Parameter countryCode: the country code of the store.
        ///
        static func cardPresentOnboardingLearnMoreTapped(reason: String, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingLearnMoreTapped,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.reason: reason
                              ])
        }

        /// Tracked when the In-Person Payments onboarding cannot be completed for some reason.
        ///
        /// - Parameters:
        ///   - reason: the reason why the onboarding is not completed.
        ///   - countryCode: the country code of the store.
        ///
        static func cardPresentOnboardingNotCompleted(reason: String, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingNotCompleted,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.reason: reason
                              ])
        }

        /// Tracked when a In-Person Payments onboarding step is skipped by the user.
        ///
        /// - Parameters:
        ///   - reason: the reason why the onboarding step was shown (effectively the name of the step.)
        ///   - remindLater: whether the user will see this onboarding step again
        ///   - countryCode: the country code of the store.
        ///
        static func cardPresentOnboardingStepSkipped(reason: String, remindLater: Bool, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingStepSkipped,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.reason: reason,
                                Keys.remindLater: remindLater
                              ])
        }

        /// Tracked when a In-Person Payments onboarding step's CTA is tapped by the user.
        ///
        /// - Parameters:
        ///   - reason: the reason why the onboarding step was shown (effectively the name of the step.)
        ///   - countryCode: the country code of the store.
        ///
        static func cardPresentOnboardingCtaTapped(reason: String, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .cardPresentOnboardingCtaTapped,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.reason: reason
                              ])
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
        static func enableCashOnDeliverySuccess(countryCode: String, source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .enableCashOnDeliverySuccess,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.source: source.rawValue
                              ])
        }

        /// Tracked when the Cash on Delivery Payment Gateway enabling fails, e.g. from the IPP onboarding flow.
        ///
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - source: the screen which the enable attempt was made on
        ///
        static func enableCashOnDeliveryFailed(countryCode: String,
                                               error: Error?,
                                               source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .enableCashOnDeliveryFailed,
                              properties: [
                                Keys.countryCode: countryCode,
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
        static func disableCashOnDeliverySuccess(countryCode: String, source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .disableCashOnDeliverySuccess,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.source: source.rawValue
                              ])
        }

        /// Tracked when the Cash on Delivery Payment Gateway disabling fails, e.g. from the toggle on the Payments hub menu.
        ///
        /// - Parameters:
        ///   - countryCode: the country code of the store.
        ///   - source: the screen which the disable attempt was made on
        ///
        static func disableCashOnDeliveryFailed(countryCode: String,
                                               error: Error?,
                                               source: CashOnDeliverySource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .disableCashOnDeliveryFailed,
                              properties: [
                                Keys.countryCode: countryCode,
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
        static func paymentsHubCashOnDeliveryToggled(enabled: Bool, countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .paymentsHubCashOnDeliveryToggled,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.enabled: enabled
                              ])
        }

        /// Tracked when the user taps on the "See Receipt" button to view a receipt.
        /// - Parameter countryCode: the country code of the store.
        ///
        static func receiptViewTapped(countryCode: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptViewTapped,
                              properties: [Keys.countryCode: countryCode])
        }

        /// Tracked when the user taps on the "Email receipt" button after successfully collecting a payment to email a receipt.
        /// - Parameter countryCode: the country code of the store.
        /// - Parameter cardReaderModel: the model type of the card reader.
        ///
        static func receiptEmailTapped(countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailTapped,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.cardReaderModel: cardReaderModel
                              ].compactMapValues { $0 })
        }

        /// Tracked when sending or saving the receipt email failed.
        /// - Parameters:
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the model type of the card reader.
        ///
        static func receiptEmailFailed(error: Error, countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailFailed,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.cardReaderModel: cardReaderModel
                              ].compactMapValues { $0 },
                              error: error)
        }

        /// Tracked when the user canceled sending the receipt by email.
        /// - Parameter countryCode: the country code of the store.
        /// - Parameter cardReaderModel: the model type of the card reader.
        ///
        static func receiptEmailCanceled(countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailCanceled,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.cardReaderModel: cardReaderModel
                              ].compactMapValues { $0 })
        }

        /// Tracked when the receipt was sent by email.
        /// - Parameter countryCode: the country code of the store.
        ///
        static func receiptEmailSuccess(countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .receiptEmailSuccess,
                              properties: [
                                Keys.countryCode: countryCode,
                                Keys.cardReaderModel: cardReaderModel
                              ].compactMapValues { $0 })
        }

        /// Tracked when the user tapped on the button to print a receipt.
        /// - Parameter countryCode: the country code of the store.
        ///
        static func receiptPrintTapped(countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode,
                Keys.cardReaderModel: cardReaderModel
            ]
            return WooAnalyticsEvent(statName: .receiptPrintTapped,
                                     properties: properties.compactMapValues { $0 })
        }

        /// Tracked when printing the receipt failed.
        /// - Parameters:
        ///   - error: the error to be included in the event properties.
        ///   - countryCode: the country code of the store.
        ///   - cardReaderModel: the country code of the store.
        ///
        static func receiptPrintFailed(error: Error, countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode,
                Keys.cardReaderModel: cardReaderModel
            ]
            return WooAnalyticsEvent(statName: .receiptPrintFailed,
                                     properties: properties.compactMapValues { $0 },
                                     error: error)
        }

        /// Tracked when the user canceled printing the receipt.
        /// - Parameter countryCode: the country code of the store.
        /// - Parameter cardReaderModel: the country code of the store.
        ///
        static func receiptPrintCanceled(countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode,
                Keys.cardReaderModel: cardReaderModel
            ]
            return WooAnalyticsEvent(statName: .receiptPrintCanceled,
                                     properties: properties.compactMapValues { $0 })
        }

        /// Tracked when the receipt was successfully sent to the printer. iOS won't guarantee that the receipt has actually printed.
        /// - Parameter countryCode: the country code of the store.
        /// - Parameter cardReaderModel: the country code of the store.
        ///
        static func receiptPrintSuccess(countryCode: String, cardReaderModel: String?) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Keys.countryCode: countryCode,
                Keys.cardReaderModel: cardReaderModel
            ]
            return WooAnalyticsEvent(statName: .receiptPrintSuccess,
                                     properties: properties.compactMapValues { $0 })
        }

        enum LearnMoreLinkSource {
            case paymentsMenu
            case paymentMethods

            var trackingValue: String {
                switch self {
                case .paymentsMenu:
                    return "payments_menu"
                case .paymentMethods:
                    return "payment_methods"
                }
            }
        }

        static func learnMoreTapped(source: LearnMoreLinkSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .inPersonPaymentsLearnMoreTapped, properties: ["source": source.trackingValue])
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
            case templateEligible = "template_eligible"
        }

        enum CreationType: String {
            case manual
            case template
        }

        /// Tracks when a store is eligible for products onboarding
        ///
        static func storeIsEligible() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productsOnboardingEligible, properties: [:])
        }

        /// Tracks when the call to action is tapped on the products onboarding banner
        ///
        static func bannerCTATapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productsOnboardingCTATapped, properties: [:])
        }

        /// Trackas when the merchants selects a product creation type.
        ///
        static func productCreationTypeSelected(type: CreationType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addProductCreationTypeSelected, properties: [Keys.type.rawValue: type.rawValue])
        }

        static func productListAddProductButtonTapped(templateEligible: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .productListAddProductTapped, properties: [Keys.templateEligible.rawValue: templateEligible])
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
        }

        enum BulkUpdateField: String {
            case price
            case status
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

// MARK: - Free Trial
//
extension WooAnalyticsEvent {
    enum FreeTrial {
        enum Keys: String {
            case source
        }

        enum Source: String {
            case banner
            case upgradesScreen = "upgrades_screen"
        }

        static func freeTrialUpgradeNowTapped(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .freeTrialUpgradeNowTapped, properties: [Keys.source.rawValue: source.rawValue])
        }

        static func planUpgradeSuccess(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .planUpgradeSuccess, properties: [Keys.source.rawValue: source.rawValue])
        }

        static func planUpgradeAbandoned(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .planUpgradeAbandoned, properties: [Keys.source.rawValue: source.rawValue])
        }
    }
}
