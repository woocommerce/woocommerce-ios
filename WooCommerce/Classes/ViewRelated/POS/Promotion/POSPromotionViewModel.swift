import Foundation
import protocol WooFoundation.Analytics

/// View model for the POS Promotion modal flow.
///
@MainActor
final class POSPromotionViewModel: ObservableObject {
    /// The currently selected step index (0-indexed).
    @Published var selectedStep = 0

    /// The steps to display in the modal.
    @Published private(set) var steps: [POSPromotionStepViewModel]

    /// When set to true, the modal should dismiss.
    @Published var dismiss: Bool = false

    /// The total number of steps.
    var totalSteps: Int { steps.count }

    /// The image name for the modal (same across all steps).
    let imageName: String

    /// Whether the user is currently on the final step.
    var isOnFinalStep: Bool {
        selectedStep == steps.count - 1
    }

    /// The title for the primary action button.
    var primaryButtonTitle: String {
        isOnFinalStep ? Localization.explorePOS : Localization.next
    }

    private let analytics: Analytics
    private let urlOpener: URLOpener
    private let onDismiss: () -> Void

    init(steps: [POSPromotionStepViewModel]? = nil,
         imageName: String = "pos-promotion-header",
         analytics: Analytics = ServiceLocator.analytics,
         urlOpener: URLOpener = ApplicationURLOpener(),
         onDismiss: @escaping () -> Void = {}) {
        self.steps = steps ?? POSPromotionStepsFactory.steps()
        self.imageName = imageName
        self.analytics = analytics
        self.urlOpener = urlOpener
        self.onDismiss = onDismiss
    }

    // MARK: - Actions

    /// Called when the primary action button is tapped.
    func primaryActionTapped() {
        if isOnFinalStep {
            analytics.track(.posPromotionModalCTATapped)
            urlOpener.open(WooConstants.URLs.posLearnMore.asURL())
            dismiss = true
        } else {
            selectedStep += 1
        }
    }

    /// Called when the close button is tapped.
    func closeButtonTapped() {
        analytics.track(.posPromotionModalDismissed)
        dismiss = true
    }

    // MARK: - View Lifecycle

    /// Called when the view appears.
    func onAppear() {
        analytics.track(.posPromotionModalShown)
    }

    /// Called when the view disappears.
    func onDisappear() {
        onDismiss()
    }
}

// MARK: - Localization

private enum Localization {
    static let next = NSLocalizedString(
        "posPromotion.button.next",
        value: "Next",
        comment: "Button to go to the next step in the POS promotion modal"
    )

    static let explorePOS = NSLocalizedString(
        "posPromotion.button.explorePOS",
        value: "Explore WooCommerce POS",
        comment: "Button to open the POS learn more page in Safari (final step of POS promotion modal)"
    )
}
