import Foundation
import class Networking.UserAgent
import struct NetworkingCore.WordPressAPIDiscovery
import protocol NetworkingCore.URLSessionProtocol
import protocol WooFoundation.ConnectivityObserver
import class WordPressAuthenticator.WordPressComSiteInfo

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
    }

    /// Cards to be rendered by the view.
    ///
    @Published var cards: [PreLoginCheckCard] = []

    /// The site URL being tested.
    ///
    let siteURL: URL

    /// The discovered REST API root URL, set by the `apiDiscovery` test.
    ///
    private(set) var restAPIRootURL: URL?

    /// Session for making HTTP requests (injectable for testing).
    ///
    private let session: URLSessionProtocol

    /// Connectivity observer for internet check.
    ///
    private let connectivityObserver: ConnectivityObserver

    private var latestTestResults: [PreLoginTestResult] = []
    private static let requestTimeout: TimeInterval = 15

    init(siteURL: URL,
         session: URLSessionProtocol = URLSession.shared,
         connectivityObserver: ConnectivityObserver = ServiceLocator.connectivityObserver) {
        self.siteURL = siteURL
        self.session = session
        self.connectivityObserver = connectivityObserver
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
        }
    }
}

// MARK: - Test Implementations
//
private extension PreLoginConnectivityToolViewModel {

    enum Endpoint {
        static let siteInfoBase = "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url="
        static let wooCommerceAPI = "wc/v3"
        static let applicationPasswords = "wp/v2/users/me/application-passwords"
    }

    // MARK: Test 1: Internet Connectivity

    func testInternetConnectivity() -> PreLoginCheckState {
        let status = connectivityObserver.currentStatus
        if case .reachable = status {
            return .success(summary: Localization.SuccessInfo.internetConnected,
                            detail: PreLoginCheckDetail.local("Status: reachable"))
        }
        let summary = Localization.ErrorMessage.withDetail(.noInternet, .noInternetDetail)
        return .error(summary: summary, detail: PreLoginCheckDetail.local("Status: \(status)"))
    }

    // MARK: Test 2: Site Info

    func testSiteInfo() async -> PreLoginCheckState {
        let siteInfoURLString = Endpoint.siteInfoBase + siteURL.absoluteString
        guard let url = URL(string: siteInfoURLString) else {
            let summary = Localization.ErrorMessage.withDetail(.siteInfoFailed, .siteInfoFailedDetail)
            return .error(summary: summary, detail: PreLoginCheckDetail.local("Invalid URL: \(siteInfoURLString)"))
        }

        switch await performRequest(url: url) {
        case .success(let result):
            guard (200...299).contains(result.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: result.data) as? [AnyHashable: Any] else {
                return .error(summary: Localization.ErrorMessage.withDetail(.siteInfoFailed, .siteInfoFailedDetail), detail: result.detail.formatted)
            }
            let summary = formatSiteInfoSummary(WordPressComSiteInfo(remote: json))
            return .success(summary: summary, detail: result.detail.formatted)

        case .failure(let detail):
            return .error(summary: Localization.ErrorMessage.withDetail(.siteInfoFailed, .siteInfoFailedDetail), detail: detail.formatted)
        }
    }

    // MARK: Test 3: API Discovery

    func testAPIDiscovery() async -> PreLoginCheckState {
        let discovery = WordPressAPIDiscovery(session: session)
        let startTime = Date()
        let rootURLString = await discovery.discoverRESTAPIRootURL(for: siteURL.absoluteString)
        let timeTaken = Date().timeIntervalSince(startTime)
        let timeFormatted = String(format: "%.0fms", timeTaken * 1000)

        if let rootURLString, let rootURL = URL(string: rootURLString) {
            restAPIRootURL = rootURL
            return .success(summary: Localization.SuccessInfo.apiDiscovered,
                            detail: PreLoginCheckDetail.local("API root: \(rootURLString)\nTime: \(timeFormatted)"))
        }

        return .error(summary: Localization.ErrorMessage.withDetail(.apiDiscoveryFailed, .apiDiscoveryFailedDetail),
                      detail: PreLoginCheckDetail.local("Site: \(siteURL.absoluteString)\nTime: \(timeFormatted)"))
    }

    // MARK: Test 4: WordPress REST API

