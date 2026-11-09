import XCTest

@MainActor
public final class ExternalAppScreen {

    public init() {}

    private let universalLinks: [String: UniversalLink] = [
        "payments": UniversalLink(
            url: "https://woocommerce.com/mobile/payments",
            destinationElement: { $0.buttons["card-reader-manuals"] }
        ),
        "orders": UniversalLink(
            url: "https://www.woocommerce.com/mobile/orders/details?blog_id=161477129&order_id=3337",
            destinationElement: { $0.staticTexts["summary-table-view-cell-title-label"] }
        )
    ]

    public func openUniversalLink(linkedScreen: String) throws {
        guard let universalLink = universalLinks[linkedScreen] else {
            throw NSError(domain: "UI Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Universal link not found for key: \(linkedScreen)"])
        }
        guard let url = URL(string: universalLink.url) else {
            throw NSError(domain: "UI Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid universal link: \(universalLink.url)"])
        }

        let app = XCUIApplication()
        for attempt in 1...Constants.maximumOpenAttempts {
            XCUIDevice.shared.system.open(url)
            let destinationElement = universalLink.destinationElement(app)
            if destinationElement.waitForExistence(timeout: Constants.destinationWaitTimeout) {
                return
            }

            // Once Woo handled the link, keep waiting for its destination instead of stacking the same route again.
            if app.state == .runningForeground || destinationElement.exists {
                if destinationElement.waitForExistence(timeout: Constants.routedDestinationWaitTimeout) {
                    return
                }
                break
            }

            if attempt < Constants.maximumOpenAttempts {
                app.activate()
            }
        }

        throw NSError(
            domain: "UI Test",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Universal link did not open \(linkedScreen) after \(Constants.maximumOpenAttempts) attempts"]
        )
    }

    private struct UniversalLink {
        let url: String
        let destinationElement: (XCUIApplication) -> XCUIElement
    }

    private enum Constants {
        static let maximumOpenAttempts = 3
        static let destinationWaitTimeout: TimeInterval = 10
        static let routedDestinationWaitTimeout: TimeInterval = 20
    }
}
