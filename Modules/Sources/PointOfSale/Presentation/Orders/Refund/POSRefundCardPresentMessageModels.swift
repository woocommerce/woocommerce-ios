import Foundation
import struct Yosemite.CardReaderInput
import enum Yosemite.CardReaderServiceError

enum POSRefundCardPresentMessageType: Equatable {
    case preparingReader(POSRefundCardPresentBasicMessageViewModel)
    case waitingForCard(POSRefundCardPresentImageMessageViewModel)
    case cardInserted(POSRefundCardPresentImageMessageViewModel)
    case processing(POSRefundCardPresentProcessingMessageViewModel)
    case displayReaderMessage(POSRefundCardPresentProcessingMessageViewModel)
    case cancelledOnReader(POSRefundCardPresentActionMessageViewModel)
    case error(POSRefundCardPresentErrorMessageViewModel)

    var usesPrimaryBackground: Bool {
        switch self {
        case .processing, .displayReaderMessage:
            return true
        case .preparingReader, .waitingForCard, .cardInserted, .cancelledOnReader, .error:
            return false
        }
    }
}

struct POSRefundCardPresentBasicMessageViewModel: Equatable {
    let title: String
    let message: String

    static var preparingReader: Self {
        .init(title: Localization.gettingReady, message: Localization.preparingReader)
    }

    static var checkingRefund: Self {
        .init(title: Localization.gettingReady, message: Localization.checkingRefund)
    }
}

struct POSRefundCardPresentImageMessageViewModel: Equatable {
    let imageName = PointOfSaleAssets.readyForPayment.imageName
    let title: String
    let message: String

    init(inputMethods: CardReaderInput) {
        title = Localization.readyForRefund
        message = Self.message(for: inputMethods)
    }

    static var cardInserted: Self {
        .init(title: Localization.readyForRefund,
              message: Localization.cardInserted)
    }

    private init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    private static func message(for inputMethods: CardReaderInput) -> String {
        if inputMethods == [.swipe, .insert, .tap] {
            return Localization.tapInsertOrSwipe
        } else if inputMethods == [.tap, .insert] {
            return Localization.tapOrInsert
        } else if inputMethods.contains(.tap) {
            return Localization.tap
        } else if inputMethods.contains(.insert) {
            return Localization.insert
        } else {
            return Localization.presentCard
        }
    }
}

struct POSRefundCardPresentProcessingMessageViewModel: Equatable {
    let title = Localization.processingRefund
    let message: String

    static var processing: Self {
        .init(message: Localization.pleaseWait)
    }

    static func displayReaderMessage(_ message: String) -> Self {
        .init(message: message)
    }
}

struct POSRefundCardPresentActionMessageViewModel: Equatable {
    let title: String
    let message: String?
    let primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?
    let secondaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?

    static func cancelledOnReader(backToRefund: @escaping () -> Void) -> Self {
        .init(title: Localization.cancelledOnReader,
              message: nil,
              primaryButtonViewModel: .init(title: Localization.backToRefund,
                                            actionHandler: backToRefund),
              secondaryButtonViewModel: nil)
    }
}

struct POSRefundCardPresentErrorMessageViewModel: Equatable {
    let title = Localization.refundFailed
    let message: String
    let primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel?
    let secondaryButtonViewModel: CardPresentPaymentsModalButtonViewModel

    init(error: Error,
         retryAction: (() -> Void)?,
         cancelAction: @escaping () -> Void) {
        message = Self.message(for: error)
        primaryButtonViewModel = retryAction.map {
            .init(title: Localization.tryRefundAgain, actionHandler: $0)
        }
        secondaryButtonViewModel = .init(title: retryAction == nil ? Localization.close : Localization.cancelRefund,
                                         actionHandler: cancelAction)
    }

    private static func message(for error: Error) -> String {
        if let error = error as? CardReaderServiceError {
            return error.errorDescription ?? error.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
}

private enum Localization {
    static let gettingReady = NSLocalizedString(
        "pos.refundCardPresent.gettingReady.title",
        value: "Getting ready",
        comment: "Title shown in POS while preparing a card reader for a refund."
    )

    static let preparingReader = NSLocalizedString(
        "pos.refundCardPresent.preparingReader.message",
        value: "Preparing reader for refund",
        comment: "Message shown in POS while preparing a card reader for a refund."
    )

    static let checkingRefund = NSLocalizedString(
        "pos.refundCardPresent.checkingRefund.message",
        value: "Checking refund",
        comment: "Message shown in POS while validating a refund before using a card reader."
    )

    static let readyForRefund = NSLocalizedString(
        "pos.refundCardPresent.readyForRefund.title",
        value: "Ready for refund",
        comment: "Title shown in POS when the card reader is ready to process a refund."
    )

    static let tapInsertOrSwipe = NSLocalizedString(
        "pos.refundCardPresent.tapSwipeInsert.message",
        value: "Tap, swipe, or insert card to refund",
        comment: "Instruction shown in POS when a card should be presented for a refund."
    )

    static let tapOrInsert = NSLocalizedString(
        "pos.refundCardPresent.tapInsert.message",
        value: "Tap or insert card to refund",
        comment: "Instruction shown in POS when a card should be tapped or inserted for a refund."
    )

    static let tap = NSLocalizedString(
        "pos.refundCardPresent.tap.message",
        value: "Tap card to refund",
        comment: "Instruction shown in POS when a card should be tapped for a refund."
    )

    static let insert = NSLocalizedString(
        "pos.refundCardPresent.insert.message",
        value: "Insert card to refund",
        comment: "Instruction shown in POS when a card should be inserted for a refund."
    )

    static let presentCard = NSLocalizedString(
        "pos.refundCardPresent.presentCard.message",
        value: "Present card to refund",
        comment: "Instruction shown in POS when a card should be presented for a refund."
    )

    static let cardInserted = NSLocalizedString(
        "pos.refundCardPresent.cardInserted.message",
        value: "Card inserted",
        comment: "Message shown in POS when a card has been inserted for a refund."
    )

    static let processingRefund = NSLocalizedString(
        "pos.refundCardPresent.processingRefund.title",
        value: "Processing refund",
        comment: "Title shown in POS while a card reader refund is processing."
    )

    static let pleaseWait = NSLocalizedString(
        "pos.refundCardPresent.pleaseWait.message",
        value: "Please wait",
        comment: "Message shown in POS while a card reader refund is processing."
    )

    static let cancelledOnReader = NSLocalizedString(
        "pos.refundCardPresent.cancelledOnReader.title",
        value: "Refund canceled on reader",
        comment: "Title shown in POS when a refund is canceled on the card reader."
    )

    static let refundFailed = NSLocalizedString(
        "pos.refundCardPresent.refundFailed.title",
        value: "Refund failed",
        comment: "Title shown in POS when a card reader refund fails."
    )

    static let tryRefundAgain = NSLocalizedString(
        "pos.refundCardPresent.tryRefundAgain.button.title",
        value: "Try refund again",
        comment: "Button shown in POS to retry a failed card reader refund."
    )

    static let cancelRefund = NSLocalizedString(
        "pos.refundCardPresent.cancelRefund.button.title",
        value: "Cancel refund",
        comment: "Button shown in POS to cancel a failed card reader refund."
    )

    static let backToRefund = NSLocalizedString(
        "pos.refundCardPresent.backToRefund.button.title",
        value: "Back to refund",
        comment: "Button shown in POS to return to refund review after a card reader refund is canceled."
    )

    static let close = NSLocalizedString(
        "pos.refundCardPresent.close.button.title",
        value: "Close",
        comment: "Button shown in POS to dismiss a card reader refund message."
    )
}
