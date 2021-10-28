import Foundation
import Networking
import Storage


public class TelemetryStore: Store {
    private let telemetryRemote: TelemetryRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.telemetryRemote = TelemetryRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: TelemetryAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? TelemetryAction else {
            assertionFailure("TelemetryStore received an unsupported action")
            return
        }

        switch action {
        case .sendTelemetry(let siteID, let versionString, let onCompletion):
            sendTelemetry(siteID: siteID, versionString: versionString, onCompletion: onCompletion)
        }
    }
}

private extension TelemetryStore {

    func sendTelemetry(siteID: Int64, versionString: String, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        telemetryRemote.sendTelemetry(for: siteID, versionString: versionString, completion: onCompletion)
    }
}
