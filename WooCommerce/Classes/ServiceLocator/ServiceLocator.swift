
import Foundation

final class ServiceLocator {
    private static var _analytics: Analytics = WooAnalytics(analyticsProvider: TracksProvider())
    //private static var _storesManager: StoresManager = DefaultStoresManager()

    static var analytics: Analytics {
        return _analytics
    }

//    static var storesManager: StoresManager {
//        return _storesManager
//    }
}

// Testability
extension ServiceLocator {
    static func setAnalytics(_ mock: Analytics) {
        _analytics = mock
    }

//    static func setStoresManager(_ mock: StoresManager) {
//        _storesManager = mock
//    }
}
