import SwiftUI
import UIKit
import EventHorizonSDK
import protocol WooFoundation.Analytics

/// Generic base for per-section push-notification preference detail screens.
/// Owns navigation chrome — Save bar button, spinner while saving, and the
/// discard-changes flow; each subclass just declares its detail view and a
/// scoped discard handler.
///
/// The **title** is set via `.navigationTitle` *and* `title`.
/// `UIHostingController` clears `navigationItem.title` when SwiftUI doesn't
/// supply one, and the UIKit side is what the push transition measures —
/// otherwise the back button is sized against an empty title and visibly
/// collapses to "Back" once the real one lands. Both read
/// `Content.navigationTitle`.
///
/// The back button is UIKit's standard one, which routes through
/// `navigationBar(_:shouldPop:)` into `shouldPopOnBackButton` to trigger the
/// discard flow. Do NOT add `.navigationBarBackButtonHidden(true)` — on iOS 18
/// that hides the whole leading area, UIKit-set items included (WOOMOB-4027).
///
class NotificationDetailHostingController<Content: NotificationDetailContent>: UIHostingController<Content> {

    let viewModel: PushNotificationPreferencesViewModel
    private let onDiscard: () -> Void
    private let notificationType: NotificationTypeValue
    private let analytics: Analytics

    private lazy var saveBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: NotificationDetailHostingControllerStrings.save,
                                   style: .done,
                                   target: self,
                                   action: #selector(handleSaveTapped))
        item.isEnabled = false
        return item
    }()

    private lazy var savingActivityItem: UIBarButtonItem = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        return UIBarButtonItem(customView: spinner)
    }()

    init(viewModel: PushNotificationPreferencesViewModel,
         rootView: Content,
         notificationType: NotificationTypeValue,
         onDiscard: @escaping () -> Void,
         analytics: Analytics = ServiceLocator.analytics) {
        self.viewModel = viewModel
        self.onDiscard = onDiscard
        self.notificationType = notificationType
        self.analytics = analytics
        super.init(rootView: rootView)
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Reserves width for the bar's first layout, during the push transition.
        title = Content.navigationTitle
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

    @objc private func handleSaveTapped() {
        guard !viewModel.isSaving else { return }
        analytics.track(.notificationsSettingsUpdateStarted(notificationType: notificationType))
        Task { @MainActor [weak self] in
            guard let self else { return }
            let success = await viewModel.save()
            if success {
                analytics.track(.notificationsSettingsUpdateSuccess(notificationType: notificationType))
                navigationController?.popViewController(animated: true)
            } else {
                analytics.track(.notificationsSettingsUpdateFailed(notificationType: notificationType))
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
            guard let self else { return }
            analytics.track(.notificationsDetailDismissUnsavedChangesResolved(notificationType: notificationType,
                                                                               outcome: .discard))
            onDiscard()
            navigationController?.popViewController(animated: true)
        },
                                                           onCancel: { [weak self] in
            guard let self else { return }
            analytics.track(.notificationsDetailDismissUnsavedChangesResolved(notificationType: notificationType,
                                                                               outcome: .cancel))
        })
    }
}

/// Root view of a push-notification preference detail screen.
/// `NotificationDetailHostingController` reads `navigationTitle`.
protocol NotificationDetailContent: View {
    static var navigationTitle: String { get }
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
}
