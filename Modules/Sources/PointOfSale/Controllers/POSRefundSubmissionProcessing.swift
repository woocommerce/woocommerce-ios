import Foundation
import Observation
import struct Yosemite.CardReaderInput
import struct Yosemite.POSOrder
import struct Yosemite.POSStaffAuth

public struct POSRefundPreparation: Equatable {
    public let orderID: Int64
    public let selectableItems: [POSRefundSelectableItem]
    public let paymentMethodDescription: String
    public let customerEmail: String?
    public let requiresCardPresentRefund: Bool

    public init(orderID: Int64,
                selectableItems: [POSRefundSelectableItem],
                paymentMethodDescription: String,
                customerEmail: String?,
                requiresCardPresentRefund: Bool = false) {
        self.orderID = orderID
        self.selectableItems = selectableItems
        self.paymentMethodDescription = paymentMethodDescription
        self.customerEmail = customerEmail
        self.requiresCardPresentRefund = requiresCardPresentRefund
    }
}

public enum POSRefundSubmissionState {
    case idle
    case loading
    case onboarding(factory: CardPresentPaymentOnboardingViewContainer, onCancel: () -> Void)
    case cardPresentEvent(CardPresentPaymentEventDetails)
    case preparingReader(cancel: () -> Void)
    case waitingForCard(inputMethods: CardReaderInput, cancel: () -> Void)
    case processingReader
    case displayingReaderMessage(String)
    case submitting
    case submittingCardPresent
    case retryableError(error: any Error, retry: () -> Void, cancel: () -> Void)
    case nonRetryableError(error: any Error, dismiss: () -> Void)
    case completed
}

public enum POSRefundSubmissionError: Error, Equatable {
    case canceledByUser
}

@Observable public final class POSRefundSubmissionModel {
    public var state: POSRefundSubmissionState = .idle

    public init() {}

    public func reset() {
        state = .idle
    }
}

@MainActor
public protocol POSRefundSubmissionProcessing: AnyObject {
    var stateModel: POSRefundSubmissionModel { get }

    func preloadRefund(for order: POSOrder) async

    func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation

    func prepareReviewData(for order: POSOrder,
                           preparation: POSRefundPreparation,
                           selectedItems: [POSRefundSelectableItem],
                           reason: String?) -> POSRefundReviewData?

    /// - Parameter auth: when non-nil, the resulting `POST /wc/v3/orders/{order_id}/refunds`
    ///   request carries the `X-WC-POS-*` staff headers — `X-WC-POS-Staff-Id` for the actor
    ///   (the operator, or the approving manager on an override refund) and `X-WC-POS-Initiator-Id`
    ///   for the cashier who initiated an override refund.
    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?,
                      auth: POSStaffAuth?) async throws
}

public final class POSNoOpRefundSubmissionProcessor: POSRefundSubmissionProcessing {
    public let stateModel = POSRefundSubmissionModel()

    nonisolated public init() {}

    public func preloadRefund(for order: POSOrder) async {}

    public func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation {
        POSRefundPreparation(orderID: order.id,
                             selectableItems: [],
                             paymentMethodDescription: String(format: Localization.viaPaymentMethodFormat, order.paymentMethodTitle),
                             customerEmail: order.customerEmail,
                             requiresCardPresentRefund: false)
    }

    public func prepareReviewData(for order: POSOrder,
                                  preparation: POSRefundPreparation,
                                  selectedItems: [POSRefundSelectableItem],
                                  reason: String?) -> POSRefundReviewData? {
        nil
    }

    public func submitRefund(for order: POSOrder,
                             preparation: POSRefundPreparation,
                             selectedItems: [POSRefundSelectableItem],
                             reason: String?,
                             auth: POSStaffAuth?) async throws {
        stateModel.state = .completed
    }
}

private extension POSNoOpRefundSubmissionProcessor {
    enum Localization {
        static let viaPaymentMethodFormat = NSLocalizedString(
            "pointOfSale.refunds.paymentMethodDescription.viaPaymentMethod",
            value: "via %1$@",
            comment: "Payment method description for POS refunds. %1$@ is the payment method title."
        )
    }
}
