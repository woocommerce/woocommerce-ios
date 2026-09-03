import Foundation
import UIKit

/// Consent state for the currently outstanding significant change, if any.
enum SignificantChangeConsentState: Equatable {
    /// No unacknowledged significant change — no consent needed.
    case notRequired
    /// A significant change needs consent and no request has been sent yet.
    /// Sending is an explicit user action, never automatic.
    case required
    /// The parent/guardian approved the change.
    case granted
    /// The question was sent and the answer hasn't arrived yet.
    case pending
    /// The parent/guardian declined the change.
    case denied
    /// PermissionKit is unavailable or sending failed — treated permissively by policy.
    case notAvailable
}

@MainActor
final class SignificantChangeConsentCoordinator {
    private let consentProvider: SignificantChangeConsentProviding
    private let consentStore: SignificantChangeConsentStoring
    private var responsesTask: Task<Void, Never>?
    private var onResolution: (@MainActor (SignificantChangeConsentStatus) -> Void)?
    /// Grace-window waiters keyed by question id. The single response listener resumes these,
    /// so an answer is never split between two competing stream subscriptions.
    private var graceContinuations: [UUID: CheckedContinuation<SignificantChangeConsentResponse?, Never>] = [:]

    nonisolated init(
        consentProvider: SignificantChangeConsentProviding = PermissionKitSignificantChangeConsentProvider(),
        consentStore: SignificantChangeConsentStoring = UserDefaultsSignificantChangeConsentStore()
    ) {
        self.consentProvider = consentProvider
        self.consentStore = consentStore
    }

    deinit {
        responsesTask?.cancel()
    }

    /// Registers the app-wide resolution callback for answers that arrive outside an active
    /// check (e.g. long after the question was sent, or on a later launch). The underlying
    /// listener is a single long-lived subscription shared with the grace-window path.
    func startObservingResponses(onResolution: @escaping @MainActor (SignificantChangeConsentStatus) -> Void) {
        self.onResolution = onResolution
        ensureObservingResponses()
    }

    /// Resolves the consent state for the given change without any side effects.
    /// Sending the question is a separate, explicitly user-initiated step — `requestConsent`.
    /// - Parameter manualChangeIdentifier: a developer-declared significant change; takes
    ///   precedence over a detected age rating change.
    func checkConsentIfNeeded(
        ageRatingChange: AgeRatingChangeCheckResult?,
        manualChangeIdentifier: SignificantChangeIdentifier? = nil
    ) -> SignificantChangeConsentState {
        guard let changeIdentifier = changeIdentifier(
            ageRatingChange: ageRatingChange,
            manualChangeIdentifier: manualChangeIdentifier
        ) else {
            return .notRequired
        }

        switch consentStore.status(for: changeIdentifier) {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .pending:
            return .pending
        case nil:
            return .required
        }
    }

    /// Sends the consent question to the parent/guardian. Call only from an explicit user
    /// action (the blocking screen's button) — never automatically. A previous denial is
    /// cleared so the question can be asked again.
    func requestConsent(
        in viewController: UIViewController,
        ageRatingChange: AgeRatingChangeCheckResult?,
        manualChangeIdentifier: SignificantChangeIdentifier? = nil
    ) async -> SignificantChangeConsentState {
        guard let changeIdentifier = changeIdentifier(
            ageRatingChange: ageRatingChange,
            manualChangeIdentifier: manualChangeIdentifier
        ) else {
            return .notRequired
        }

        switch consentStore.status(for: changeIdentifier) {
        case .granted:
            return .granted
        case .pending:
            return .pending
        case .denied:
            consentStore.clearStatus(for: changeIdentifier)
        case nil:
            break
        }

        ensureObservingResponses()
        let requestResult = await consentProvider.requestConsent(
            in: viewController,
            significantAppUpdateDescription: description(for: changeIdentifier)
        )
        switch requestResult {
        case let .sent(questionID):
            consentStore.setStatus(.pending, for: changeIdentifier)
            consentStore.setPendingRequest(.init(questionID: questionID, identifier: changeIdentifier))
            // An answer can arrive immediately (in-person approval, sandbox simulation).
            // Give it a short grace window so callers get the final state directly instead of
            // flashing a pending UI that is torn down a moment later.
            if let response = await awaitResponse(questionID: questionID, timeout: Constants.immediateResponseGraceWindow) {
                let status: SignificantChangeConsentStatus = response.isApproved ? .granted : .denied
                consentStore.setStatus(status, for: changeIdentifier)
                consentStore.clearPendingRequest()
                return response.isApproved ? .granted : .denied
            }
            return .pending
        case .notAvailable, .failed:
            return .notAvailable
        }
    }
}

