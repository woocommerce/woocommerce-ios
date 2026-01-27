import Foundation
import CocoaLumberjack
import UIKit
#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
#endif

enum AgeRangeVerificationResult {
    /// The feature is supported and declared user age is within the required range
    case eligible

    /// The feature is supported but declared user age is outside of the required range
    case ineligible

    /// User or parent refused from age sharing
    case declinedSharing

    /// Feature is unavailable in the current environment. I.e. iOS version is below `26.0`.
    case featureUnavailable

    /// Failed to obtain a view controller suitable for system Age Range dialogue. I.e. the provided view controller is outside of UI stack or not presented.
    case invalidUIState

    /// `DeclaredAgeRange` SDK flow produced an error.
    case sdkError(Error)

    case unknown
}

protocol AgeRangeVerificationServiceProtocol {
    /// Triggers the age range verification flow.
    /// - Parameters:
    ///   - viewController: Anchor for the system sheet/prompt.
    ///   - minimumAge: Primary age gate (required).
    ///   - completion: Called with the interpreted outcome.
    func verifyAgeRange(
        in viewController: UIViewController,
        minimumAge: Int,
        completion: @escaping (AgeRangeVerificationResult) -> Void
    )
}

#if canImport(DeclaredAgeRange)
final class AgeRangeVerificationService: AgeRangeVerificationServiceProtocol {
    /// Requests the user's declared age range using Apple's DeclaredAgeRange API (iOS 26+).
    /// The system will present its own consent UI if needed.
    func verifyAgeRange(
        in viewController: UIViewController,
        minimumAge: Int,
        completion: @escaping (AgeRangeVerificationResult) -> Void
    ) {
        guard #available(iOS 26.0, *) else {
            completion(.featureUnavailable)
            return
        }

        Task { @MainActor in
            // Use the topmost visible controller as the anchor to ensure UI can be presented.
            let anchor = viewController.topmostPresentedViewController
            guard anchor.view.window != nil else {
                DDLogWarn("Declared Age Range API: Anchor viewController is not in window; skipping request.")
                completion(.invalidUIState)
                return
            }

            do {
                let response = try await requestAgeRangeResponse(
                    minimumAge: minimumAge,
                    viewController: anchor
                )
                let result = mapResponseToResult(
                    response,
                    minimumAge: minimumAge
                )
                DDLogInfo("Declared Age Range API: Response mapped to \(result)")
                completion(result)
            } catch {
                if let ageError = error as? AgeRangeService.Error, ageError == .notAvailable {
                    DDLogInfo("Declared Age Range API: Not available (simulator or account not eligible); skipping further prompts.")
                } else {
                    DDLogError("Declared Age Range API: Failed to retrieve age range. Error: \(error)")
                }
                completion(.sdkError(error))
            }
        }
    }
}

@available(iOS 26.0, *)
private extension AgeRangeVerificationService {
    func requestAgeRangeResponse(
        minimumAge: Int,
        viewController: UIViewController
    ) async throws -> AgeRangeService.Response {
        return try await AgeRangeService.shared.requestAgeRange(
            ageGates: minimumAge,
            in: viewController
        )
    }

    func mapResponseToResult(
        _ response: AgeRangeService.Response,
        minimumAge: Int
    ) -> AgeRangeVerificationResult {
        switch response {
        case let .sharing(range):
            if let lowerBound = range.lowerBound, lowerBound >= minimumAge {
                return .eligible
            }
            return .ineligible
        case .declinedSharing:
            return .declinedSharing
        @unknown default:
            assertionFailure("Unhandled case for AgeRangeService.Response: \(response)")
            return .unknown
        }
    }
}
#else
/// Fallback implementation when the DeclaredAgeRange SDK is unavailable (e.g., older Xcode/SDK).
final class AgeRangeVerificationService: AgeRangeVerificationServiceProtocol {
    func verifyAgeRange(
        in viewController: UIViewController,
        minimumAge: Int,
        completion: @escaping (AgeRangeVerificationResult) -> Void
    ) {
        completion(.featureUnavailable)
    }
}
#endif
