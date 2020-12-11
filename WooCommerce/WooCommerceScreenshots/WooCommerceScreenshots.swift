import XCTest
import Embassy

class WooCommerceScreenshots: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait

    }

    func testScreenshots() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        setupSnapshot(app)

        app.launchArguments = ["mocked-network-layer", "disable-animations", ]
        app.launch()

        MyStoreScreen()

            // My Store
            .dismissTopBannerIfNeeded()
            .then { ($0 as! MyStoreScreen).periodStatsTable.switchToYearsTab() }
            .thenTakeScreenshot(named: "order-dashboard")

            // Orders
            .tabBar.gotoOrdersScreen()
            .thenTakeScreenshot(named: "order-list")
            .selectOrder(atIndex: 0)
            .thenTakeScreenshot(named: "order-detail")
            .goBackToOrdersScreen()

            .openSearchPane()
            .thenTakeScreenshot(named: "order-search")
            .cancel()

            // Reviews
            .tabBar.gotoReviewsScreen()
            .thenTakeScreenshot(named: "review-list")
            .selectReview(atIndex: 3)
            .thenTakeScreenshot(named: "review-details")
            .goBackToReviewsScreen()

            // Products
            .tabBar.gotoProductsScreen()
            .collapseTopBannerIfNeeded()
            .thenTakeScreenshot(named: "product-list")
            .selectProduct(atIndex: 1)
            .thenTakeScreenshot(named: "product-details")
    }

    ///
    /// Screenshots Web Server
    ///
    override static func setUp() {
        startWebServer()
    }

    private static let loop = try! SelectorEventLoop(selector: try! KqueueSelector())

    private static func startWebServer() {
        /// Run the web server on a background queue
        DispatchQueue.global(qos: .userInitiated).async {

            let server = DefaultHTTPServer(eventLoop: self.loop, port: 9285) {
                (env: [String: Any], startResponse: ((String, [(String, String)]) -> Void), sendBody: ((Data) -> Void)
                ) in

                /// Extract the path, so http://localhost:9285/foo-bar would be `/foo-bar` here.
                guard let path = env["PATH_INFO"] as? String else {
                    startResponse("404 Not Found", [])
                    sendBody(Data())
                    return
                }

                /// Remove the leading `/`, so we're left with `foo-bar`
                let assetName = path.replacingOccurrences(of: "/", with: "")

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

            /// Start HTTP server to listen on the port
            try! server.start()

            /// Run event loop
            self.loop.runForever()
        }
    }

}

fileprivate var screenshotCount = 0

extension BaseScreen {

    @discardableResult
    func thenTakeScreenshot(named title: String) -> Self {
        screenshotCount += 1

        let mode = isDarkMode ? "dark" : "light"
        let filename = "\(screenshotCount)-\(mode)-\(title)"

        snapshot(filename)

        return self
    }
}
