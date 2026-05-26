import Foundation

/// Protocol for carrier-specific Terms of Service view models.
///
/// The protocol is intentionally minimal — it knows nothing about checkbox content
/// or structure. Checkbox rendering is the responsibility of each carrier's call site
/// via `@ViewBuilder` injection into `CarrierTermsView`.
///
protocol CarrierTermsViewModel: ObservableObject {
    /// The title displayed at the top of the terms view.
    var title: String { get }

    /// The message displayed below the title (and optional address).
    var message: String { get }

    /// The origin address to display. When `nil`, the "Shipping from" section is hidden.
    var displayedOriginAddress: String? { get }

    /// Whether the confirm button should be enabled (all required checkboxes are accepted).
    var shouldEnableConfirmButton: Bool { get }

    /// Whether a confirmation request is in progress.
    var isConfirming: Bool { get }

    /// Submits the ToS acceptance to the backend.
    /// - Returns: `true` if acceptance was recorded successfully.
    func confirmAcceptance() async throws -> Bool
}
