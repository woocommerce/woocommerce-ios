import Foundation
import Observation
import struct Yosemite.CardReaderInput
import struct Yosemite.POSOrder

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
    case refundPreviewFailed

    /// The store created a refund with no amount from a quantity-only request, which means it
    /// ignored `compute_totals` (a ghost refund). The refund record exists on the store and the
    /// items may have been restocked, but no money moved. Retrying would create a second refund
    /// and restock a second time, so the flow sends the cashier back to the order instead.
    case refundCreatedWithoutPayment
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
                           reason: String?) async throws -> POSRefundReviewData

    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?) async throws
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
                                  reason: String?) async throws -> POSRefundReviewData {
        POSRefundReviewData(itemsCount: selectedItems.count,
                            formattedItemsSubtotal: "",
                            formattedTax: "",
                            formattedRefundTotal: "",
                            paymentMethodDescription: preparation.paymentMethodDescription,
                            customerEmail: preparation.customerEmail,
                            refundReason: reason,
                            isFullRefund: false)
    }

    public func submitRefund(for order: POSOrder,
                             preparation: POSRefundPreparation,
                             selectedItems: [POSRefundSelectableItem],
                             reason: String?) async throws {
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
