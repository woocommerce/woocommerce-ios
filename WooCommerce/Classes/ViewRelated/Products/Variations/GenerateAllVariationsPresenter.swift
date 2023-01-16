import Foundation
import UIKit

/// Type to encapsulate view controllers and notices shown while generating all variations.
///
final class GenerateAllVariationsPresenter {

    /// Base view controller where the loading indicators and notices will be presented.
    ///
    private let baseViewController: UIViewController

    /// Default notices presenter.
    ///
    private let noticePresenter: NoticePresenter

    init(baseViewController: UIViewController, noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.baseViewController = baseViewController
        self.noticePresenter = noticePresenter
    }

    /// Respond to necessary presentation changes.
    ///
    func handleStateChanges(state: GenerateAllVariationsUseCase.State) {
        switch state {
        case .fetching:
            presentFetchingIndicator()
        case .confirmation(let variationCount, let onCompletion):
            presentGenerationConfirmation(numberOfVariations: variationCount, onCompletion: onCompletion)
        case .creating:
            presentCreatingIndicator()
        case .canceled:
            dismissBlockingIndicator()
        case .finished(let variationsCreated, _):
            dismissBlockingIndicator()
            if variationsCreated {
                presentVariationsCreatedNotice()
            } else {
                presentNoGenerationNotice()
            }
            break
        case .error(let error):
            dismissBlockingIndicator()
            presentGenerationError(error)
        }
    }
}

// MARK: Helper Methods
//
private extension GenerateAllVariationsPresenter {
    /// Informs the merchant about errors that happen during the variation generation
    ///
    private func presentGenerationError(_ error: GenerateAllVariationsUseCase.GenerationError) {
        let notice = Notice(title: error.errorTitle, message: error.errorDescription)
        noticePresenter.enqueue(notice: notice)
    }

    /// Asks the merchant for confirmation before generating all variations.
    ///
    private func presentGenerationConfirmation(numberOfVariations: Int, onCompletion: @escaping (_ confirmed: Bool) -> Void) {
        let controller = UIAlertController(title: Localization.confirmationTitle,
                                           message: Localization.confirmationDescription(variationCount: numberOfVariations),
                                           preferredStyle: .alert)
        controller.addDefaultActionWithTitle(Localization.ok) { _ in
            onCompletion(true)
        }
        controller.addCancelActionWithTitle(Localization.cancel) { _ in
            onCompletion(false)
        }

        // There should be an `inProgressViewController` being presented. Fallback to `self` in case there isn't one.
        let baseViewController = baseViewController.presentedViewController ?? baseViewController
        baseViewController.present(controller, animated: true)
    }

    /// Presents a blocking view controller while variations are being fetched.
    ///
    private func presentFetchingIndicator() {
        let inProgressViewController = InProgressViewController(viewProperties: .init(title: Localization.fetchingVariations, message: ""))
        baseViewController.present(inProgressViewController, animated: true)
    }

    /// Presents a blocking view controller while variations are being created.
    ///
    private func presentCreatingIndicator() {
        let newViewProperties = InProgressViewProperties(title: Localization.creatingVariations, message: "")

        // There should be already a presented `InProgressViewController`. But we present one in case there isn;t.
        guard let inProgressViewController = baseViewController.presentedViewController as? InProgressViewController else {
            let inProgressViewController = InProgressViewController(viewProperties: newViewProperties)
            return baseViewController.present(inProgressViewController, animated: true)
        }

        // Update the already presented view controller with the "Creating..." copy.
        inProgressViewController.updateViewProperties(newViewProperties)
    }

    /// Dismiss any `InProgressViewController` being presented.
    /// By default retires the dismissal one time to overcome UIKit presentation delays.
    ///
    private func dismissBlockingIndicator(retry: Bool = true) {
        if let inProgressViewController = baseViewController.presentedViewController as? InProgressViewController {
            inProgressViewController.dismiss(animated: true)
        } else {
            // When this method is invoked right after `InProgressViewController` is presented, chances are that it won't exists in the view controller
            // hierarchy yet.
            // Here we are retrying it with a small delay to give UIKit APIs time to finish its presentation.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.dismissBlockingIndicator(retry: false)
            }
        }
    }

    /// Informs the merchant that no variations were created.
    ///
    private func presentNoGenerationNotice() {
        let notice = Notice(title: Localization.noVariationsCreatedTitle, message: Localization.noVariationsCreatedDescription)
        noticePresenter.enqueue(notice: notice)
    }

    /// Informs the merchant that some variations were created.
    ///
    private func presentVariationsCreatedNotice() {
        let notice = Notice(title: Localization.variationsCreatedTitle)
        noticePresenter.enqueue(notice: notice)
    }
}

// MARK: Localization
//
private extension GenerateAllVariationsPresenter {
    enum Localization {
        static let confirmationTitle = NSLocalizedString("Generate all variations?",
                                                         comment: "Alert title to allow the user confirm if they want to generate all variations")
        static func confirmationDescription(variationCount: Int) -> String {
            let format = NSLocalizedString("This will create a variation for each and every possible combination of variation attributes (%d variations).",
                                           comment: "Alert description to allow the user confirm if they want to generate all variations")
            return String.localizedStringWithFormat(format, variationCount)
        }
        static let ok = NSLocalizedString("OK", comment: "Button text to confirm that we want to generate all variations")
        static let cancel = NSLocalizedString("Cancel", comment: "Button text to confirm that we don't want to generate all variations")
        static let fetchingVariations = NSLocalizedString("Fetching Variations...",
                                                          comment: "Blocking indicator text when fetching existing variations prior generating them.")
        static let creatingVariations = NSLocalizedString("Creating Variations...",
                                                          comment: "Blocking indicator text when creating multiple variations remotely.")
        static let noVariationsCreatedTitle = NSLocalizedString("No variations to generate",
                                                                comment: "Title for the notice when there were no variations to generate")
        static let noVariationsCreatedDescription = NSLocalizedString("All variations are already generated.",
                                                                      comment: "Message for the notice when there were no variations to generate")
        static let variationsCreatedTitle = NSLocalizedString("Variations created successfully",
                                                              comment: "Title for the notice when after variations were created")
    }
}
