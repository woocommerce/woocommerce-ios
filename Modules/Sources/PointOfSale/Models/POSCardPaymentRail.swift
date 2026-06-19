import Foundation

enum POSCardPaymentRail: Equatable {
    case tapToPay
    case bluetoothReader

    init(connectionMethod: CardReaderConnectionMethod) {
        switch connectionMethod {
        case .tapToPay:
            self = .tapToPay
        case .bluetooth:
            self = .bluetoothReader
        }
    }

    var connectionMethod: CardReaderConnectionMethod {
        switch self {
        case .tapToPay:
            return .tapToPay
        case .bluetoothReader:
            return .bluetooth
        }
    }
}

enum POSCardPaymentSelectionMode: Equatable {
    case large
    case compact
}
