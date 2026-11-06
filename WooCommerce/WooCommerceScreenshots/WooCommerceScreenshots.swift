import Network
import ScreenObject
import UITestsFoundation
import XCTest
import os

class WooCommerceScreenshots: XCTestCase {

    private var screenshotOrientation: UIDeviceOrientation {
        UIDevice.current.userInterfaceIdiom == .pad || XCUIScreen.screens.count > 1 ? .landscapeLeft : .portrait
    }

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

    @MainActor func testScreenshots() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("mocked-network-layer")
        app.launchArguments.append("use-mocked-card-present-payment")
        app.launchArguments.append("-simulate-stripe-card-reader")
        // Disabling UIKit transitions leaves an idle refresh spinner visible on iPad.
        app.launchArguments.append("-mocks-push-notification")
        if UIDevice.current.userInterfaceIdiom == .pad {
            app.launchArguments.append("bypass-pos-eligibility-checks")
            app.launchArguments.append("load-mocked-pos-products")
            app.launchArguments.append("bypass-pos-order-syncing")
        }
        app.launchArguments.append("bypass-card-present-payment")
        app.launchArguments.append(contentsOf: ["-mocks-port", "\(assetPort)"])

        app.launch()

        addUIInterruptionMonitor(withDescription: "System Dialog") { alert in
            let buttons = alert.buttons.allElementsBoundByIndex
            // Try to tap the "Allow" button, but make it work in any language.
            if buttons.count >= 2 {
                buttons[1].tap()
                return true
            }

            return false
        }

        // Triggers any pending system dialogs (like push notification permissions).
        // The interruption monitor above only activates when the app receives user interaction.
        app.tap()

        // My Store
        try TabNavComponent()
            .goToMyStoreScreen()
            .dismissTopBannerIfNeeded()
            .then { screen in
                XCTAssertEqual(screen.app.buttons["tab-bar-pos-item"].exists, UIDevice.current.userInterfaceIdiom == .pad,
                               "Promotional screenshots show the POS tab only on iPad.")
            }
            .thenTakeScreenshot(named: "order-dashboard", orientation: screenshotOrientation)

        if app.launchArguments.contains("-screenshots-dashboard-only") {
            return
        }
        if app.launchArguments.contains("-screenshots-product-only") || app.launchArguments.contains("-screenshots-dashboard-product-only") {
            // Keep the release filenames when recapturing these scenes without the intervening flows.
            screenshotCount = UIDevice.current.userInterfaceIdiom == .pad ? 6 : 3
            try TabNavComponent()
                .goToProductsScreen()
                .tapAddProduct()
                .thenTakeScreenshot(named: "product-add", orientation: screenshotOrientation)
            return
        }

        // Orders
        try TabNavComponent()
        .goToOrdersScreen()
        .startOrderCreation()
        .thenTakeScreenshot(named: "order-creation", orientation: screenshotOrientation)
        .cancelOrderCreation()