private extension SignificantChangeConsentCoordinator {
    enum Constants {
        static let immediateResponseGraceWindow: TimeInterval = 2
    }

    /// Starts the single long-lived response listener if it isn't running yet.
    func ensureObservingResponses() {
        guard responsesTask == nil else { return }
        responsesTask = Task { [consentProvider, weak self] in
            for await response in consentProvider.responses() {
                await self?.handle(response)
            }
            // The stream ended — no more answers can arrive, release any grace waiters.
            await self?.resumeAllGraceWaiters()
        }
    }

    func handle(_ response: SignificantChangeConsentResponse) {
        // An active grace window for this question owns the response; the check flow
        // persists the outcome and reports the final state itself.
        if let continuation = graceContinuations.removeValue(forKey: response.questionID) {
            continuation.resume(returning: response)
            return
        }
        guard let pending = consentStore.pendingRequest, pending.questionID == response.questionID else { return }
        let status: SignificantChangeConsentStatus = response.isApproved ? .granted : .denied
        consentStore.setStatus(status, for: pending.identifier)
        consentStore.clearPendingRequest()
        onResolution?(status)
    }

    /// Waits up to `timeout` for the answer to the given question; nil when none arrives in time.
    func awaitResponse(questionID: UUID, timeout: TimeInterval) async -> SignificantChangeConsentResponse? {
        ensureObservingResponses()
        return await withCheckedContinuation { continuation in
            graceContinuations[questionID] = continuation
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                await self?.expireGraceWaiter(questionID: questionID)
            }
        }
    }

    func expireGraceWaiter(questionID: UUID) {
        if let continuation = graceContinuations.removeValue(forKey: questionID) {
            continuation.resume(returning: nil)
        }
    }

    func resumeAllGraceWaiters() {
        let continuations = graceContinuations.values
        graceContinuations.removeAll()
        continuations.forEach { $0.resume(returning: nil) }
    }

    func changeIdentifier(
        ageRatingChange: AgeRatingChangeCheckResult?,
        manualChangeIdentifier: SignificantChangeIdentifier?
    ) -> SignificantChangeIdentifier? {
        if let manualChangeIdentifier { return manualChangeIdentifier }
        guard let ageRatingChange else { return nil }
        switch ageRatingChange {
        case let .ageRatingChanged(_, ratingCode):
            return .ageRatingChange(ratingCode: ratingCode)
        }
    }

    func description(for changeIdentifier: SignificantChangeIdentifier) -> String {
        switch changeIdentifier {
        case .ageRatingChange:
            return Localization.ageRatingChangeRequestDescription
        case let .manual(id):
            return String(format: Localization.manualChangeRequestDescriptionFormat, id)
        }
    }

    enum Localization {
        static let ageRatingChangeRequestDescription = NSLocalizedString(
            "significantChangeConsent.ageRatingChange.request.description",
            value: "The app's App Store age rating has increased.",
            comment: "Description a parent or guardian sees in the system consent request " +
            "when the app's App Store age rating changes."
        )

        static let manualChangeRequestDescriptionFormat = NSLocalizedString(
            "significantChangeConsent.manual.description",
            value: "Significant app update: %1$@.",
            comment: "PermissionKit description shown for a manual significant change." +
            "manualChangeID: %1$@ is a short description."
        )
    }
}
