import Foundation

struct WPComConnectionSetupStep: Identifiable {
    enum Status {
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