        // Collect payment
        .tapOrder(atIndex: 0)
        .then { screen in
            let editButton = screen.app.buttons["order-details-edit-button"]
            let synced = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: editButton)
            XCTAssertEqual(XCTWaiter.wait(for: [synced], timeout: 20), .completed,
                           "Order synchronization must finish before collecting payment.")
        }
        .tapCollectPaymentButton()

        .tapCardPresentPayment()
        .thenTakeScreenshot(named: "order-payment", orientation: screenshotOrientation)

        .goBackToPaymentMethodsScreen()
        .goBackToOrderScreen()
        .goBackToOrdersScreen()

        // POS - iPad only
        if UIDevice.current.userInterfaceIdiom == .pad {
            try TabNavComponent()
                .goToPOSScreen()
                .tapAddProduct(productID: 1)
                .tapAddProduct(productID: 2)
                .thenTakeScreenshot(named: "pos-dashboard", orientation: .landscapeLeft)
                .tapConnectReader()
                .waitForReaderConnected()
                .tapCheckout()
                .waitForTotalsLoaded()
                .waitForCardPaymentReady()
                .thenTakeScreenshot(named: "pos-payment", orientation: .landscapeLeft)
                .tapCashPayment()
                .then { screen in
                    let keyboard = screen.app.keyboards.firstMatch
                    let completeButton = screen.app.buttons["pos-mark-payment-complete-button"]
                    // The cash sheet moves above the keyboard after its button first becomes hittable.
                    let aboveKeyboard = NSPredicate { _, _ in
                        keyboard.exists && completeButton.isHittable && completeButton.frame.maxY <= keyboard.frame.minY
                    }
                    let ready = XCTNSPredicateExpectation(predicate: aboveKeyboard, object: nil)
                    XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed,
                                   "Cash payment must finish moving above the keyboard before completion.")
                }
                .tapMarkPaymentComplete()
                .waitForPaymentSuccess()
                .thenTakeScreenshot(named: "pos-success", orientation: .landscapeLeft)
                .tapMenuButton()
                .tapExitMenuItem()
                .confirmExitPOS()
        }

        // Products
        try TabNavComponent()
        .goToProductsScreen()
        .tapAddProduct()
        .thenTakeScreenshot(named: "product-add", orientation: screenshotOrientation)

        .openNotificationCenterForScreenshot()
        .thenTakeScreenshot(named: "order-notification", orientation: screenshotOrientation)
    }

    private var server: ScreenshotAssetServer?
    private var assetPort: UInt16 = 0

    func startWebServer() throws {
        let bundle = Bundle(for: Self.self)
        let server = try ScreenshotAssetServer { name in
            UIImage(named: name, in: bundle, compatibleWith: nil)?.pngData()
        }
        assetPort = try server.start()
        self.server = server
    }

    func stopWebServer() {
        server?.stop()
        server = nil
        assetPort = 0
    }
}

private final class ScreenshotAssetServer: Sendable {
    private struct State: Sendable {
        var stopped = false
        var connections: [ObjectIdentifier: NWConnection] = [:]
    }

    private enum StartupError: Error {
        case timedOut
        case portUnavailable
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "screenshots-asset-server")
    private let state = OSAllocatedUnfairLock(initialState: State())
    private let assetData: @Sendable (String) -> Data?

    init(assetData: @escaping @Sendable (String) -> Data?) throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv6(.loopback), port: .any)
        listener = try NWListener(using: parameters)
        self.assetData = assetData
    }

    deinit {
        stop()
    }

    func start() throws -> UInt16 {
        let ready = DispatchSemaphore(value: 0)
        let result = OSAllocatedUnfairLock<Result<UInt16, Error>?>(initialState: nil)
        listener.stateUpdateHandler = { [listener] state in
            let update: Result<UInt16, Error>
            switch state {
            case .ready:
                update = listener.port.map { .success($0.rawValue) } ?? .failure(StartupError.portUnavailable)
            case .failed(let error), .waiting(let error):
                update = .failure(error)
            case .cancelled:
                update = .failure(CancellationError())
            default:
                return
            }
            let firstResult = result.withLock { stored in
                guard stored == nil else { return false }
                stored = update
                return true
            }
            if firstResult {
                ready.signal()
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        listener.start(queue: queue)
        guard ready.wait(timeout: .now() + 5) == .success else {
            stop()
            throw StartupError.timedOut
        }
        listener.stateUpdateHandler = nil
        guard let startupResult = result.withLock({ $0 }) else {
            stop()
            throw StartupError.portUnavailable
        }
        do {
            return try startupResult.get()
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        let connections = state.withLock { state in
            state.stopped = true
            let connections = Array(state.connections.values)
            state.connections.removeAll()
            return connections
        }
        listener.newConnectionHandler = nil
        listener.stateUpdateHandler = nil
        listener.cancel()
        for connection in connections {
            connection.stateUpdateHandler = nil
            connection.cancel()
        }
    }

    private func accept(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            if case .failed = state, let connection {
                self?.close(connection)
            }
        }
        let accepted = state.withLock { state in
            guard !state.stopped else { return false }
            state.connections[ObjectIdentifier(connection)] = connection
            connection.start(queue: queue)
            return true
        }
        guard accepted else {
            connection.cancel()
            return
        }
        receiveRequest(on: connection, buffered: Data())
    }

    private func receiveRequest(on connection: NWConnection, buffered: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384 - buffered.count) { [weak self] data, _, complete, error in
            guard let self else { return }
            var request = buffered
            request.append(data ?? Data())
            if let headerEnd = request.range(of: Data("\r\n\r\n".utf8)) {
                connection.send(content: response(for: request[..<headerEnd.lowerBound]), contentContext: .finalMessage, isComplete: true,
                                completion: .contentProcessed { [weak self] _ in self?.close(connection) })
            } else if complete || error != nil || request.count >= 16_384 {
                close(connection)
            } else {
                receiveRequest(on: connection, buffered: request)
            }
        }
    }

    private func response(for request: Data) -> Data {
        let firstLine = String(decoding: request, as: UTF8.self).components(separatedBy: "\r\n").first ?? ""
        let target = firstLine.split(separator: " ").dropFirst().first
        let path = target.flatMap { URLComponents(string: String($0))?.path }
        let body = path.flatMap { assetData(String($0.dropFirst())) }
        let status = body == nil ? "404 Not Found" : "200 OK"
        let payload = body ?? Data()
        let header = "HTTP/1.1 \(status)\r\nContent-Type: image/png\r\nContent-Length: \(payload.count)\r\nConnection: close\r\n\r\n"
        var response = Data(header.utf8)
        response.append(payload)
        return response
    }

    private func close(_ connection: NWConnection) {
        state.withLock { $0.connections[ObjectIdentifier(connection)] = nil }
        connection.stateUpdateHandler = nil
        connection.cancel()
    }
}

