import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class WPComConnectionSetupHandlerTests: XCTestCase {

    private let testSiteURL = "https://example.com"

    private var mockConnectionService: MockJetpackConnectionService!
    private var mockPluginVersionChecker: MockPluginVersionChecker!
    private var delegateSpy: MockWPComConnectionSetupHandlerDelegate!

    override func setUp() {
        super.setUp()
        mockConnectionService = MockJetpackConnectionService()
        mockPluginVersionChecker = MockPluginVersionChecker()
        delegateSpy = MockWPComConnectionSetupHandlerDelegate()
    }

    override func tearDown() {
        mockConnectionService = nil
        mockPluginVersionChecker = nil
        delegateSpy = nil
        super.tearDown()
    }

    // MARK: - start() Tests

    func test_start_with_alreadyConnected_marks_connect_step_as_success() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .success(.alreadyConnected(email: "test@example.com"))
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 4)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[0].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .success)
    }

    func test_start_with_connected_marks_connect_step_as_success() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .success(.connected(email: "test@example.com"))
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 4)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .success)
    }

    func test_start_with_webViewRequired_triggers_web_view_with_account_connection_url() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .success(.webViewRequired)
        let accountURL = URL(string: "https://jetpack.wordpress.com/jetpack.authorize/123")!
        mockConnectionService.fetchJetpackConnectionURLResult = .success(accountURL)
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForWebViewRequired()

        // Then
        XCTAssertEqual(delegateSpy.webViewURLs.count, 1)
        XCTAssertEqual(delegateSpy.webViewURLs.first?.url, accountURL)
        XCTAssertEqual(delegateSpy.webViewURLs.first?.siteURL, testSiteURL)
    }

    func test_start_with_webViewRequired_uses_fallback_url_when_not_account_connection() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .success(.webViewRequired)
        let nonAccountURL = URL(string: "https://other.example.com/connect")!
        mockConnectionService.fetchJetpackConnectionURLResult = .success(nonAccountURL)
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForWebViewRequired()

        // Then
        let expectedFallback = URL(string: "\(testSiteURL)/wp-admin/admin.php?page=jetpack")!
        XCTAssertEqual(delegateSpy.webViewURLs.first?.url, expectedFallback)
    }

    func test_start_without_credentials_does_not_run_connect_step() async throws {
        // Given
        let handler = makeHandler(credentials: .none)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(mockConnectionService.evaluateAndConnectCallCount, 0)
        XCTAssertFalse(delegateSpy.stepUpdates.contains { $0.step == .connect && $0.status == .running })
    }

    func test_start_with_evaluateAndConnect_failure_marks_connect_step_as_failure() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates.count, 2)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        assertFailureStatus(delegateSpy.stepUpdates[1].status)
    }

    func test_start_with_fetchURL_failure_marks_connect_step_as_failure() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .success(.webViewRequired)
        mockConnectionService.fetchJetpackConnectionURLResult = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates.count, 2)
        assertFailureStatus(delegateSpy.stepUpdates[1].status)
    }

    // MARK: - didAuthorizeWebViewConnection() Tests

    func test_didAuthorizeWebViewConnection_verifies_connection_and_marks_success() async throws {
        // Given
        mockConnectionService.verifyConnectionResult = .success("test@example.com")
        let handler = makeHandler()

        // When
        handler.didAuthorizeWebViewConnection()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(mockConnectionService.verifyConnectionCallCount, 1)
        XCTAssertEqual(delegateSpy.stepUpdates[0].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .success)
    }

    func test_didAuthorizeWebViewConnection_on_verification_failure_marks_failure() async throws {
        // Given
        mockConnectionService.verifyConnectionResult = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler()

        // When
        handler.didAuthorizeWebViewConnection()
        await delegateSpy.waitForStepUpdate(count: 1)

        // Then
        XCTAssertEqual(mockConnectionService.verifyConnectionCallCount, 1)
        assertFailureStatus(delegateSpy.stepUpdates.first?.status)
    }

    // MARK: - didEncounterWebViewError() Tests

    func test_didEncounterWebViewError_marks_connect_step_as_failure() {
        // Given
        let handler = makeHandler()

        // When
        handler.didEncounterWebViewError(code: 404)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates.count, 1)
        XCTAssertEqual(delegateSpy.stepUpdates.first?.step, .connect)
        assertFailureStatus(delegateSpy.stepUpdates.first?.status)
    }

    // MARK: - didCancelWebView() Tests

    func test_didCancelWebView_marks_connect_step_as_failure() {
        // Given
        let handler = makeHandler()

        // When
        handler.didCancelWebView()

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates.count, 1)
        XCTAssertEqual(delegateSpy.stepUpdates.first?.step, .connect)
        assertFailureStatus(delegateSpy.stepUpdates.first?.status)
    }

    // MARK: - retry() Tests

    func test_retry_after_connection_failure_restarts_connection() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler()
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Reset for retry
        mockConnectionService.evaluateAndConnectResult = .success(.alreadyConnected(email: "test@example.com"))
        delegateSpy.stepUpdates.removeAll()

        // When
        handler.retry()
        await delegateSpy.waitForStepUpdate(count: 4)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[0].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .connect)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .success)
    }

    // MARK: - Plugin Version Check Tests

    func test_start_with_connection_success_chains_to_plugin_check_success() async throws {
        // Given
        mockConnectionService.evaluateAndConnectResult = .success(.alreadyConnected(email: "test@example.com"))
        mockPluginVersionChecker.result = .success(.compatible)
        let handler = makeHandler()

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 4)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[2].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[3].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[3].status, .success)
    }

    func test_start_without_credentials_starts_plugin_check() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.compatible)
        let handler = makeHandler(credentials: .none)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[2].status, .success)
    }

    func test_plugin_check_incompatible_marks_step_as_failure_with_outdated_message() async throws {
        // Given
        mockPluginVersionChecker.result = .success(.incompatible(currentVersion: "10.3.4", requiredVersion: "10.5.3"))
        let handler = makeHandler(credentials: .none)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[2].status, .failure(error: .outdatedPlugin(version: "10.3.4")))
    }

    func test_plugin_check_error_marks_step_as_failure_with_generic_error() async throws {
        // Given
        mockPluginVersionChecker.result = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler(credentials: .none)

        // When
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        assertFailureStatus(delegateSpy.stepUpdates[2].status)
    }

    func test_retry_after_plugin_check_failure_restarts_plugin_check() async throws {
        // Given
        mockPluginVersionChecker.result = .failure(NSError(domain: "Test", code: -1))
        let handler = makeHandler(credentials: .none)
        handler.start()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Reset for retry
        mockPluginVersionChecker.result = .success(.compatible)
        delegateSpy.stepUpdates.removeAll()

        // When
        handler.retry()
        await delegateSpy.waitForStepUpdate(count: 2)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[0].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[0].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .success)
    }

    func test_didAuthorizeWebViewConnection_success_chains_to_plugin_check() async throws {
        // Given
        mockConnectionService.verifyConnectionResult = .success("test@example.com")
        mockPluginVersionChecker.result = .success(.compatible)
        let handler = makeHandler()

        // When
        handler.didAuthorizeWebViewConnection()
        await delegateSpy.waitForStepUpdate(count: 3)

        // Then
        XCTAssertEqual(delegateSpy.stepUpdates[1].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[1].status, .running)
        XCTAssertEqual(delegateSpy.stepUpdates[2].step, .checkPlugin)
        XCTAssertEqual(delegateSpy.stepUpdates[2].status, .success)
    }

    // MARK: - Helpers

    private enum CredentialsOption {
        case `default`
        case none
        case custom(Credentials)

        var value: Credentials? {
            switch self {
            case .default:
                return Credentials.wpcom(username: "test", authToken: "secret", siteAddress: "https://example.com")
            case .none:
                return nil
            case .custom(let creds):
                return creds
            }
        }
    }

    private func makeHandler(credentials: CredentialsOption = .default) -> WPComConnectionSetupHandler {
        let handler = WPComConnectionSetupHandler(
            siteID: 123,
            siteURL: testSiteURL,
            credentials: credentials.value,
            stores: MockStoresManager(sessionManager: .makeForTesting()),
            jetpackConnectionService: mockConnectionService,
            pluginVersionChecker: mockPluginVersionChecker
        )
        handler.delegate = delegateSpy
        return handler
    }

    private func assertFailureStatus(_ status: WPComConnectionSetupStep.Status?, file: StaticString = #filePath, line: UInt = #line) {
        guard let status else {
            XCTFail("Status is nil", file: file, line: line)
            return
        }
        if case .failure = status {
            // Expected
        } else {
            XCTFail("Expected .failure but got \(status)", file: file, line: line)
        }
    }
}

// MARK: - Mock Delegate

@MainActor
private final class MockWPComConnectionSetupHandlerDelegate: WPComConnectionSetupHandlerDelegate {
    struct StepUpdate {
        let step: SetupStep
        let status: WPComConnectionSetupStep.Status
    }

    struct WebViewURL {
        let url: URL
        let siteURL: String
    }

    var stepUpdates: [StepUpdate] = []
    var setupCompleteCalled = false
    var webViewURLs: [WebViewURL] = []

    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        stepUpdates.append(StepUpdate(step: step, status: status))
    }

    func setupDidComplete() {
        setupCompleteCalled = true
    }

    func setupDidRequireWebView(url: URL, siteURL: String) {
        webViewURLs.append(WebViewURL(url: url, siteURL: siteURL))
    }

    /// Polls until the expected number of step updates are received.
    func waitForStepUpdate(count: Int, timeout: TimeInterval = 2.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while stepUpdates.count < count, Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    /// Polls until at least one web view URL is received.
    func waitForWebViewRequired(timeout: TimeInterval = 2.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while webViewURLs.isEmpty, Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
}
