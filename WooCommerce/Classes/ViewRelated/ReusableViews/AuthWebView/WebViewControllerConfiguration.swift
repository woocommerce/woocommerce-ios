import UIKit
import WebKit
import struct Networking.Site

class WebViewControllerConfiguration: NSObject {
    @objc var url: URL?

    @objc var customTitle: String?
    @objc var authenticator: RequestAuthenticator?
    var onClose: (() -> Void)?

    @objc init(url: URL?) {
        self.url = url
        super.init()
    }

    func authenticate(site: Site, username: String, token: String) {
        self.authenticator = RequestAuthenticator(site: site, username: username, token: token)
    }
}
