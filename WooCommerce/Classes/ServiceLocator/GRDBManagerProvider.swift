import protocol Storage.GRDBManagerProtocol

protocol GRDBManagerProviding {
    var initializedGRDBManager: GRDBManagerProtocol? { get }
}

struct ServiceLocatorGRDBManagerProvider: GRDBManagerProviding {
    var initializedGRDBManager: GRDBManagerProtocol? {
        ServiceLocator.initializedGRDBManager
    }
}