fileprivate var screenshotCount = 0

extension BaseScreen {

    @MainActor @discardableResult
    func thenTakeScreenshot(named title: String, orientation: UIDeviceOrientation = .portrait) -> Self {
        XCUIDevice.shared.orientation = orientation
        screenshotCount += 1

        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(screenshotCount)-\(mode)-\(title)"

        snapshot(filename, timeWaitingForIdle: 0)

        return self
    }
}

extension ScreenObject {

    @MainActor @discardableResult
    func openNotificationCenterForScreenshot() -> Self {
        let appFrame = app.windows.firstMatch.frame
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.activate()
        // A window anchor preserves the active display; application coordinates use Duo's outer display.
        guard let homeWindow = springboard.windows.allElementsBoundByIndex.first(where: {
            abs($0.frame.width - appFrame.width) < 1 && abs($0.frame.height - appFrame.height) < 1 && $0.icons.firstMatch.exists
        }) else {
            XCTFail("The active display's Home window must be available before opening Notification Center.")
            return self
        }
        let top = homeWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
        let bottom = homeWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        top.press(forDuration: 0.1, thenDragTo: bottom)

        // The fixture amount uses either decimal separator across the supported translations.
        let notification = springboard.windows["SBCoverSheetWindow"].buttons
            .matching(NSPredicate(format: "label MATCHES %@", ".*13[.,]98.*")).firstMatch
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: notification)
        if XCTWaiter.wait(for: [visible], timeout: 20) != .completed {
            XCTContext.runActivity(named: "Missing order notification") { activity in
                activity.add(XCTAttachment(string: springboard.debugDescription))
                for (index, screen) in XCUIScreen.screens.enumerated() {
                    let attachment = XCTAttachment(screenshot: screen.screenshot())
                    attachment.name = "Display \(index)"
                    activity.add(attachment)
                }
            }
            XCTFail("The mocked order notification must be visible before capturing it.")
        }
        return self
    }

    @MainActor @discardableResult
    func thenTakeScreenshot(named title: String, orientation: UIDeviceOrientation = .portrait) -> Self {
        XCUIDevice.shared.orientation = orientation
        screenshotCount += 1

        let mode = XCUIDevice.inDarkMode ? "dark" : "light"
        let filename = "\(screenshotCount)-\(mode)-\(title)"

        snapshot(filename, timeWaitingForIdle: 0)

        return self
    }
}
