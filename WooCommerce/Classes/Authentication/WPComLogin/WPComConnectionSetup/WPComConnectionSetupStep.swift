import Foundation

struct WPComConnectionSetupStep: Identifiable {
    enum Status: Equatable {
        case notStarted
        case running
        case success
        case failure(error: ErrorType)
    }

    enum ErrorType: Equatable {
        case outdatedPlugin(version: String)
        case generic(reason: String)
    }

    let title: String
    let status: Status
    let id = UUID()
}

extension WPComConnectionSetupStep.ErrorType: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .outdatedPlugin(let version):
            return "Outdated plugin version: \(version)"
        case .generic(let reason):
            return reason
        }
    }
}
