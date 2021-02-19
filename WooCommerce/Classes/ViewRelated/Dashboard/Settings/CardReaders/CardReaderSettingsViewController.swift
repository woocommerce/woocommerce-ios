import UIKit
import Combine

final class CardReaderSettingsViewController: UIViewController {
    private var subscriptions = Set<AnyCancellable>()
    private var viewmodel = CardReaderSettingsViewModel()
    private var subView: UIView?
    private var alert: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()

        self.viewmodel = CardReaderSettingsViewModel()
        viewmodel.$summaryState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summaryState in
                self?.setSubView()
            }
            .store(in: &subscriptions)
    }

    private func setSubView() {
        alert?.dismiss(animated: true, completion: nil)
        subView?.removeFromSuperview()

        switch self.viewmodel.summaryState {
        case .cleanSlate:
            addCleanSlateView()
        case .connected:
            addListView()
        case .notConnected:
            addListView()
        }

        switch self.viewmodel.interactiveState {
        case .none:
            noop()
        case .searching:
            addSearchingModal()
        case .foundReader:
            noop()
        case .connecting:
            noop()
        case .tutorial:
            noop()
        case .updateAvailable:
            noop()
        case .updateRequired:
            noop()
        case .updating:
            noop()
        }
    }

    private func addCleanSlateView() {
        let connectView = CardReaderSettingsConnectView(frame: view.frame)
        connectView.onPressedConnect = {
            self.viewmodel.startSearch()
        }
        subView = connectView
        if subView != nil {
            view.addSubview(subView!)
        }
    }

    private func addListView() {
        // TODO Implement
    }

    private func noop() {
        // TODO cleanup
    }

    private func addSearchingModal() {
        // TODO Use FancyAlert instead
        alert = UIAlertController(
            title: "Scanning for readers",
            message: "Press the power button of your reader until you see a flashing blue light",
            preferredStyle: UIAlertController.Style.alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { UIAlertAction in
            self.viewmodel.stopSearch()
        }
        alert?.addAction(cancelAction)
        if alert != nil {
            self.present(alert!, animated: true, completion: nil)
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
