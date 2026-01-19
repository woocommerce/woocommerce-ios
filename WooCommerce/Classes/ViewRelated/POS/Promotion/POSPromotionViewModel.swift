import Foundation
import Observation

/// View model for the POS Promotion modal flow.
///
@MainActor
@Observable
final class POSPromotionViewModel {
    /// The currently selected step index (0-indexed).
    var selectedStep = 0

    /// The step descriptions to display in the modal.
    private(set) var stepDescriptions: [String]

    /// When set to true, the modal should dismiss.
    var dismiss: Bool = false

    /// The total number of steps.
    var totalSteps: Int { stepDescriptions.count }

    /// The image name for the modal (same across all steps).
    let imageName: String

    /// The title for the modal (same across all steps).
    let title: String

    /// Whether the user is currently on the final step.
    var isOnFinalStep: Bool {
        selectedStep == stepDescriptions.count - 1
    }

    /// The title for the primary action button.
    var primaryButtonTitle: String {
        isOnFinalStep ? Localization.explorePOS : Localization.next
    }

    private let onDismiss: () -> Void

    init(stepDescriptions: [String]? = nil,
         imageName: String = "pos-promotion-header",
         title: String = Localization.title,
         onDismiss: @escaping () -> Void = {}) {
        self.stepDescriptions = stepDescriptions ?? POSPromotionStepsFactory.stepDescriptions()
        self.imageName = imageName
        self.title = title
        self.onDismiss = onDismiss
    }

    // MARK: - Actions

    /// Called when the primary action button is tapped.
    func primaryActionTapped() {
        if isOnFinalStep {
            dismiss = true
        } else {
            selectedStep += 1
        }
    }

    /// Called when the close button is tapped.
    func closeButtonTapped() {
        dismiss = true
    }

    // MARK: - View Lifecycle

    /// Called when the view appears.
    func onAppear() {
        // Analytics tracking will be added in the next PR
    }

    /// Called when the view disappears.
    func onDisappear() {
        onDismiss()
    }
}

// MARK: - Localization

private enum Localization {
    static let title = NSLocalizedString(
        "posPromotion.title",
        value: "Run POS with the WooCommerce mobile app",
        comment: "Title for the POS promotion modal (shown on all steps)"
    )

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
