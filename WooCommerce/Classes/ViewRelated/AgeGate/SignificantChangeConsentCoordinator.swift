import Foundation
import UIKit

/// Consent state for the currently outstanding significant change, if any.
enum SignificantChangeConsentState: Equatable {
    /// No unacknowledged significant change — no consent needed.
    case notRequired
    /// The parent/guardian approved the change.
    case granted
    /// The question was sent and the answer hasn't arrived yet.
    case pending
    /// The parent/guardian declined the change.
    case denied
    /// PermissionKit is unavailable or sending failed — treated permissively by policy.
    case notAvailable
}

final class SignificantChangeConsentCoordinator {
    private let consentProvider: SignificantChangeConsentProviding
    private let consentStore: SignificantChangeConsentStoring
    private var responsesTask: Task<Void, Never>?

    init(
        consentProvider: SignificantChangeConsentProviding = PermissionKitSignificantChangeConsentProvider(),
        consentStore: SignificantChangeConsentStoring = UserDefaultsSignificantChangeConsentStore()
    ) {
        self.consentProvider = consentProvider
        self.consentStore = consentStore
    }

    deinit {
        responsesTask?.cancel()
    }

    /// Starts the long-lived listener for parent/guardian answers. An answer can arrive at any
    /// time after the question was sent — including on a later launch — so this should run for
    /// the whole app session. `onResolution` is called on the main actor with the final status.
    func startObservingResponses(onResolution: @escaping @MainActor (SignificantChangeConsentStatus) -> Void) {
        guard responsesTask == nil else { return }
        responsesTask = Task { [consentProvider, weak self] in
            for await response in consentProvider.responses() {
                await MainActor.run { [weak self] in
                    guard let self,
                          let pending = self.consentStore.pendingRequest,
                          pending.questionID == response.questionID else {
                        return
                    }
                    let status: SignificantChangeConsentStatus = response.isApproved ? .granted : .denied
                    self.consentStore.setStatus(status, for: pending.identifier)
                    self.consentStore.clearPendingRequest()
                    onResolution(status)
                }
            }
        }
    }

    /// Resolves the consent state for the given change, sending the question when it was never asked.
    /// - Parameter manualChangeIdentifier: a developer-declared significant change; takes
    ///   precedence over a detected age rating change.
    func checkConsentIfNeeded(
        in viewController: UIViewController,
        ageRatingChange: AgeRatingChangeCheckResult?,
        manualChangeIdentifier: SignificantChangeIdentifier? = nil
    ) async -> SignificantChangeConsentState {
        let changeIdentifier: SignificantChangeIdentifier? = {
            if let manualChangeIdentifier { return manualChangeIdentifier }
            guard let ageRatingChange else { return nil }
            switch ageRatingChange {
            case let .ageRatingChanged(_, ratingCode):
                return .ageRatingChange(ratingCode: ratingCode)
            }
        }()

        guard let changeIdentifier else {
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
            break
        }

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

    /// Clears a previously denied consent so the question can be asked again — the recovery
    /// path offered by the blocking UI.
    func resetDeniedConsent(for identifier: SignificantChangeIdentifier) {
        guard consentStore.status(for: identifier) == .denied else { return }
        consentStore.clearStatus(for: identifier)
    }
}

private extension SignificantChangeConsentCoordinator {
    enum Constants {
        static let immediateResponseGraceWindow: TimeInterval = 2
    }

    /// Waits up to `timeout` for the answer to the given question; nil when none arrives in time.
    func awaitResponse(questionID: UUID, timeout: TimeInterval) async -> SignificantChangeConsentResponse? {
        await withTaskGroup(of: SignificantChangeConsentResponse?.self) { group in
            group.addTask { [consentProvider] in
                for await response in consentProvider.responses() where response.questionID == questionID {
                    return response
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
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
