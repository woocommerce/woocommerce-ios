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
    let statName: WooAnalyticsStat
    let properties: [String: WooAnalyticsEventPropertyType]
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
        /// Shown in products banner for Variations release.
        case productsVariations = "products_variations"
        /// Shown in shipping labels banner for Milestone 3 features.
        case shippingLabelsRelease3 = "shipping_labels_m3"
        /// Shown in beta feature banner for order add-ons.
        case addOnsI1 = "add-ons_i1"
        /// Shown in beta feature banner for simple payments prototype.
        case simplePaymentsPrototype = "simple_payments_prototype"
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
        }

        private enum Keys {
            static let flow = "flow"
            static let hasDifferentShippingDetails = "has_different_shipping_details"
            static let orderStatus = "order_status"
            static let productCount = "product_count"
            static let hasCustomerDetails = "has_customer_details"
            static let errorContext = "error_context"
            static let errorDescription = "error_description"
            static let to = "to"
            static let from = "from"
        }

        static func orderAddNew() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderAddNew, properties: [:])
        }

        static func orderProductAdd(flow: Flow) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderProductAdd, properties: [Keys.flow: flow.rawValue])
        }

        static func orderCustomerDetailsAdd(flow: Flow, hasDifferentShippingDetails: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCustomerAdd, properties: [
                Keys.flow: flow.rawValue,
                Keys.hasDifferentShippingDetails: hasDifferentShippingDetails
            ])
        }

        static func orderStatusChange(flow: Flow, from oldStatus: OrderStatus, to newStatus: OrderStatus) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderStatusChange, properties: [
                Keys.flow: flow.rawValue,
                Keys.from: oldStatus.slug,
                Keys.to: newStatus.slug
            ])
        }

        static func orderCreateButtonTapped(status: OrderStatus,
                                            productCount: Int,
                                            hasCustomerDetails: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreateButtonTapped, properties: [
                Keys.orderStatus: status.slug,
                Keys.productCount: Int64(productCount),
                Keys.hasCustomerDetails: hasCustomerDetails
            ])
        }

        static func orderCreationSuccess() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationSuccess, properties: [:])
        }

        static func orderCreationFailed(errorContext: String, errorDescription: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .orderCreationFailed, properties: [
                Keys.errorContext: errorContext,
                Keys.errorDescription: errorDescription
            ])
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

        static func simplePaymentsFlowCompleted(amount: String, method: PaymentMethod) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowCompleted, properties: [Keys.amount: amount, Keys.paymentMethod: method.rawValue])
        }

        static func simplePaymentsFlowCanceled() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowCanceled, properties: [:])
        }

        static func simplePaymentsFlowFailed(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowFailed, properties: [Keys.source: source.rawValue])
        }

        static func simplePaymentsFlowNoteAdded() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowNoteAdded, properties: [:])
        }

        static func simplePaymentsFlowTaxesToggled(isOn: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowTaxesToggled, properties: [Keys.state: isOn ? "on" : "off"])
        }

        static func simplePaymentsFlowCollect(method: PaymentMethod) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .simplePaymentsFlowCollect, properties: [Keys.paymentMethod: method.rawValue])
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