    func testWordPressRESTAPI() async -> PreLoginCheckState {
        guard let apiRoot = restAPIRootURL else {
            return .error(summary: Localization.ErrorMessage.withDetail(.noRESTAPI, .noRESTAPIDetail),
                          detail: PreLoginCheckDetail.local("No API root URL available from discovery"))
        }

        switch await performRequest(url: apiRoot) {
        case .success(let result):
            guard (200...299).contains(result.statusCode) else {
                return .error(summary: Localization.ErrorMessage.withDetail(.noRESTAPI, .noRESTAPIDetail), detail: result.detail.formatted)
            }
            if let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
               json["namespaces"] != nil || json["name"] != nil {
                return .success(summary: Localization.SuccessInfo.restAPIAvailable, detail: result.detail.formatted)
            }
            return .error(summary: Localization.ErrorMessage.withDetail(.noRESTAPI, .noRESTAPIDetail), detail: result.detail.formatted)

        case .failure(let detail):
            return .error(summary: Localization.ErrorMessage.withDetail(.noRESTAPI, .noRESTAPIDetail), detail: detail.formatted)
        }
    }

    // MARK: Test 5: WooCommerce API

    func testWooCommerceAPI() async -> PreLoginCheckState {
        guard let apiRoot = restAPIRootURL else {
            return .error(summary: Localization.ErrorMessage.withDetail(.noWooCommerce, .noWooCommerceDetail),
                          detail: PreLoginCheckDetail.local("No API root URL available from discovery"))
        }

        let wcURL = apiRoot.appending(path: Endpoint.wooCommerceAPI)
        switch await performRequest(url: wcURL) {
        case .success(let result):
            guard (200...299).contains(result.statusCode) else {
                return .error(summary: Localization.ErrorMessage.withDetail(.noWooCommerce, .noWooCommerceDetail), detail: result.detail.formatted)
            }
            if let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any] {
                let hasWCNamespace = (json["namespace"] as? String)?.contains("wc") == true
                let hasWCRoutes = (json["routes"] as? [String: Any])?.keys.contains(where: { $0.contains("/wc/") }) == true
                if hasWCNamespace || hasWCRoutes {
                    return .success(summary: Localization.SuccessInfo.wooCommerceActive, detail: result.detail.formatted)
                }
            }
            return .error(summary: Localization.ErrorMessage.withDetail(.noWooCommerce, .noWooCommerceDetail), detail: result.detail.formatted)

        case .failure(let detail):
            return .error(summary: Localization.ErrorMessage.withDetail(.noWooCommerce, .noWooCommerceDetail), detail: detail.formatted)
        }
    }

    // MARK: Test 6: Application Passwords

    func testApplicationPasswords() async -> PreLoginCheckState {
        guard let apiRoot = restAPIRootURL else {
            return .error(summary: Localization.ErrorMessage.withDetail(.applicationPasswordsUnavailable, .applicationPasswordsUnavailableDetail),
                          detail: PreLoginCheckDetail.local("No API root URL available from discovery"))
        }

        let url = apiRoot.appending(path: Endpoint.applicationPasswords)
        switch await performRequest(url: url) {
        case .success(let result):
            switch result.statusCode {
            case 401:
                if let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
                   let code = json["code"] as? String,
                   code == "application_passwords_disabled" {
                    let summary = Localization.ErrorMessage.withDetail(.applicationPasswordsDisabled,
                                                                      .applicationPasswordsDisabledDetail)
                    return .error(summary: summary, detail: result.detail.formatted)
                }
                return .success(summary: Localization.SuccessInfo.applicationPasswordsAvailable,
                                detail: result.detail.formatted)
            case 200...299:
                return .success(summary: Localization.SuccessInfo.applicationPasswordsAvailable,
                                detail: result.detail.formatted)
            default:
                let summary = Localization.ErrorMessage.withDetail(.applicationPasswordsUnavailable,
                                                                   .applicationPasswordsUnavailableDetail)
                return .error(summary: summary, detail: result.detail.formatted)
            }

        case .failure(let detail):
            let summary = Localization.ErrorMessage.withDetail(.applicationPasswordsUnavailable,
                                                               .applicationPasswordsUnavailableDetail)
            return .error(summary: summary, detail: detail.formatted)
        }
    }
}

// MARK: - Site Info Formatting
//
private extension PreLoginConnectivityToolViewModel {

