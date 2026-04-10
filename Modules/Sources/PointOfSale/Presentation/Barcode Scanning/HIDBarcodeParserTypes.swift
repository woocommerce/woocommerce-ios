enum HIDBarcodeParserError: Error {
    case scanTooShort(barcode: String)
    case timedOut(barcode: String)

    var analyticsReason: String {
        switch self {
        case .scanTooShort:
            return "too_short"
        case .timedOut:
            return "no_terminator"
        }
    }

    var barcode: String {
        switch self {
        case .scanTooShort(let barcode), .timedOut(let barcode):
            return barcode
        }
    }
}

enum HIDBarcodeParserResult {
    case success(barcode: String, scanDurationMs: Int)
    case failure(error: HIDBarcodeParserError, scanDurationMs: Int)

    var asResult: Result<String, HIDBarcodeParserError> {
        switch self {
        case .success(let barcode, _):
            return .success(barcode)
        case .failure(let error, _):
            return .failure(error)
        }
    }
}
