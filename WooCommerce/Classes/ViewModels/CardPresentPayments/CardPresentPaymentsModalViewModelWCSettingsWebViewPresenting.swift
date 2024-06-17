import Combine
import Foundation

struct WCSettingsWebViewModel: Identifiable {
    var id: String {
        webViewURL.absoluteString
    }

    let webViewURL: URL
    let onCompletion: () -> Void
}
