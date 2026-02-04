// POSBookingPaymentState.swift
import Foundation

enum POSBookingPaymentState: Equatable {
    case ready
    case processing
    case success
    case error(String)

    var canCancel: Bool {
        switch self {
        case .ready, .error:
            return true
        case .processing, .success:
            return false
        }
    }

    var showsAmount: Bool {
        switch self {
        case .ready, .processing, .success:
            return true
        case .error:
            return false
        }
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}
