import Foundation
import UIKit
#if canImport(PermissionKit)
import PermissionKit
#endif

enum SignificantChangeConsentOutcome: Equatable {
    case granted
    case denied
    case notAvailable
    case unknown
}

protocol SignificantChangeConsentProviding {
    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentOutcome
}

final class PermissionKitSignificantChangeConsentProvider: SignificantChangeConsentProviding {
    func requestConsent(
        in viewController: UIViewController,
        significantAppUpdateDescription: String
    ) async -> SignificantChangeConsentOutcome {
        #if canImport(PermissionKit)
        if #available(iOS 26.2, *) {
            let topic = SignificantAppUpdateTopic(description: significantAppUpdateDescription)
            let question = PermissionQuestion(significantAppUpdateTopic: topic)
            do {
                try await AskCenter.shared.ask(question, in: viewController)
            } catch {
                return .unknown
            }

            for await response in AskCenter.shared.responses(for: SignificantAppUpdateTopic.self) {
                guard response.question.id == question.id else { continue }
                if response.choice == .approve {
                    return .granted
                }
                if response.choice == .decline {
                    return .denied
                }
                return .unknown
            }
            return .unknown
        }
        #endif
        return .notAvailable
    }
}
