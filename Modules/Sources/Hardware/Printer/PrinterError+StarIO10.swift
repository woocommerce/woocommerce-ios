import Foundation
@preconcurrency import StarIO10

extension PrinterError {
    /// Classifies an error thrown by `StarPrinter.print(command:)`.
    init(printFailure error: any Error) {
        let detail = String(describing: error)
        switch error as? StarIO10Error {
        case .unprintable(_, _, let status):
            self = .unprintable(coverOpen: status?.coverOpen ?? false,
                                paperEmpty: status?.paperEmpty ?? false,
                                detail: detail)
        case .communication, .illegalDeviceState, .notFound, .invalidOperation:
            self = .connectionLost(detail: detail)
        default:
            self = .printFailed(detail: detail)
        }
    }

    /// The cover wins because it has to be closed before the merchant can reach the paper roll.
    static func unprintable(coverOpen: Bool, paperEmpty: Bool, detail: String) -> PrinterError {
        if coverOpen {
            return .coverOpen
        }
        return paperEmpty ? .paperEmpty : .printFailed(detail: detail)
    }
}
