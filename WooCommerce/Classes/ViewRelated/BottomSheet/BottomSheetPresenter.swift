import UIKit

/// Based on `UISheetPresentationController`'s properties for bottom sheet customizations.
@MainActor
protocol BottomSheetConfigurable {
    var prefersEdgeAttachedInCompactHeight: Bool { get set }
    var largestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier? { get set }
    var prefersGrabberVisible: Bool { get set }
    var detents: [UISheetPresentationController.Detent] { get set }
}

extension UISheetPresentationController: BottomSheetConfigurable {}

/// Handles presentation and dismissal of a bottom sheet natively.
@MainActor
final class BottomSheetPresenter: NSObject {
    typealias ConfigureBottomSheet = (BottomSheetConfigurable) -> Void

    private var viewController: UIViewController?
    private var onDismiss: (() -> Void)?

    private let configure: ConfigureBottomSheet

    /// - Parameter configure: Customizations of the bottom sheet with a default implementation.
    init(configure: @escaping ConfigureBottomSheet = Defaults.config) {
        self.configure = configure
    }

    /// Presents a view controller in a bottom sheet.
    /// - Parameters:
    ///   - viewController: View controller to present in a bottom sheet.
    ///   - sourceViewController: View controller that presents the bottom sheet.
    ///   - onDismiss: Called when the bottom sheet is dismissed interactively (dragging down gesture).
    func present(_ viewController: UIViewController,
                 from sourceViewController: UIViewController,
                 onDismiss: (() -> Void)? = nil) {
        self.viewController = viewController
        self.onDismiss = onDismiss
        if let sheet = viewController.sheetPresentationController {
            configure(sheet)
        }
        viewController.presentationController?.delegate = self
        sourceViewController.present(viewController, animated: true)
    }

    /// Dismisses the previously presented bottom sheet.
    /// - Parameter onDismiss: Called when the bottom sheet is dismissed. If non-nil, the `onDismiss` from the `present` call is
    ///   replaced by the new callback.
    func dismiss(onDismiss: (() -> Void)? = nil) {
        if let onDismiss {
            self.onDismiss = onDismiss
        }
        viewController?.dismiss(animated: true) { [weak self] in
            self?.onDismissCompletion()
        }
    }
}

extension BottomSheetPresenter: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismissCompletion()
    }
}

private extension BottomSheetPresenter {
    func onDismissCompletion() {
        onDismiss?()
        onDismiss = nil
        viewController = nil
    }
}

private extension BottomSheetPresenter {
    enum Defaults {
        @MainActor
        static let config: ConfigureBottomSheet = { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersGrabberVisible = false
            sheet.detents = [.medium()]
        }
    }
}
