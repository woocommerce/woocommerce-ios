import Foundation
import UIKit

protocol CardPresentPaymentAlertsPresenting {
    func present(viewModel: CardPresentPaymentsModalViewModel)
    func foundSeveralReaders(readerIDs: [String],
                             connect: @escaping (String) -> Void,
                             cancelSearch: @escaping () -> Void)
    func updateSeveralReadersList(readerIDs: [String])
    func dismiss()
}

final class CardPresentPaymentAlertsPresenter: CardPresentPaymentAlertsPresenting {
    private var modalController: CardPresentPaymentsModalViewController?
    private var severalFoundController: SeveralReadersFoundViewController?

    let rootViewController: UIViewController

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    func present(viewModel: CardPresentPaymentsModalViewModel) {
        setViewModelAndPresent(from: rootViewController, viewModel: viewModel)
    }

    private func setViewModelAndPresent(from: UIViewController, viewModel: CardPresentPaymentsModalViewModel) {
        guard modalController == nil else {
            modalController?.setViewModel(viewModel)
            return
        }

        modalController = CardPresentPaymentsModalViewController(viewModel: viewModel)
        guard let modalController = modalController else {
            return
        }

        modalController.prepareForCardReaderModalFlow()

        dismissSeveralFoundAndPresent(animated: true, from: from, present: modalController)
    }

    /// Dismisses any view controller based on `CardPresentPaymentsModalViewController`,
    /// then presents any `SeveralReadersFoundViewController` passed to it
    ///
    private func dismissCommonAndPresent(animated: Bool = true, from: UIViewController? = nil, present: SeveralReadersFoundViewController? = nil) {
        /// Dismiss any common modal
        ///
        guard modalController == nil else {
            let shouldAnimateDismissal = animated && present == nil
            modalController?.dismiss(animated: shouldAnimateDismissal, completion: { [weak self] in
                self?.modalController = nil
                guard let from = from, let present = present else {
                    return
                }
                from.present(present, animated: false)
            })
            return
        }

        /// Or, if there was no common modal to dismiss, present straight-away
        ///
        guard let from = from, let present = present else {
            return
        }
        from.present(present, animated: animated)
    }

    /// Dismisses the `SeveralReadersFoundViewController`, then presents any
    /// `CardPresentPaymentsModalViewController` passed to it.
    ///
    func dismissSeveralFoundAndPresent(animated: Bool = true, from: UIViewController? = nil, present: CardPresentPaymentsModalViewController? = nil) {
        guard severalFoundController == nil else {
            let shouldAnimateDismissal = animated && present == nil
            severalFoundController?.dismiss(animated: shouldAnimateDismissal, completion: { [weak self] in
                self?.severalFoundController = nil
                guard let from = from, let present = present else {
                    return
                }
                from.present(present, animated: false)
            })
            return
        }
        /// Or, if there was no several-found modal to dismiss, present straight-away
        ///
        guard let from = from, let present = present else {
            return
        }
        from.present(present, animated: animated)
    }

    /// Note: `foundSeveralReaders` uses a view controller distinct from the common
    /// `CardPresentPaymentsModalViewController` to avoid further
    /// overloading `CardPresentPaymentsModalViewModel`
    ///
    /// This will dismiss any view controllers using the common view model first before
    /// presenting the several readers found modal
    ///
    func foundSeveralReaders(readerIDs: [String],
                             connect: @escaping (String) -> Void,
                             cancelSearch: @escaping () -> Void) {
        severalFoundController = SeveralReadersFoundViewController()

        if let severalFoundController = severalFoundController {
            severalFoundController.configureController(
                readerIDs: readerIDs,
                connect: connect,
                cancelSearch: cancelSearch
            )
            severalFoundController.prepareForCardReaderModalFlow()
        }

        dismissCommonAndPresent(animated: false, from: rootViewController, present: severalFoundController)
    }

    /// Used to update the readers list in the several readers found view
    ///
    func updateSeveralReadersList(readerIDs: [String]) {
        severalFoundController?.updateReaderIDs(readerIDs: readerIDs)
    }

    func dismiss() {
        dismissCommonAndPresent(animated: true)
        dismissSeveralFoundAndPresent(animated: true)
    }
}
