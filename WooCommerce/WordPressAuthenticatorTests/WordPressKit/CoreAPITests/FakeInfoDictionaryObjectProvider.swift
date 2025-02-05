@testable import WordPressAuthenticator

class FakeInfoDictionaryObjectProvider: InfoDictionaryObjectProvider {
    private let appTransportSecurity: [String: Any]?

    init(appTransportSecurity: [String: Any]?) {
        self.appTransportSecurity = appTransportSecurity
    }

    func object(forInfoDictionaryKey key: String) -> Any? {
        if key == "NSAppTransportSecurity" {
            return appTransportSecurity
        }

        return nil
    }
}
