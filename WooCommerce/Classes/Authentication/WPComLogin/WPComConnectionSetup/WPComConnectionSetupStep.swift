import Foundation

struct WPComConnectionSetupStep: Identifiable {
    enum Status: Equatable {
        case notStarted
        case running
        case success
        case failure(reason: String)
    }

    let title: String
    let status: Status
    let id = UUID()
}
