import Foundation
import NetworkingCore
import Yosemite

enum WriteOutcomeClassifier {
    static func isOutcomeUnknown(_ error: Error) -> Bool {
        switch error {
        case let networkError as NetworkError:
            return networkError.responseCode.map(HTTPStatusClassification.isOutcomeUnknownStatus) ?? false
        case ProductUpdateError.unknown(let anyError):
            return isOutcomeUnknown(anyError.error)
        default:
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                return true
            }

            let description = error.localizedDescription.lowercased()
            return description.contains("timed out") || description.contains("network connection was lost")
        }
    }
}
