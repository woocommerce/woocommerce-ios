import Foundation
import Networking
import Storage


// MARK: - SitePerformanceStore
//
public class SitePerformanceStore: Store {
    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SitePerformanceAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? SitePerformanceAction else {
            assertionFailure("SitePerformanceStore received an unsupported action")
            return
        }

        switch action {
        case .fetchResponseTimes(let onCompletion):
            fetchResponseTimes(onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension SitePerformanceStore {

    func fetchResponseTimes(onCompletion: ([Int]) -> Void) {
        onCompletion(network.responseTimes())
    }
}
