import Combine
import Foundation

struct WCSettingsWebViewModel: Identifiable {
    var id: String {
        webViewURL.absoluteString
    }

    let webViewURL: URL
    let onCompletion: () -> Void
}

protocol CardPresentPaymentsModalViewModelWCSettingsWebViewPresenting {
    var webViewModel: AnyPublisher<WCSettingsWebViewModel?, Never> { get }
}