    func formatSiteInfoSummary(_ info: WordPressComSiteInfo) -> String {
        var lines: [String] = []

        if info.isWP {
            lines.append(Localization.SiteInfo.wordPressDetected)
        } else {
            lines.append(Localization.SiteInfo.wordPressNotDetected)
        }

        if info.hasJetpack {
            if info.isJetpackConnected {
                lines.append(Localization.SiteInfo.jetpackConnected)
            } else if info.isJetpackActive {
                lines.append(Localization.SiteInfo.jetpackActiveNotConnected)
            } else {
                lines.append(Localization.SiteInfo.jetpackInstalledNotActive)
            }
        } else {
            lines.append(Localization.SiteInfo.jetpackNotInstalled)
        }

        if info.isCommerceGarden {
            lines.append(Localization.SiteInfo.commerceGarden)
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - HTTP Helpers
//
private extension PreLoginConnectivityToolViewModel {

    struct RequestResult {
        let data: Data
        let statusCode: Int
        let body: String
        let headers: [String: String]
        let detail: PreLoginCheckDetail
    }

    func performRequest(url: URL, method: String = "GET") async -> Result<RequestResult, PreLoginCheckDetail> {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = Self.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let startTime = Date()
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            let headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
            let detail = PreLoginCheckDetail(url: url.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: httpResponse.statusCode,
                                             headers: headers,
                                             responseBody: body)
            return .success(RequestResult(data: data, statusCode: httpResponse.statusCode,
                                          body: body, headers: headers, detail: detail))
        } catch {
            let detail = PreLoginCheckDetail(url: url.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: nil,
                                             headers: [:],
                                             responseBody: String(describing: error))
            return .failure(detail)
        }
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
    }

    var icon: ConnectivityToolCard.Icon {
        switch self {
        case .internetConnection: .system("wifi")
        case .siteInfo: .system("info.circle")
        case .apiDiscovery: .system("magnifyingglass")
        case .wordPressRESTAPI: .system("arrow.left.arrow.right")
        case .wooCommerceAPI: .system("storefront")
        case .applicationPasswords: .system("key")
        }
    }

    var inProgressCard: PreLoginCheckCard {
        PreLoginCheckCard(title: title, icon: icon, state: .inProgress)
    }
}

// MARK: - Localization
//
private extension PreLoginConnectivityToolViewModel {

    // swiftlint:disable nesting
    enum Localization {
        enum ErrorMessage {
            static let noInternet = NSLocalizedString(
                "preLoginConnectivityTool.error.noInternet",
                value: "It looks like you're not connected to the internet.",
                comment: "Error message when there is no internet connection in the pre-login connectivity tool"
            )
            static let noInternetDetail = NSLocalizedString(
                "preLoginConnectivityTool.error.noInternetDetail",
                value: "Ensure your Wi-Fi is turned on. If you're using mobile data, make sure it's enabled in your device settings.",
                comment: "Additional guidance for no internet connection error in the pre-login connectivity tool"
            )
            static let siteInfoFailed = NSLocalizedString(
                "preLoginConnectivityTool.error.siteInfoFailed",
                value: "Could not retrieve site information.",
                comment: "Error message when site info lookup fails in the pre-login connectivity tool"
            )
            static let siteInfoFailedDetail = NSLocalizedString(
                "preLoginConnectivityTool.error.siteInfoFailedDetail",
                value: "Please check the URL is correct and that your site is online.",
                comment: "Additional guidance for site info failure in the pre-login connectivity tool"
            )
            static let apiDiscoveryFailed = NSLocalizedString(
                "preLoginConnectivityTool.error.apiDiscoveryFailed",
                value: "Could not discover the REST API endpoint for your site.",
                comment: "Error message when REST API discovery fails in the pre-login connectivity tool"
            )
            static let apiDiscoveryFailedDetail = NSLocalizedString(
                "preLoginConnectivityTool.error.apiDiscoveryFailedDetail",
                value: "The site may not have a WordPress REST API or it may be disabled.",
                comment: "Additional guidance for API discovery failure in the pre-login connectivity tool"
            )
            static let noRESTAPI = NSLocalizedString(
                "preLoginConnectivityTool.error.noRESTAPI",
                value: "The WordPress REST API is not available on your site.",
                comment: "Error message when REST API is unavailable in the pre-login connectivity tool"
            )
            static let noRESTAPIDetail = NSLocalizedString(
                "preLoginConnectivityTool.error.noRESTAPIDetail",
                value: "Ensure pretty permalinks are enabled, or contact your hosting provider.",
                comment: "Additional guidance for REST API unavailable in the pre-login connectivity tool"
            )
            static let noWooCommerce = NSLocalizedString(
                "preLoginConnectivityTool.error.noWooCommerce",
                value: "WooCommerce doesn't appear to be active on your site.",
                comment: "Error message when WooCommerce is not active in the pre-login connectivity tool"
            )
            static let noWooCommerceDetail = NSLocalizedString(
                "preLoginConnectivityTool.error.noWooCommerceDetail",
                value: "Make sure the WooCommerce plugin is installed and activated.",
                comment: "Additional guidance for WooCommerce not active in the pre-login connectivity tool"
            )
            static let applicationPasswordsDisabled = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsDisabled",
                value: "Application Passwords are disabled on your site.",
                comment: "Error message when application passwords are disabled in the pre-login connectivity tool"
            )
            static let applicationPasswordsDisabledDetail = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsDisabledDetail",
                value: "This feature is required for the WooCommerce app. Please enable it or contact your hosting provider.",
                comment: "Additional guidance for application passwords disabled in the pre-login connectivity tool"
            )
            static let applicationPasswordsUnavailable = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsUnavailable",
                value: "Application Passwords are not available on your site.",
                comment: "Error message when application passwords are not available in the pre-login connectivity tool"
            )
            static let applicationPasswordsUnavailableDetail = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsUnavailableDetail",
                value: "This feature requires WordPress 5.6 or later. Please update WordPress.",
                comment: "Additional guidance for application passwords unavailable in the pre-login connectivity tool"
            )

