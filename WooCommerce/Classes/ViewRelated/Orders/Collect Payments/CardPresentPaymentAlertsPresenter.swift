import Foundation
import SwiftUI
import UIKit

protocol CardPresentPaymentAlertsPresenting {
    func present(viewModel: CardPresentPaymentsModalViewModel)
    func presentWCSettingsWebView(adminURL: URL, completion: @escaping () -> Void)
    func foundSeveralReaders(readerIDs: [String],
                             connect: @escaping (String) -> Void,
                             cancelSearch: @escaping () -> Void)
    func updateSeveralReadersList(readerIDs: [String])
    func dismiss()
}

final class CardPresentPaymentAlertsPresenter: CardPresentPaymentAlertsPresenting {
    private var modalController: CardPresentPaymentsModalViewController?
    private var severalFoundController: SeveralReadersFoundViewController?

    /// There should not be a strong reference to the view controller, as generally the alerts presenter
    /// will be owned (perhaps indirectly) by the view controller. Keeping a strong reference here makes
    /// retain cycles likely/unavoidable.
    private weak var rootViewController: ViewControllerPresenting?

    init(rootViewController: ViewControllerPresenting) {
        self.rootViewController = rootViewController
    }

    func present(viewModel: CardPresentPaymentsModalViewModel) {
        setViewModelAndPresent(viewModel: viewModel)
    }

    private func setViewModelAndPresent(viewModel: CardPresentPaymentsModalViewModel) {
        guard modalController == nil else {
            modalController?.setViewModel(viewModel)
            return
        }

        modalController = CardPresentPaymentsModalViewController(viewModel: viewModel)
        guard let modalController = modalController else {
            return
        }

        modalController.prepareForCardReaderModalFlow()

        dismissSeveralFoundAndPresent(animated: true, from: rootViewController, present: modalController)
    }

    /// Dismisses any view controller based on `CardPresentPaymentsModalViewController`,
    /// then presents any `SeveralReadersFoundViewController` passed to it
    ///
    private func dismissCommonAndPresent(animated: Bool = true, from: ViewControllerPresenting? = nil, present: SeveralReadersFoundViewController? = nil) {
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

    func presentWCSettingsWebView(adminURL: URL, completion: @escaping () -> Void) {
        guard let modalController else {
            return
        }
        let nav = WCSettingsWebView(adminUrl: adminURL) {
            modalController.dismiss(animated: true) {
                completion()
            }
        }
        let hostingController = UIHostingController(rootView: nav)
        modalController.present(hostingController, animated: true, completion: nil)
    }

    /// Dismisses the `SeveralReadersFoundViewController`, then presents any
    /// `CardPresentPaymentsModalViewController` passed to it.
    ///
    func dismissSeveralFoundAndPresent(animated: Bool = true, from: ViewControllerPresenting? = nil, present: CardPresentPaymentsModalViewController? = nil) {
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
