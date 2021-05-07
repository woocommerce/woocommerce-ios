import Foundation
import UIKit

final class CardReaderSettingsPresentingViewController: UIViewController {

    /// An array of viewModels and related view classes
    private var viewModelsAndViews: CardReaderSettingsPrioritizedViewModelsProvider?

    /// The view controller we are currently presenting
    private var childViewController: UIViewController?

    /// Set our dependencies
    func configure(viewModelsAndViews: CardReaderSettingsPrioritizedViewModelsProvider) {
        self.viewModelsAndViews = viewModelsAndViews
        self.viewModelsAndViews?.onPriorityChanged = onViewModelsPriorityChange
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureNavigation()
        configureInitialState()
    }

    private func configureInitialState() {
        onViewModelsPriorityChange(viewModelAndView: viewModelsAndViews?.priorityViewModelAndView)
    }

    private func onViewModelsPriorityChange(viewModelAndView: CardReaderSettingsViewModelAndView?) {
        childViewController?.willMove(toParent: nil)
        childViewController?.removeFromParent()
        childViewController?.view.removeFromSuperview()

        childViewController = self.storyboard!.instantiateViewController(withIdentifier: viewModelAndView!.viewIdentifier)

        guard let childViewController = childViewController else {
            return
        }

        self.view.addSubview(childViewController.view)
        self.addChild(childViewController)
        childViewController.didMove(toParent: self)
    }
}

// MARK: - View Configuration
//
private extension CardReaderSettingsPresentingViewController {

    private func configureBackground() {
        /// Needed to avoid incorrect background appearing near bottom of view, especially on dark mode
        view.backgroundColor = .systemBackground
    }

    private func configureNavigation() {
        title = Localization.screenTitle
    }
}

// MARK: - Localization
//
private enum Localization {
    static let screenTitle = NSLocalizedString(
        "Manage Card Reader",
        comment: "Card reader settings screen title"
    )
}
