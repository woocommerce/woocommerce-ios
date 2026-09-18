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
/// - **Save and Back buttons**: declared by the root view. UIKit-set bar button
///   items are wiped on SwiftUI's next update pass, or on iOS 18 hidden outright.
///   Back runs the discard check itself rather than relying on the system back
///   button: that one only consults `shouldPopOnBackButton` via
///   `navigationBar(_:shouldPop:)`, which isn't reliably called outside
///   `WooNavigationController`, and these screens live in a SwiftUI `NavigationStack`.
///
class NotificationDetailHostingController<Content: NotificationDetailContent>: UIHostingController<Content> {

    let viewModel: PushNotificationPreferencesViewModel
    private let onDiscard: () -> Void
    private let notificationType: NotificationTypeValue
    private let analytics: Analytics

    /// Stands in for the SwiftUI back button during the push, so the system "Back" button
    /// doesn't show for a few frames first. Runs the same action in case it's ever tapped.
    private lazy var placeholderBackBarButtonItem: UIBarButtonItem = {
        // Same symbol, weight and size as the SwiftUI button that replaces it.
        let configuration = UIImage.SymbolConfiguration(textStyle: .body)
            .applying(UIImage.SymbolConfiguration(weight: .semibold))
        let item = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: configuration),
                                   style: .plain,
                                   target: self,
                                   action: #selector(handleBackTapped))
        item.accessibilityLabel = NotificationDetailHostingControllerStrings.back
        return item
    }()

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
        // Set after `super.init` so the closures can capture `self` weakly.
        self.rootView.onSave = { [weak self] in self?.handleSaveTapped() }
        self.rootView.onBack = { [weak self] in self?.handleBackTapped() }
    }

    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Both reserve width for the bar's first layout, during the push transition.
        title = Content.navigationTitle
        navigationItem.leftBarButtonItem = placeholderBackBarButtonItem
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
    //
    // In the class body rather than an extension: `@objc` members aren't allowed in
    // extensions of generic classes.

    @objc private func handleBackTapped() {
        guard !viewModel.hasUnsavedChanges else {
            presentBackNavigationActionSheet()
            return
        }
        navigationController?.popViewController(animated: true)
    }

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
/// `NotificationDetailHostingController` reads `navigationTitle` and injects the actions.
protocol NotificationDetailContent: View {
    static var navigationTitle: String { get }

    var onBack: (() -> Void)? { get set }
    var onSave: (() -> Void)? { get set }
}

/// Back and Save bar buttons; Save shows a spinner while a save is in flight.
/// Reading the view model here lets `@Observable` keep them in sync.
private struct NotificationDetailToolbar: ViewModifier {
    let viewModel: PushNotificationPreferencesViewModel
    let onBack: (() -> Void)?
    let onSave: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onBack?()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel(NotificationDetailHostingControllerStrings.back)
                }
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
    func notificationDetailToolbar(viewModel: PushNotificationPreferencesViewModel,
                                   onBack: (() -> Void)?,
                                   onSave: (() -> Void)?) -> some View {
        modifier(NotificationDetailToolbar(viewModel: viewModel, onBack: onBack, onSave: onSave))
    }
}

/// At file scope because generic types can't hold static stored properties.
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
