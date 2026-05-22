import SwiftUI
import UIKit

/// Generic base for per-section push-notification preference detail screens.
/// Owns navigation chrome — Save bar button, custom back button, spinner
/// while saving, discard-changes flow — and observes the shared
/// `PushNotificationPreferencesViewModel` so each kind's host controller
/// becomes a thin subclass that just declares its detail view and a scoped
/// discard handler.
///
/// Toolbar items live on `navigationItem` rather than in a SwiftUI `.toolbar`
/// modifier — when a `UIHostingController`'s root view declares any toolbar
/// item, SwiftUI takes ownership of the navigation item and routes the back
/// button through its own gesture stack, bypassing
/// `UINavigationBarDelegate.navigationBar(_:shouldPop:)` and
/// `shouldPopOnBackButton`.
///
class NotificationDetailHostingController<Content: View>: UIHostingController<Content> {

    let viewModel: PushNotificationPreferencesViewModel
    private let onDiscard: () -> Void

    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: NotificationDetailHostingControllerStrings.save,
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
        item.accessibilityLabel = NotificationDetailHostingControllerStrings.back
        return item
    }()

    private lazy var savingActivityItem: UIBarButtonItem = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        return UIBarButtonItem(customView: spinner)
    }()

    init(viewModel: PushNotificationPreferencesViewModel,
         rootView: Content,
         onDiscard: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDiscard = onDiscard
        super.init(rootView: rootView)
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

    // MARK: - Action handlers
    //
    // Lives in the class body (not a private extension) because `@objc`
    // members aren't permitted in extensions of generic classes.

    @objc private func handleBackTapped() {
        if viewModel.hasUnsavedChanges {
            presentBackNavigationActionSheet()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func handleSaveTapped() {
        guard !viewModel.isSaving else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let success = await viewModel.save()
            if success {
                navigationController?.popViewController(animated: true)
            }
        }
    }

    /// `@Observable` tracking fires once and stops, so re-register after each
    /// change to keep the bar item in sync with `hasUnsavedChanges` and
    /// `isSaving`.
    private func observeUnsavedChanges() {
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

    private func refreshRightBarButtonItem() {
        if viewModel.isSaving {
            navigationItem.rightBarButtonItem = savingActivityItem
        } else {
            saveBarButtonItem.isEnabled = viewModel.hasUnsavedChanges
            navigationItem.rightBarButtonItem = saveBarButtonItem
        }
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self,
                                                           onDiscard: { [weak self] in
            self?.onDiscard()
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

/// Localized strings for `NotificationDetailHostingController`. Lives at file
/// scope because static stored properties aren't supported inside generic
/// types.
private enum NotificationDetailHostingControllerStrings {
    static let save = NSLocalizedString(
        "notificationDetailHostingController.save",
        value: "Save",
        comment: "Title of the Save bar button on a push notification preferences detail screen."
    )
    static let back = NSLocalizedString(
        "notificationDetailHostingController.back",
        value: "Back",
        comment: "VoiceOver label for the back button on a push notification preferences detail screen."
    )
}
