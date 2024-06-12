import UIKit

typealias CardPresentPaymentsModalViewModel = CardPresentPaymentsModalViewModelContent
    & CardPresentPaymentsModalViewModelUIKitActions
    & CardPresentPaymentsModalViewModelActions

/// Abstracts configuration and contents of the modal screens presented
/// during operations related to Card Present Payments
protocol CardPresentPaymentsModalViewModelContent {
    /// The number and distribution of text labels
    var textMode: PaymentsModalTextMode { get }

    /// The title at the top of the modal view.
    var topTitle: String { get }

    /// The second line of text of the modal view. Right over the illustration
    var topSubtitle: String? { get }

    /// An illustration accompanying the modal
    var image: UIImage { get }

    /// Large loading indicator which may be shown in place of the image
    var showLoadingIndicator: Bool { get }

    /// The title in the bottom section of the modal. Right below the image
    var bottomTitle: String? { get }

    /// The subtitle in the bottom section of the modal. Right below the image
    var bottomSubtitle: String? { get }

    /// The accessibilityLabel to be provided to VoiceOver
    var accessibilityLabel: String? { get }
}

protocol CardPresentPaymentsModalViewModelUIKitActions {
    /// The number and distribution of action buttons
    var actionsMode: PaymentsModalActionsMode { get }

    /// Provides a title for a primary action button
    var primaryButtonTitle: String? { get }

    /// Provides a title for a secondary action button
    var secondaryButtonTitle: String? { get }

    /// Provides a title for an auxiliary button
    var auxiliaryButtonTitle: String? { get }

    /// Provides a title as a NSAttributedString for an auxiliary button
    var auxiliaryAttributedButtonTitle: NSAttributedString? { get }

    /// Executes action associated to a tap in the view controller primary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapPrimaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller secondary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapSecondaryButton(in viewController: UIViewController?)

    /// Executes action associated to a tap in the view controller auxiliary button
    /// - Parameter viewController: usually the view controller sending the tap
    func didTapAuxiliaryButton(in viewController: UIViewController?)
}

protocol CardPresentPaymentsModalViewModelActions {
    var primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? { get }
    var secondaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? { get }
    var auxiliaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? { get }
}

enum POSCardPresentPaymentsModalPresentation {
    case alert(viewModel: CardPresentPaymentAlertViewModel)
    case alertWithDismiss(viewModel: CardPresentPaymentAlertViewModel)
    case hidden
    case readyForPayment
    case inlineMessage(message: String)
    case success
}

struct POSCardPresentPaymentsModalViewModel {
    let presentation: POSCardPresentPaymentsModalPresentation

    init(modalViewModel: CardPresentPaymentsModalViewModel) {
        self.presentation = Self.presentation(from: modalViewModel)
    }
}

private extension POSCardPresentPaymentsModalViewModel {
    static func presentation(from modalViewModel: CardPresentPaymentsModalViewModel) -> POSCardPresentPaymentsModalPresentation {
        switch modalViewModel {
            case is CardPresentModalScanningForReader:
                return .inlineMessage(message: "Scanning for reader...")
            case is CardPresentModalConnectingToReader:
                return .inlineMessage(message: "Connecting to reader...")
            case is CardPresentModalPreparingForPayment:
                return .hidden
            case is CardPresentModalError:
                guard let actionHandler = modalViewModel.primaryButtonViewModel?.actionHandler else {
                    return .hidden
                }
                return .alertWithDismiss(viewModel: CardPresentModalError(
                    errorDescription: modalViewModel.bottomTitle,
                    transactionType: .collectPayment,
                    primaryAction: actionHandler,
                    dismissCompletion: {}))
            case is CardPresentModalTapCard:
                return .readyForPayment
            case is CardPresentModalProcessing:
                return .inlineMessage(message: "Processing payment...")
            case let viewModel as CardPresentModalDisplayMessage:
                // This is really just a workaround from making `CardPresentModalDisplayMessage.message` public that we should consider refactoring/changing.
                return .inlineMessage(message: viewModel.message)
            case is CardPresentModalSuccess:
                return .success
            case is CardPresentModalSuccessWithoutEmail:
                return .success
            default:
                return .alert(viewModel: modalViewModel)
        }
    }
}

/// This is a naive fallback use of the existing UIKit handlers, without passing a view controller.
/// In general, we should have specific SwiftUI handlers for each view model, but this helps us move forward quickly.
extension CardPresentPaymentsModalViewModelUIKitActions where Self: CardPresentPaymentsModalViewModelActions {
    var primaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? {
        CardPresentPaymentsModalButtonViewModel(title: primaryButtonTitle) {
            didTapPrimaryButton(in: nil)
        }
    }

    var secondaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? {
        CardPresentPaymentsModalButtonViewModel(title: secondaryButtonTitle) {
            didTapSecondaryButton(in: nil)
        }
    }

    var auxiliaryButtonViewModel: CardPresentPaymentsModalButtonViewModel? {
        CardPresentPaymentsModalButtonViewModel(title: auxiliaryButtonTitle) {
            didTapAuxiliaryButton(in: nil)
        }
    }
}

/// The type of card-present transaction.
enum CardPresentTransactionType {
    /// To collect payment.
    case collectPayment

    /// To issue a refund.
    case refund
}

/// Represents the different visual modes of the modal view's textfields
enum PaymentsModalTextMode {
    /// From top to bottom: Two lines of text at the top, image, two more lines of text
    case fullInfo

    /// From top to bottom: One line of text at the top, image
    case reducedTopInfo

    /// From top to bottom: Two lines of text at the top, image, one more line of text
    case reducedBottomInfo

    /// From top to bottom: Two lines of text at the top, and image
    case noBottomInfo
}

enum PaymentsModalActionsMode {
    /// No action buttons
    case none

    /// One action button
    case oneAction

    /// One secondary action button
    case secondaryOnlyAction

    /// One secondary action button and an auxiliary button
    case secondaryActionAndAuxiliaryButton

    /// Two action buttons
    case twoAction

    /// Two action buttons and an auxiliary button
    case twoActionAndAuxiliary

}

extension CardPresentPaymentsModalViewModelUIKitActions {
    /// Default implementation for NSAttributedString auxiliary button title.
    /// If is not set directly by each Modal's ViewModel, it will default to nil
    var auxiliaryAttributedButtonTitle: NSAttributedString? {
        get { return nil }
    }
}

extension CardPresentPaymentsModalViewModelContent {
    /// Default implementation for the large loading indicator used in place of an image.
    /// If is not set directly by each Modal's ViewModel, it will default to false
    var showLoadingIndicator: Bool {
        get { return false }
    }
}
