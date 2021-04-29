import Foundation
import UIKit

final class CardReaderSettingsPresentingViewController: UIViewController {

    /// An array of viewModels and related view classes
    private var viewModelsAndViews = [CardReaderSettingsViewModelAndView]()

    /// Set our dependencies
    func configure(viewModelsAndViews: [CardReaderSettingsViewModelAndView]) {
        self.viewModelsAndViews = viewModelsAndViews
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureNavigation()
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
