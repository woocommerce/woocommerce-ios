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
        self.viewModelsAndViews?.onPriorityChanged = { [weak self] viewModelAndView in
            self?.onViewModelsPriorityChange(viewModelAndView: viewModelAndView)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureInitialState()
    }

    private func configureInitialState() {
        /// To avoid child view controllers extending underneath the navigation bar
        self.edgesForExtendedLayout = []

        onViewModelsPriorityChange(viewModelAndView: viewModelsAndViews?.priorityViewModelAndView)
    }

    private func onViewModelsPriorityChange(viewModelAndView: CardReaderSettingsViewModelAndView?) {
        childViewController?.willMove(toParent: nil)
        childViewController?.removeFromParent()
        childViewController?.view.removeFromSuperview()

        guard let viewModelAndView = viewModelAndView else {
            return
        }

        childViewController = storyboard!.instantiateViewController(withIdentifier: viewModelAndView.viewIdentifier)

        guard let childViewController = childViewController else {
            return
        }

        guard let presenter = childViewController as? CardReaderSettingsViewModelPresenter else {
            return
        }
        presenter.configure(viewModel: viewModelAndView.viewModel)

        self.addChild(childViewController)
        self.view.addSubview(childViewController.view)
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.pinSubviewToAllEdges(childViewController.view)
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
}
