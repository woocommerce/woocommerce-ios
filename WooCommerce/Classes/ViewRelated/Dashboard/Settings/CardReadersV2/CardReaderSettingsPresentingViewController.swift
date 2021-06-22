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
        configureNavigation()
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

        if viewModelAndView.viewIdentifier == "CardReaderSettingsUnknownViewController" {
            childViewController = CardReaderSettingsUnknownViewController(viewModel: viewModelAndView.viewModel as! CardReaderSettingsUnknownViewModel)
        } else {
            childViewController = self.storyboard!.instantiateViewController(withIdentifier: viewModelAndView.viewIdentifier)
        }

        guard let childViewController = childViewController else {
            return
        }

        guard let presenter = childViewController as? CardReaderSettingsViewModelPresenter else {
            return
        }
        presenter.configure(viewModel: viewModelAndView.viewModel)

        self.view.addSubview(childViewController.view)
        self.addChild(childViewController)
        childViewController.didMove(toParent: self)

        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            childViewController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            childViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            childViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor),
            childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
         ])
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
