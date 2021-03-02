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
        /// Shown in products banner for Milestone 4 features. New product banners should have
        /// their own `FeedbackContext` option.
        case productsM4 = "products_m4"
        /// Shown in shipping labels banner for Milestone 1 features.
        case shippingLabelsRelease1 = "shipping_labels_m1"
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

    static func ordersListLoaded(totalDuration: TimeInterval, pageNumber: Int, status: OrderStatus?) -> WooAnalyticsEvent {
        WooAnalyticsEvent(statName: .ordersListLoaded, properties: [
            "status": status?.slug ?? String(),
            "page_number": Int64(pageNumber),
            "total_duration": Double(totalDuration)
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
