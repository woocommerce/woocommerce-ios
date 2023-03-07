import Foundation
import UIKit

protocol URLOpener {
    func open(_ url: URL)
}

/// Uses the UIApplication API to open the url
///
struct ApplicationURLOpener: URLOpener {
    func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
