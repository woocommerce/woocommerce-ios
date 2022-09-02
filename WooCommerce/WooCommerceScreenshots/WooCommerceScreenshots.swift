import Embassy
import ScreenObject
import UITestsFoundation
import XCTest

class WooCommerceScreenshots: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
        continueAfterFailure = false

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait

        try startWebServer()
    }

    override func tearDown() {
        super.tearDown()
        stopWebServer()
    }

    func testScreenshots() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("mocked-network-layer")
        app.launchArguments.append("-simulate-stripe-card-reader")
        app.launchArguments.append("disable-animations")
        app.launchArguments.append("-mocks-port")
        app.launchArguments.append("-mocks-push-notification")
        app.launchArguments.append("\(server.listenAddress.port)")

        app.launch()

        addUIInterruptionMonitor(withDescription: "System Dialog") {
            (alert) -> Bool in
            alert.buttons["Allow"].tap()
            return true
        }
        app.tap()

        try MyStoreScreen()

        // My Store
        .dismissTopBannerIfNeeded()
        .then { ($0 as! MyStoreScreen).periodStatsTable.switchToMonthsTab() }
        .thenTakeScreenshot(named: "order-dashboard")

        // Orders
        .tabBar.goToOrdersScreen()
        .startOrderCreation()
        .thenTakeScreenshot(named: "order-creation")
        .cancelOrderCreation()

        // Collect payment
        .selectOrder(atIndex: 0)
        .tapCollectPaymentButton()
        .selectCardPresentPayment()
        .thenTakeScreenshot(named: "order-payment")
        .goBackToPaymentMethodsScreen()
        .goBackToOrderScreen()
        .goBackToOrdersScreen()

        // Products
        .tabBar.goToProductsScreen()
        .selectAddProduct()
        .thenTakeScreenshot(named: "product-add")

        // Push notification
        .lockScreen()
        .thenTakeScreenshot(named: "order-notification")
    }

    private let loop = try! SelectorEventLoop(selector: try! KqueueSelector())

    private let queue = DispatchQueue(label: "screenshots-asset-server")

    private lazy var server = DefaultHTTPServer(eventLoop: loop, app: handleWebRequest)

    func startWebServer() throws {
        try queue.sync {
            /// Start HTTP server to listen on the port
            try self.server.start()
            debugPrint("Web Server running on port \(self.server.listenAddress.port)")
        }

        queue.async {
            /// Run event loop
            self.loop.runForever()
        }
    }

    /// This method handles web requests to the asset server running in the test process. It allows for retrieving assets by name, so
    /// passing in `/test-image` will cause the server to return the bits for the item in the `ScreenshotImages.xcassets` catalogue
    /// named `test-image`. Right now only `png` images are supported, though we could add support for additional items over time as needed.
    func handleWebRequest(env: [String: Any], startResponse: ((String, [(String, String)]) -> ()), sendBody: ((Data) -> ())) {
        /// Extract the path, so http://localhost:9285/foo-bar would be `/foo-bar` here.
        /// See https://github.com/envoy/Embassy#whats-swsgi-swift-web-server-gateway-interface for more about PATH_INFO
        guard let path = env["PATH_INFO"] as? String else {
            startResponse("404 Not Found", [])
            sendBody(Data())
            return
        }

        /// Remove the leading `/`, so we're left with `foo-bar`
        let assetName = path.replacingOccurrences(of: "^/", with: "", options: .regularExpression)

        /// Lookup the `assetName` in this bundle
        let bundle = Bundle(for: Self.self)

        guard
            let image = UIImage(named: assetName, in: bundle, compatibleWith: nil),
            let data = image.pngData()
        else {
            startResponse("404 Not Found", [])
            sendBody(Data())
            return
        }

        /// HTTP Header
        startResponse("200 OK", [
            ("Content-Type", "image/png"),
            ("Content-Length", "\(data.count)")
        ])

        /// HTTP Body Data
        sendBody(data)

        /// HTTP EOF
        sendBody(Data())
    }

    func stopWebServer() {
        self.server.stop()
        self.loop.stop()
    }
}

fileprivate var screenshotCount = 0

extension BaseScreen {

    @discardableResult
    func thenTakeScreenshot(named title: String) -> Self {
        screenshotCount += 1

        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(screenshotCount)-\(mode)-\(title)"

        snapshot(filename, timeWaitingForIdle: 0)

        return self
    }
}

extension ScreenObject {

    @discardableResult
    func lockScreen() -> Self {
        // This is a hack from https://stackoverflow.com/a/57356929
        // ☠️ Beware of breaking changes in future updates ☠️
        XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
        sleep(5)
        return self
    }

    @discardableResult
    func thenTakeScreenshot(named title: String) -> Self {
        screenshotCount += 1

        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(screenshotCount)-\(mode)-\(title)"

        snapshot(filename, timeWaitingForIdle: 0)

        return self
    }
}
