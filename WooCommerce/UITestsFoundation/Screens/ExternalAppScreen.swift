import XCTest

public final class ExternalAppScreen {

    public private(set) var app: XCUIApplication!

    public init() {
        app = XCUIApplication()
    }

    let universalLinks = [
        "payments": "https://woo.com/mobile/payments",
        "orders": "https://www.woo.com/mobile/orders/details?blog_id=161477129&order_id=3337"
    ]

    // To open universal links listed in mocked HTML file
    public func openUniversalLinkFromSafariApp(linkedScreen: String) throws {
        guard let universalLink = universalLinks[linkedScreen] else {
            throw NSError(domain: "UI Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Universal link not found for key: \(linkedScreen)"])
        }

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()

        // To accommodate elements on both iPhone and iPad
        let searchBarElement = UIDevice.current.userInterfaceIdiom == .phone ? "CapsuleNavigationBar?isSelected=true" : "UnifiedTabBar"

        // Go to Wiremock's HTML file with universal links
        safari.otherElements[searchBarElement].tap()
        safari.typeText("http://localhost:8282/links.html")
        safari.buttons["Go"].tap()

        guard safari.links[universalLink].waitForIsHittable(timeout: 10) else {
            return XCTFail("\(universalLink) is not displayed!")
        }
        safari.links[universalLink].tap()
    }
}
