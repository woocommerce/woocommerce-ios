import UIKit
import Combine
import OSLog

class CardReaderSettingsViewController: UIViewController {
    private var viewmodel: CardReaderSettingsViewModel
    private var previousChildView: CardReaderSettingsActiveChildView = .none
    private var subscriptions = Set<AnyCancellable>()

    required init?(coder: NSCoder) {
        self.viewmodel = CardReaderSettingsViewModel()
        super.init(coder: coder)

        os_log("In CRSVC init")

        viewmodel.$activeChildView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] readers in
                self?.setChildView()
            }
            .store(in: &subscriptions)
    }

    deinit {
        os_log("In CRSVC deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        os_log("In CRSVC viewDidLoad")
    }

    private func setChildView() {
        // Close any existing child view
        if viewmodel.activeChildView != .none {
            self.navigationController?.popViewController(animated: true)
        }

        // Open the new one (if any)
        if viewmodel.activeChildView == .connect {
            let connectViewController = CardReaderSettingsConnectViewController()
            self.navigationController?.pushViewController(connectViewController, animated: true)
        }
    }
}

// MARK: - View Configuration
//
private extension CardReaderSettingsViewController {

    func configureNavigation() {
        title = NSLocalizedString("Card Readers", comment: "Card reader settings screen title")

        // Don't show the Settings title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }
}