            /// Combines a summary and detail string with a paragraph break.
            static func withDetail(_ summary: String, _ detail: String) -> String {
                summary + "\n\n" + detail
            }
        }

        enum SuccessInfo {
            static let internetConnected = NSLocalizedString(
                "preLoginConnectivityTool.success.internetConnected",
                value: "Your device is connected to the internet.",
                comment: "Success info when internet connectivity check passes in the pre-login connectivity tool"
            )
            static let apiDiscovered = NSLocalizedString(
                "preLoginConnectivityTool.success.apiDiscovered",
                value: "REST API endpoint discovered.",
                comment: "Success info when REST API discovery succeeds in the pre-login connectivity tool"
            )
            static let restAPIAvailable = NSLocalizedString(
                "preLoginConnectivityTool.success.restAPIAvailable",
                value: "The WordPress REST API is available.",
                comment: "Success info when REST API check passes in the pre-login connectivity tool"
            )
            static let wooCommerceActive = NSLocalizedString(
                "preLoginConnectivityTool.success.wooCommerceActive",
                value: "WooCommerce is active on your site.",
                comment: "Success info when WooCommerce check passes in the pre-login connectivity tool"
            )
            static let applicationPasswordsAvailable = NSLocalizedString(
                "preLoginConnectivityTool.success.applicationPasswordsAvailable",
                value: "Application Passwords are supported.",
                comment: "Success info when application passwords are available in the pre-login connectivity tool"
            )
        }

        enum SiteInfo {
            static let wordPressDetected = NSLocalizedString(
                "preLoginConnectivityTool.siteInfo.wordPressDetected",
                value: "WordPress site detected.",
                comment: "Site info line shown when the site is a WordPress site"
            )
            static let wordPressNotDetected = NSLocalizedString(
                "preLoginConnectivityTool.siteInfo.wordPressNotDetected",
                value: "WordPress was not detected on this site.",
                comment: "Site info line shown when the site is not a WordPress site"
            )
            static let jetpackConnected = NSLocalizedString(
                "preLoginConnectivityTool.siteInfo.jetpackConnected",
                value: "Jetpack is installed and connected.",
                comment: "Site info line shown when Jetpack is installed and connected"
            )
            static let jetpackActiveNotConnected = NSLocalizedString(
                "preLoginConnectivityTool.siteInfo.jetpackActiveNotConnected",
                value: "Jetpack is installed and active, but not connected.",
                comment: "Site info line shown when Jetpack is active but not connected"
            )
            static let jetpackInstalledNotActive = NSLocalizedString(
                "preLoginConnectivityTool.siteInfo.jetpackInstalledNotActive",
                value: "Jetpack is installed but not active.",
                comment: "Site info line shown when Jetpack is installed but not active"
            )
            static let jetpackNotInstalled = NSLocalizedString(
                "preLoginConnectivityTool.siteInfo.jetpackNotInstalled",
                value: "Jetpack is not installed.",
                comment: "Site info line shown when Jetpack is not installed"
            )
            static let commerceGarden = NSLocalizedString(
                "preLoginConnectivityTool.siteInfo.commerceGarden",
                value: "eCommerce Garden site.",
                comment: "Site info line shown when the site is an eCommerce Garden (CIAB) site"
            )
        }
    }
    // swiftlint:enable nesting
}
