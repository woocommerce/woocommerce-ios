import Foundation
import Combine

/// Keeps track of all the bindings that are needed through the app lifecycle.
/// This type is meant to be passed as an environment variable
///
@MainActor
final class AppBindings: NSObject, ObservableObject {

    override nonisolated init() {
        super.init()
    }

    /// Determines when an order notification arrives and should be presented.
    ///
    @Published var orderNotification: PushNotification?

    /// Trigger to refresh data.
    ///
    let refreshData = PassthroughSubject<Void, Never>()
}
