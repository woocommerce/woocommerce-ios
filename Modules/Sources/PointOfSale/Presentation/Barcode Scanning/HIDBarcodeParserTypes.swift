import Foundation

public enum HIDBarcodeParserError: Error {
    case scanTooShort(barcode: String)
    case timedOut(barcode: String)

    public var analyticsReason: String {
        switch self {
        case .scanTooShort:
            return "too_short"
        case .timedOut:
            return "no_terminator"
        }
    }

    public var barcode: String {
        switch self {
        case .scanTooShort(let barcode), .timedOut(let barcode):
            return barcode
        }
    }
}

public enum HIDBarcodeParserResult {
    case success(barcode: String, scanDurationMs: Int)
    case failure(error: HIDBarcodeParserError, scanDurationMs: Int)

    public var asResult: Result<String, HIDBarcodeParserError> {
        switch self {
        case .success(let barcode, _):
            return .success(barcode)
        case .failure(let error, _):
            return .failure(error)
        }
    }
}
