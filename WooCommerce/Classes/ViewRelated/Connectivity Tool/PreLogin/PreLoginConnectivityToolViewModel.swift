import Foundation
import Combine
import class Networking.UserAgent
import struct NetworkingCore.WordPressAPIDiscovery
import protocol NetworkingCore.URLSessionProtocol
import protocol WooFoundation.Analytics
import protocol WooFoundation.ConnectivityObserver

/// Represents the state of a pre-login connectivity check.
///
/// - `summary`: A user-facing description of the result.
/// - `detail`: Technical detail including the request URL, time taken, HTTP status, and response body.
///
enum PreLoginCheckState {
    case inProgress
    case success(summary: String, detail: String)
    case error(summary: String, detail: String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

/// Captures technical detail about an HTTP request/response for display in a check result.
///
struct PreLoginCheckDetail {
    let url: String
    let timeTaken: TimeInterval
    let statusCode: Int?
    let headers: [String: String]
    let responseBody: String

    /// Formats the detail as a multi-line technical description.
    ///
    var formatted: String {
        var lines: [String] = []
        lines.append("URL: \(url)")
        lines.append("Time: \(String(format: "%.0fms", timeTaken * 1000))")
        if let statusCode {
            lines.append("Status: \(statusCode)")
        }
        if !headers.isEmpty {
            let headerLines = headers.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n  ")
            lines.append("Headers:\n  \(headerLines)")
        }
        if !responseBody.isEmpty {
            let truncated = responseBody.prefix(500)
            lines.append("Response: \(truncated)")
        }
        return lines.joined(separator: "\n")
    }

    /// Creates a detail string for a non-HTTP check (e.g. internet connectivity, blocking analysis).
    ///
    static func local(_ info: String) -> String {
        info
    }
}

/// A single card in the pre-login connectivity tool.
///
struct PreLoginCheckCard {
    let title: String
    let icon: ConnectivityToolCard.Icon
    let state: PreLoginCheckState

    func updatingState(_ newState: PreLoginCheckState) -> PreLoginCheckCard {
        PreLoginCheckCard(title: title, icon: icon, state: newState)
    }
}

/// ViewModel for the pre-login connectivity tool.
/// Runs unauthenticated checks against a user-provided site URL.
///
@MainActor
final class PreLoginConnectivityToolViewModel: ObservableObject {

    /// Tests run sequentially in this order.
    ///
    enum ConnectivityTest: Int, CaseIterable {
        case internetConnection
        case siteInfo
        case apiDiscovery
        case wordPressRESTAPI
        case wooCommerceAPI
        case applicationPasswords
        case loginPageAnalysis
    }

    /// Cards to be rendered by the view.
    ///
    @Published var cards: [PreLoginCheckCard] = []

    /// The site URL being tested.
    ///
    let siteURL: URL

    /// The discovered REST API root URL, set by the `apiDiscovery` test.
    /// Used by subsequent tests to build API endpoint URLs.
    ///
    var restAPIRootURL: URL?

    /// Session for making HTTP requests (injectable for testing).
    ///
    let session: URLSessionProtocol

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    /// Connectivity observer for internet check.
    ///
    let connectivityObserver: ConnectivityObserver

    /// Results for all completed tests.
    ///
    private var latestTestResults: [PreLoginTestResult] = []

    /// Request timeout in seconds.
    ///
    private static let requestTimeout: TimeInterval = 15

    init(siteURL: URL,
         session: URLSessionProtocol = URLSession.shared,
         analytics: Analytics = ServiceLocator.analytics,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver) {
        self.siteURL = siteURL
        self.session = session
        self.analytics = analytics
        self.connectivityObserver = connectivityObserver

        analytics.track(event: .PreLoginConnectivityTool.opened())

        Task {
            await startConnectivityTests()
        }
    }

    /// Runs all connectivity tests sequentially.
    ///
    func startConnectivityTests() async {
        for testCase in ConnectivityTest.allCases {
            let cardIndex = cards.count
            cards.append(testCase.inProgressCard)

            let startTime = Date()
            let testResult = await runTest(for: testCase)
            let timeTaken = Date().timeIntervalSince(startTime)

            cards[cardIndex] = cards[cardIndex].updatingState(testResult)

            trackResponseEvent(for: testCase, success: testResult.isSuccess, timeTaken: timeTaken)
            latestTestResults.append(PreLoginTestResult(testCase: testCase, result: testResult, timeTaken: timeTaken))
        }
    }

    /// Generates a text description of test results for support attachment.
    ///
    func troubleshootingDescription() -> String? {
        guard !latestTestResults.isEmpty else { return nil }
        return latestTestResults.enumerated().map { index, result in
            "## \(index + 1). " + result.description()
        }.joined()
    }
}

// MARK: - Test Dispatch
//
private extension PreLoginConnectivityToolViewModel {

    func runTest(for testCase: ConnectivityTest) async -> PreLoginCheckState {
        switch testCase {
        case .internetConnection:
            return testInternetConnectivity()
        case .siteInfo:
            return await testSiteInfo()
        case .apiDiscovery:
            return await testAPIDiscovery()
        case .wordPressRESTAPI:
            return await testWordPressRESTAPI()
        case .wooCommerceAPI:
            return await testWooCommerceAPI()
        case .applicationPasswords:
            return await testApplicationPasswords()
        case .loginPageAnalysis:
            return await testLoginPage()
        }
    }
}

// MARK: - HTTP Helpers
//
extension PreLoginConnectivityToolViewModel {

    /// Makes an HTTP request and returns the response data, response, and body string.
    ///
    func makeRequest(url: URL, method: String = "GET") async throws -> (Data, HTTPURLResponse, String) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = Self.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let body = String(data: data, encoding: .utf8) ?? ""
        return (data, httpResponse, body)
    }

}

// MARK: - Analytics
//
private extension PreLoginConnectivityToolViewModel {

