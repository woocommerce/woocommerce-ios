import UIKit
import WebKit
import struct Networking.Site

class WebViewControllerConfiguration: NSObject {
    @objc var url: URL?
    @objc var secureInteraction = false

    /// Opens any new pages in Safari. Otherwise, a new web view will be opened
    var opensNewInSafari = false

    /// The behavior to use for allowing links to be loaded by the web view based
    var linkBehavior = LinkBehavior.all
    @objc var customTitle: String?
    var onClose: (() -> Void)?

    @objc init(url: URL?) {
        self.url = url
        super.init()
    }
}
