import SwiftUI
import UIKit
import EventHorizonSDK
import protocol WooFoundation.Analytics

/// Generic base for per-section push-notification preference detail screens.
/// Owns the discard-changes flow and the save action; each subclass just declares
/// its detail view and a scoped discard handler.
///
/// SwiftUI owns the navigation item here, which dictates where each piece lives:
///
/// - **Title**: set via `.navigationTitle` *and* `title`. `UIHostingController`
///   clears `navigationItem.title` when SwiftUI doesn't supply one, and the UIKit
///   side is what the push transition measures. Both read `Content.navigationTitle`.
/// - **Save button**: declared by the root view. A UIKit `rightBarButtonItem` is
///   wiped on SwiftUI's next update pass.
/// - **Back button**: UIKit's standard one, which routes through
///   `navigationBar(_:shouldPop:)` into `shouldPopOnBackButton` to trigger the
///   discard flow. Do NOT add `.navigationBarBackButtonHidden(true)` — on iOS 18
///   that hides the whole leading area, UIKit-set items included (WOOMOB-4027).
///
class NotificationDetailHostingController<Content: NotificationDetailContent>: UIHostingController<Content> {

    let viewModel: PushNotificationPreferencesViewModel
    private let onDiscard: () -> Void
    private let notificationType: NotificationTypeValue
    private let analytics: Analytics

    /// Reserves the SwiftUI Save button's width for the bar's first layout pass.
    /// Usually replaced before it ever draws.
    private lazy var placeholderSaveBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: NotificationDetailHostingControllerStrings.save,
                                   style: .done,
                                   target: nil,
                                   action: nil)
        item.isEnabled = false
        return item
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
        // Set after `super.init` so the closure can capture `self` weakly.
        self.rootView.onSave = { [weak self] in self?.handleSaveTapped() }
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Both reserve width for the bar's first layout, during the push transition.
        title = Content.navigationTitle
        navigationItem.rightBarButtonItem = placeholderSaveBarButtonItem
        // Routes the edge-swipe gesture through `shouldPopOnSwipeBack`.
        handleSwipeBackGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Render SwiftUI before the bar is laid out for the push, so the real toolbar
        // item and title are in place rather than arriving mid-transition.
        view.layoutIfNeeded()
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

    private func handleSaveTapped() {
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
/// `NotificationDetailHostingController` reads `navigationTitle` and injects `onSave`.
protocol NotificationDetailContent: View {
    static var navigationTitle: String { get }

    var onSave: (() -> Void)? { get set }
}

/// Save bar button, shown as a spinner while a save is in flight. Reading the
/// view model here lets `@Observable` keep it in sync.
private struct NotificationDetailSaveToolbar: ViewModifier {
    let viewModel: PushNotificationPreferencesViewModel
    let onSave: (() -> Void)?

    func body(content: Content) -> some View {
        content.toolbar {
            // `.confirmationAction` renders semibold, matching the placeholder's `.done`.
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button(NotificationDetailHostingControllerStrings.save) {
                        onSave?()
                    }
                    .disabled(!viewModel.hasUnsavedChanges)
                }
            }
        }
    }
}

extension View {
    func notificationDetailSaveToolbar(viewModel: PushNotificationPreferencesViewModel,
                                       onSave: (() -> Void)?) -> some View {
        modifier(NotificationDetailSaveToolbar(viewModel: viewModel, onSave: onSave))
    }
}

/// At file scope because generic types can't hold static stored properties.
private enum NotificationDetailHostingControllerStrings {
    static let save = NSLocalizedString(
        "notificationDetailHostingController.save",
        value: "Save",
        comment: "Title of the Save bar button on a push notification preferences detail screen."
    )
}
