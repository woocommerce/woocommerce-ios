import Foundation
import UIKit
import CocoaLumberjack
#if canImport(PermissionKit)
import PermissionKit
#endif

/// Result of handing a significant-change consent question to the system.
enum SignificantChangeConsentRequestResult: Equatable {
    /// The system accepted the question. The parent/guardian answer arrives asynchronously
    /// through `responses()` — possibly much later, or after an app relaunch.
    case sent(questionID: UUID)

    /// PermissionKit is unavailable: OS below iOS 26.2, or the account isn't eligible for asks.
    case notAvailable

    /// Sending the question failed.
    case failed
}

/// A parent/guardian answer to a previously sent consent question.
struct SignificantChangeConsentResponse: Equatable {
    let questionID: UUID
    let isApproved: Bool
}

protocol SignificantChangeConsentProviding {
    /// Sends the consent question to the parent/guardian. Returns once the question is handed
    /// to the system — NOT when it is answered. Answers arrive through `responses()`.
    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentRequestResult

    /// Long-lived stream of parent/guardian answers to significant app update questions.
    /// Finishes immediately when PermissionKit is unavailable.
    func responses() -> AsyncStream<SignificantChangeConsentResponse>
}

final class PermissionKitSignificantChangeConsentProvider: SignificantChangeConsentProviding {
    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentRequestResult {
        #if canImport(PermissionKit)
        if #available(iOS 26.2, *) {
            let topic = SignificantAppUpdateTopic(description: significantAppUpdateDescription)
            let question = PermissionQuestion(significantAppUpdateTopic: topic)
            do {
                try await AskCenter.shared.ask(question, in: viewController)
                return .sent(questionID: question.id)
            } catch {
                DDLogError("Significant change consent: failed to send question. Error: \(error)")
                if let askError = error as? AskError, case .notAvailable = askError {
                    return .notAvailable
                }
                return .failed
            }
        }
        #endif
        return .notAvailable
    }

    func responses() -> AsyncStream<SignificantChangeConsentResponse> {
        AsyncStream { continuation in
            #if canImport(PermissionKit)
            guard #available(iOS 26.2, *) else {
                continuation.finish()
                return
            }
            let task = Task {
                for await response in AskCenter.shared.responses(for: SignificantAppUpdateTopic.self) {
                    switch response.choice {
                    case .approve:
                        continuation.yield(.init(questionID: response.question.id, isApproved: true))
                    case .decline:
                        continuation.yield(.init(questionID: response.question.id, isApproved: false))
                    default:
                        DDLogWarn("Significant change consent: unexpected response choice; ignoring.")
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
            #else
            continuation.finish()
            #endif
        }
    }
}
