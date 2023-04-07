import XCTest

public final class ExternalAppScreen {

    public private(set) var app: XCUIApplication!

    public init() {
        app = XCUIApplication()
    }

    // To open universal links listed in mocked HTML file
    public func openUniversalLinkFromSafariApp(link: String) {

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()

        // To accommodate elements on both iPhone and iPad
        let searchBarElement = UIDevice.current.userInterfaceIdiom == .phone ? "TabBarItemTitle" : "UnifiedTabBarItemView?isSelected=true"

        // Go to Wiremock's HTML file with universal links
        safari.textFields[searchBarElement].tap()
        safari.typeText("http://localhost:8282/links.html")
        safari.buttons["Go"].tap()

        // Tap on the universal link
        if safari.staticTexts["TESTING LINKS"].exists { safari.links[link].tap() }
    }
}
