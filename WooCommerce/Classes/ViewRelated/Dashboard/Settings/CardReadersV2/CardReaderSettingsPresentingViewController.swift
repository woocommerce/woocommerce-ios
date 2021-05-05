import Foundation
import UIKit

final class CardReaderSettingsPresentingViewController: UIViewController {

    @IBOutlet weak var temporaryLabel: UILabel!

    /// An array of viewModels and related view classes
    private var viewModelsAndViews: CardReaderSettingsPrioritizedViewModelsProvider?

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
        // For now, just update the label with the view identifer we should display
        // A later PR will actually add presented views
        temporaryLabel.text = viewModelAndView?.viewIdentifier ?? "Loading"
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
