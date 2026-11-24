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
            destinationElement: { $0.tables["order-details-table-view"] }
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
        // The app must leave the foreground so becoming active can confirm that iOS delivered the link.
        XCUIDevice.shared.press(.home)
        guard app.wait(for: .runningBackground, timeout: Constants.backgroundWaitTimeout) || app.state == .runningBackgroundSuspended else {
            throw NSError(domain: "UI Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "WooCommerce stayed in the foreground after pressing Home"])
        }

        for attempt in 1...Constants.maximumOpenAttempts {
            XCUIDevice.shared.system.open(url)
            guard app.wait(for: .runningForeground, timeout: Constants.foregroundWaitTimeout) else {
                continue
            }

            // Once iOS opens WooCommerce, wait for the route to finish before doing any more UI work.
            if universalLink.destinationElement(app).waitForExistence(timeout: Constants.destinationWaitTimeout) {
                return
            }
            throw NSError(
                domain: "UI Test",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "WooCommerce opened on attempt \(attempt). The \(linkedScreen) destination timed out."]
            )
        }

        throw NSError(
            domain: "UI Test",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "The \(linkedScreen) link did not open WooCommerce after \(Constants.maximumOpenAttempts) attempts"]
        )
    }

    private struct UniversalLink {
        let url: String
        let destinationElement: (XCUIApplication) -> XCUIElement
    }

    private enum Constants {
        static let maximumOpenAttempts = 3
        static let backgroundWaitTimeout: TimeInterval = 5
        static let foregroundWaitTimeout: TimeInterval = 10
        static let destinationWaitTimeout: TimeInterval = 30
    }
}
