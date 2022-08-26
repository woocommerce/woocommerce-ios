import Foundation
@testable import WooCommerce

struct MockURLOpener: URLOpener {
    let open: (URL) -> Void

    func open(_ url: URL) {
        open(url)
    }
}
