import XCTest

public final class ExternalAppScreen {

    public init() {}

    let universalLinks = [
        "payments": "https://woocommerce.com/mobile/payments",
        "orders": "https://www.woocommerce.com/mobile/orders/details?blog_id=161477129&order_id=3337"
    ]

    public func openUniversalLink(linkedScreen: String) throws {
        guard let universalLink = universalLinks[linkedScreen] else {
            throw NSError(domain: "UI Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Universal link not found for key: \(linkedScreen)"])
        }
        guard let url = URL(string: universalLink) else {
            throw NSError(domain: "UI Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid universal link: \(universalLink)"])
        }

        XCUIDevice.shared.system.open(url)
    }
}
