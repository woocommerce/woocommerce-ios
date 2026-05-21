import Foundation
import Observation
import struct Yosemite.CardReaderInput
import struct Yosemite.POSOrder

public struct POSRefundPreparation: Equatable {
    public let orderID: Int64
    public let selectableItems: [POSRefundSelectableItem]
    public let paymentMethodDescription: String
    public let customerEmail: String?

    public init(orderID: Int64,
                selectableItems: [POSRefundSelectableItem],
                paymentMethodDescription: String,
                customerEmail: String?) {
        self.orderID = orderID
        self.selectableItems = selectableItems
        self.paymentMethodDescription = paymentMethodDescription
        self.customerEmail = customerEmail
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
    case retryableError(error: any Error, retry: () -> Void, cancel: () -> Void)
    case nonRetryableError(error: any Error, dismiss: () -> Void)
    case completed
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

    func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation

    func prepareReviewData(for order: POSOrder,
                           preparation: POSRefundPreparation,
                           selectedItems: [POSRefundSelectableItem],
                           reason: String?) -> POSRefundReviewData?

    func submitRefund(for order: POSOrder,
                      preparation: POSRefundPreparation,
                      selectedItems: [POSRefundSelectableItem],
                      reason: String?) async throws
}

public final class POSNoOpRefundSubmissionProcessor: POSRefundSubmissionProcessing {
    public let stateModel = POSRefundSubmissionModel()

    public nonisolated init() {}

    public func prepareRefund(for order: POSOrder) async throws -> POSRefundPreparation {
        POSRefundPreparation(orderID: order.id,
                             selectableItems: [],
                             paymentMethodDescription: String(format: Localization.viaPaymentMethodFormat, order.paymentMethodTitle),
                             customerEmail: order.customerEmail)
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
                             reason: String?) async throws {
        stateModel.state = .completed
    }
}

private extension POSNoOpRefundSubmissionProcessor {
    enum Localization {
        static let viaPaymentMethodFormat = NSLocalizedString(
            "pointOfSale.refunds.paymentMethodDescription.viaPaymentMethod",
            value: "via %@",
            comment: "Payment method description for POS refunds. %@ is the payment method title."
        )
    }
}
