import SwiftUI
import UIKit

/// Hosts `NewOrderNotificationPreferencesDetailView` and owns its navigation
/// chrome (Save bar button, custom back button, discard-changes flow).
///
/// Toolbar items live on `navigationItem` rather than in a SwiftUI `.toolbar`
/// modifier — when a `UIHostingController`'s root view declares any toolbar
/// item, SwiftUI takes ownership of the navigation item and routes the back
/// button through its own gesture stack, bypassing
/// `UINavigationBarDelegate.navigationBar(_:shouldPop:)` and
/// `shouldPopOnBackButton`.
///
final class NewOrderNotificationPreferencesHostingController: UIHostingController<NewOrderNotificationPreferencesDetailView> {

    private let viewModel: PushNotificationPreferencesViewModel

    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: Localization.save,
                                   style: .done,
                                   target: self,
                                   action: #selector(handleSaveTapped))
        item.isEnabled = false
        return item
    }()

    private lazy var backBarButtonItem: UIBarButtonItem = {
        let image = UIImage(systemName: "chevron.backward")
        let item = UIBarButtonItem(image: image,
                                   style: .plain,
                                   target: self,
                                   action: #selector(handleBackTapped))
        item.accessibilityLabel = Localization.back
        return item
    }()

    private lazy var savingActivityItem: UIBarButtonItem = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        return UIBarButtonItem(customView: spinner)
    }()

    init(viewModel: PushNotificationPreferencesViewModel) {
        self.viewModel = viewModel
        super.init(rootView: NewOrderNotificationPreferencesDetailView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = backBarButtonItem
        refreshRightBarButtonItem()
        // Routes the edge-swipe gesture through `shouldPopOnSwipeBack`.
        handleSwipeBackGesture()
        observeUnsavedChanges()
    }

    override func shouldPopOnBackButton() -> Bool {
        if viewModel.hasUnsavedChanges {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }
}

private extension NewOrderNotificationPreferencesHostingController {
    /// `@Observable` tracking fires once and stops, so re-register after each
    /// change to keep the bar item in sync with `hasUnsavedChanges` and
    /// `isSaving`.
    func observeUnsavedChanges() {
        withObservationTracking {
            _ = viewModel.hasUnsavedChanges
            _ = viewModel.isSaving
        } onChange: { [weak self] in
            // `onChange` fires from `willSet`; hop to main before touching UIKit.
            DispatchQueue.main.async {
                self?.refreshRightBarButtonItem()
                self?.observeUnsavedChanges()
            }
        }
    }

    func refreshRightBarButtonItem() {
        if viewModel.isSaving {
            navigationItem.rightBarButtonItem = savingActivityItem
        } else {
            saveBarButtonItem.isEnabled = viewModel.hasUnsavedChanges
            navigationItem.rightBarButtonItem = saveBarButtonItem
        }
    }

    @objc func handleBackTapped() {
        if viewModel.hasUnsavedChanges {
            presentBackNavigationActionSheet()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc func handleSaveTapped() {
        guard !viewModel.isSaving else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let success = await viewModel.save()
            if success {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self,
                                                           onDiscard: { [weak self] in
            self?.viewModel.discardStoreOrderEdits()
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

private extension NewOrderNotificationPreferencesHostingController {
    enum Localization {
        static let save = NSLocalizedString(
            "newOrderNotificationPreferencesHostingController.save",
            value: "Save",
            comment: "Title of the Save bar button on the new-order push notification preferences detail screen."
        )
        static let back = NSLocalizedString(
            "newOrderNotificationPreferencesHostingController.back",
            value: "Back",
            comment: "VoiceOver label for the back button on the new-order push notification preferences detail screen."
        )
    }
}
