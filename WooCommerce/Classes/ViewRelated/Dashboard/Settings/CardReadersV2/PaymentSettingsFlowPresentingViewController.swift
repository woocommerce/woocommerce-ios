import Foundation
import SwiftUI
import UIKit

final class PaymentSettingsFlowPresentingViewController: UIViewController {
    /// An array of viewModels and related view classes
    private var viewModelsAndViews: PaymentSettingsFlowPrioritizedViewModelsProvider

    /// The view controller we are currently presenting
    private var childViewController: UIViewController?

    init(viewModelsAndViews: PaymentSettingsFlowPrioritizedViewModelsProvider) {
        self.viewModelsAndViews = viewModelsAndViews
        super.init(nibName: nil, bundle: nil)

        self.viewModelsAndViews.onPriorityChanged = { [weak self] viewModelAndView in
            self?.onViewModelsPriorityChange(viewModelAndView: viewModelAndView)
        }
        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureNavigation()
        configureInitialState()
    }

    private func configureInitialState() {
        /// To avoid child view controllers extending underneath the navigation bar
        self.edgesForExtendedLayout = []

        onViewModelsPriorityChange(viewModelAndView: viewModelsAndViews.priorityViewModelAndView)
    }

    private func onViewModelsPriorityChange(viewModelAndView: PaymentSettingsFlowViewModelAndView?) {
        childViewController?.willMove(toParent: nil)
        childViewController?.removeFromParent()
        childViewController?.view.removeFromSuperview()

        guard let viewModelAndView = viewModelAndView else {
            return
        }

        guard let childViewController = viewModelAndView.viewPresenter.init(viewModel: viewModelAndView.viewModel) else {
            DDLogError("⛔️ Unexpectedly unable to create PaymentSettingsFlow Child View Controller using: \(String(describing: viewModelAndView))")
            return
        }
        self.childViewController = childViewController

        addChild(childViewController)
        view.addSubview(childViewController.view)
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(childViewController.view)
        childViewController.didMove(toParent: self)
    }

    override var shouldShowOfflineBanner: Bool {
        true
    }
}

// MARK: - View Configuration
//
private extension PaymentSettingsFlowPresentingViewController {
    func configureBackground() {
        /// Needed to avoid incorrect background appearing near bottom of view, especially on dark mode
        view.backgroundColor = .systemBackground
    }

    func configureNavigation() {
        title = Localization.screenTitle
    }
}

// MARK: - SwiftUI compatibility
//

/// N.B. this should not be used directly for the two concrete use cases it enables
/// `SetUpTapToPayViewModelsOrderedList` and `CardReaderSettingsViewModelsOrderedList`
/// If you use it directly, the view models will outlive the views, and likely disconnect readers which we subsequently connect to.
/// Instead, use one of these wrappers, to ensure the view model has the same lifecycle as the view:
/// `TapToPaySettingsFlowPresentingView` or `CardReaderSettingsFlowPresentingView`
struct PaymentSettingsFlowPresentingView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PaymentSettingsFlowPresentingViewController
    let viewModelsAndViews: PaymentSettingsFlowPrioritizedViewModelsProvider

    func makeUIViewController(context: Context) -> PaymentSettingsFlowPresentingViewController {
        let viewController = PaymentSettingsFlowPresentingViewController(viewModelsAndViews: viewModelsAndViews)
        return viewController
    }

    func updateUIViewController(_ uiViewController: PaymentSettingsFlowPresentingViewController, context: Context) {}
}

// MARK: - Localization
//
private enum Localization {
    static let screenTitle = NSLocalizedString(
        "Manage Card Reader",
        comment: "Card reader settings screen title"
    )
}