    func trackResponseEvent(for test: ConnectivityTest, success: Bool, timeTaken: Double) {
        let eventTest: WooAnalyticsEvent.PreLoginConnectivityTool.Test = {
            switch test {
            case .internetConnection: return .internet
            case .siteInfo: return .site
            case .apiDiscovery: return .apiDiscovery
            case .wordPressRESTAPI: return .restAPI
            case .wooCommerceAPI: return .wooCommerce
            case .applicationPasswords: return .applicationPasswords
            case .loginPageAnalysis: return .loginPage
            }
        }()
        analytics.track(event: .PreLoginConnectivityTool.requestResponse(test: eventTest, success: success, timeTaken: timeTaken))
    }
}

// MARK: - Supporting Types
//
private struct PreLoginTestResult {
    let testCase: PreLoginConnectivityToolViewModel.ConnectivityTest
    let result: PreLoginCheckState
    let timeTaken: TimeInterval

    func description() -> String {
        [caseName, "Took: \(formattedTimeTaken)", "Result: \(resultDescription)", ""].joined(separator: "\n")
    }

    private var formattedTimeTaken: String {
        String(format: "%.0fms", timeTaken * 1000)
    }

    private var caseName: String {
        switch testCase {
        case .internetConnection: "Internet Connection"
        case .siteInfo: "Site Info"
        case .apiDiscovery: "API Discovery"
        case .wordPressRESTAPI: "WordPress REST API"
        case .wooCommerceAPI: "WooCommerce API"
        case .applicationPasswords: "Application Passwords"
        case .loginPageAnalysis: "Login Page Analysis"
        }
    }

    private var resultDescription: String {
        switch result {
        case .inProgress: return "In progress"
        case .success(let summary, let detail): return "\(summary)\n\(detail)"
        case .error(let summary, let detail): return "\(summary)\n\(detail)"
        }
    }
}

// MARK: - ConnectivityTest Card Properties
//
extension PreLoginConnectivityToolViewModel.ConnectivityTest {

    var title: String {
        switch self {
        case .internetConnection: Localization.internetConnection
        case .siteInfo: Localization.siteInfo
        case .apiDiscovery: Localization.apiDiscovery
        case .wordPressRESTAPI: Localization.wordPressRESTAPI
        case .wooCommerceAPI: Localization.wooCommerceAPI
        case .applicationPasswords: Localization.applicationPasswords
        case .loginPageAnalysis: Localization.loginPageAnalysis
        }
    }

    private enum Localization {
        static let internetConnection = NSLocalizedString(
            "preLoginConnectivityTool.test.internetConnection",
            value: "Internet Connection",
            comment: "Title for the internet connection test card in the pre-login connectivity tool"
        )
        static let siteInfo = NSLocalizedString(
            "preLoginConnectivityTool.test.siteInfo",
            value: "Site Info",
            comment: "Title for the site info test card in the pre-login connectivity tool"
        )
        static let apiDiscovery = NSLocalizedString(
            "preLoginConnectivityTool.test.apiDiscovery",
            value: "API Discovery",
            comment: "Title for the REST API discovery test card in the pre-login connectivity tool"
        )
        static let wordPressRESTAPI = NSLocalizedString(
            "preLoginConnectivityTool.test.wordPressRESTAPI",
            value: "WordPress REST API",
            comment: "Title for the WordPress REST API test card in the pre-login connectivity tool"
        )
        static let wooCommerceAPI = NSLocalizedString(
            "preLoginConnectivityTool.test.wooCommerceAPI",
            value: "WooCommerce Plugin",
            comment: "Title for the WooCommerce API test card in the pre-login connectivity tool"
        )
        static let applicationPasswords = NSLocalizedString(
            "preLoginConnectivityTool.test.applicationPasswords",
            value: "Application Passwords",
            comment: "Title for the application passwords test card in the pre-login connectivity tool"
        )
        static let loginPageAnalysis = NSLocalizedString(
            "preLoginConnectivityTool.test.loginPageAnalysis",
            value: "Login Page Analysis",
            comment: "Title for the login page analysis test card in the pre-login connectivity tool"
        )
    }

    var icon: ConnectivityToolCard.Icon {
        switch self {
        case .internetConnection: .system("wifi")
        case .siteInfo: .system("info.circle")
        case .apiDiscovery: .system("magnifyingglass")
        case .wordPressRESTAPI: .system("arrow.left.arrow.right")
        case .wooCommerceAPI: .system("storefront")
        case .applicationPasswords: .system("key")
        case .loginPageAnalysis: .system("person.badge.key")
        }
    }

    var inProgressCard: PreLoginCheckCard {
        PreLoginCheckCard(title: title, icon: icon, state: .inProgress)
    }
}

