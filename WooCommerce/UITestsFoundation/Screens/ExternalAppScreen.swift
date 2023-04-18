import XCTest

public final class ExternalAppScreen {

    public private(set) var app: XCUIApplication!

    public init() {
        app = XCUIApplication()
    }

    enum UniversalLinks: String {
        case payments = "https://woocommerce.com/mobile/payments"
        case orders = "https://www.woocommerce.com/mobile/orders/details?blog_id=161477129&order_id=3337"
    }

    // To open universal links listed in mocked HTML file
    public func openUniversalLinkFromSafariApp(linkedScreen: String) throws {
        let universalLink = UniversalLinks(rawValue: linkedScreen)

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()

        // To accommodate elements on both iPhone and iPad
        let searchBarElement = UIDevice.current.userInterfaceIdiom == .phone ? "CapsuleNavigationBar?isSelected=true" : "UnifiedTabBar"

        // Go to Wiremock's HTML file with universal links
        safari.otherElements[searchBarElement].tap()
        safari.typeText("http://localhost:8282/links.html")
        safari.buttons["Go"].tap()

        // Tap on the universal link
        if safari.staticTexts["TESTING LINKS"].exists { safari.links[universalLink!.rawValue].tap() }
    }
}
