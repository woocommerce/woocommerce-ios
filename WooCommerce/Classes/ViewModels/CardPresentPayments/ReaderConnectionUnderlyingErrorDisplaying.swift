import Foundation
import Yosemite

protocol ReaderConnectionUnderlyingErrorDisplaying {
    func errorDescription(underlyingError: CardReaderServiceUnderlyingError) -> String?
}

extension ReaderConnectionUnderlyingErrorDisplaying {
    func builtInReaderDescription(for error: Error) -> String? {
        if let error = error as? CardReaderServiceError {
            switch error {
            case .connection(let underlyingError),
                    .discovery(let underlyingError):
                return errorDescription(underlyingError: underlyingError)
            default:
                return error.errorDescription
            }
        } else {
            return error.localizedDescription
        }
    }
}
