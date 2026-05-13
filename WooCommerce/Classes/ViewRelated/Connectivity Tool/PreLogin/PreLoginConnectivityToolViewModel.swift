import Foundation
import UIKit
import class Networking.UserAgent
import struct NetworkingCore.WordPressAPIDiscovery
import protocol NetworkingCore.URLSessionProtocol
import class WordPressAuthenticator.WordPressComSiteInfo
import protocol WooFoundation.Analytics
import protocol Experiments.FeatureFlagService

/// Represents the state of a pre-login connectivity check.
///
enum PreLoginCheckState {
    case inProgress
    case success(String)
    case error(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

/// The result of a connectivity check: a UI state and a diagnostic log for Zendesk.
///
typealias PreLoginCheckResult = (state: PreLoginCheckState, diagnosticLog: String)

/// A single card in the pre-login connectivity tool.
///
struct PreLoginCheckCard: Identifiable {
    let id = UUID()
    let title: String
    let icon: ConnectivityToolCard.Icon
    let state: PreLoginCheckState
    let diagnosticLog: String?

    init(title: String, icon: ConnectivityToolCard.Icon, state: PreLoginCheckState, diagnosticLog: String? = nil) {
        self.title = title
        self.icon = icon
        self.state = state
        self.diagnosticLog = diagnosticLog
    }

    func updatingState(_ newState: PreLoginCheckState, diagnosticLog: String? = nil) -> PreLoginCheckCard {
        PreLoginCheckCard(title: title, icon: icon, state: newState, diagnosticLog: diagnosticLog)
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
        case siteInfo
        case apiDiscovery
        case wordPressRESTAPI
        case wooCommerceAPI
        case applicationPasswords

        var analyticValue: String {
            switch self {
            case .siteInfo: "site_info"
            case .apiDiscovery: "api_discovery"
            case .wordPressRESTAPI: "wordpress_rest_api"
            case .wooCommerceAPI: "woocommerce_api"
            case .applicationPasswords: "application_passwords"
            }
        }
    }

    /// Cards to be rendered by the view.
    ///
    @Published var cards: [PreLoginCheckCard] = []

    /// Whether the chat button should be shown.
    /// True when bot chat is supported and all tests have completed.
    ///
    @Published private(set) var showChatButton = false

    /// Whether the contact support button should be shown.
    /// True when bot chat is NOT supported and all tests have completed.
    ///
    @Published private(set) var showContactSupportButton = false

    /// Whether the AI support chat is supported.
    ///
    var isBotChatSupported: Bool {
        featureFlagService.isFeatureFlagEnabled(.aiSupportChat)
    }

    /// The site URL being tested.
    ///
    let siteURL: URL

    /// The discovered REST API root URL, set by the `apiDiscovery` test.
    /// Falls back to `?rest_route=/` when discovery fails.
    ///
    private(set) var restAPIRootURL: URL?

    /// The parsed JSON from the REST API root response, shared by Tests 3–5.
    ///
    private(set) var restAPIRootJSON: [String: Any]?

    /// Session for making HTTP requests (injectable for testing).
    ///
    private let session: URLSessionProtocol

    /// Discovers the REST API root URL for a site. Injectable for testing.
    ///
    private let discoverAPIRoot: (String) async -> String?

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    /// Feature flag service for checking AI support chat availability.
    ///
    private let featureFlagService: FeatureFlagService

    private static let requestTimeout: TimeInterval = 15

    init(siteURL: URL,
         session: URLSessionProtocol = URLSession.shared,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         discoverAPIRoot: @escaping (String) async -> String? = {
             await WordPressAPIDiscovery().discoverRESTAPIRootURL(for: $0)
         }) {
        self.siteURL = siteURL
        self.session = session
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.discoverAPIRoot = discoverAPIRoot
    }

    /// Runs all connectivity tests sequentially.
    /// Skips execution if tests have already been started.
    ///
    private var hasStartedTests = false

    func startConnectivityTests() async {
        guard !hasStartedTests else { return }
        hasStartedTests = true

        cards = []
        restAPIRootURL = nil
        restAPIRootJSON = nil
        showChatButton = false
        showContactSupportButton = false

        for testCase in ConnectivityTest.allCases {
            let cardIndex = cards.count
            cards.append(testCase.inProgressCard)

            let startTime = Date()
            let (state, log) = await runTest(for: testCase)
            let timeTaken = Date().timeIntervalSince(startTime)

            cards[cardIndex] = cards[cardIndex].updatingState(state, diagnosticLog: log)

            trackResponseEvent(for: testCase, success: state.isSuccess, timeTaken: timeTaken)
        }

        // Show appropriate support button after all tests complete
        showChatButton = isBotChatSupported
        showContactSupportButton = !isBotChatSupported
    }

    /// Generates a text description of test results for support attachment.
    ///
    func troubleshootingDescription() -> String? {
        let logs = cards.compactMap { card -> String? in
            guard let log = card.diagnosticLog else { return nil }
            let statusIcon = card.state.isSuccess ? "✅" : "❌"
            return "### \(statusIcon) \(card.title)\n\(log)"
        }
        guard !logs.isEmpty else { return nil }
        let header = "# Connectivity Diagnosis Report\n**Site:** \(siteURL.absoluteString)"
        return header + "\n\n" + logs.joined(separator: "\n\n")
    }

    /// Creates a SupportChatViewModel with the current troubleshooting context.
    ///
    func makeSupportChatViewModel(onContactHumanSupport: @escaping (
        _ chatID: Int64?,
        _ transcript: String,
        _ supportAreaInfo: SupportAreaInfo?,
        _ entryPoint: SupportChatViewModel.EntryPoint
    ) -> Void) -> SupportChatViewModel {
        var context: [String: Any] = [:]

        if let troubleshootingDescription = troubleshootingDescription() {
            context["troubleshootingResults"] = troubleshootingDescription
        }

        context["site_url"] = siteURL.absoluteString

        return SupportChatViewModel(
            entryPoint: .preLogin,
            initialContext: context,
            onContactHumanSupport: onContactHumanSupport
        )
    }
}

// MARK: - Analytics
//
private extension PreLoginConnectivityToolViewModel {

    func trackResponseEvent(for test: ConnectivityTest, success: Bool, timeTaken: Double) {
        analytics.track(event: .ConnectivityTool.preLoginRequestResponse(testName: test.analyticValue, success: success, timeTaken: timeTaken))
    }
}

// MARK: - Test Dispatch
//
private extension PreLoginConnectivityToolViewModel {

    /// Returns the check state for the UI and a diagnostic log string for Zendesk.
    ///
    func runTest(for testCase: ConnectivityTest) async -> PreLoginCheckResult {
        switch testCase {
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
extension PreLoginConnectivityToolViewModel {

    private enum Constants {
        static let siteInfoPath = "/rest/v1.1/connect/site-info/"
        static let siteInfoHost = "public-api.wordpress.com"
        static let wooCommerceNamespace = "wc/v3"
        static let restRouteKey = "rest_route"
        static let namespacesKey = "namespaces"
        static let nameKey = "name"
        static let authenticationKey = "authentication"
        static let applicationPasswordsKey = "application-passwords"
        static let endpointsKey = "endpoints"
        static let authorizationKey = "authorization"
    }

    // MARK: Test 1: Site Info

    func testSiteInfo() async -> PreLoginCheckResult {
        var components = URLComponents()
        components.scheme = "https"
        components.host = Constants.siteInfoHost
        components.path = Constants.siteInfoPath
        components.queryItems = [URLQueryItem(name: "url", value: siteURL.absoluteString)]

        guard let url = components.url else {
            return (.error(Localization.ErrorMessage.siteInfoFailed), "Invalid URL for site: \(siteURL.absoluteString)")
        }

        switch await performRequest(url: url) {
        case .success(let result):
            guard (200...299).contains(result.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: result.data) as? [AnyHashable: Any] else {
                return (.error(Localization.ErrorMessage.siteInfoFailed), result.detail.formatted)
            }
            let summary = formatSiteInfoSummary(WordPressComSiteInfo(remote: json))
            return (.success(summary), result.detail.formatted)

        case .failure(let detail):
            return (.error(Localization.ErrorMessage.siteInfoFailed), detail.formatted)
        }
    }

    // MARK: Test 2: API Discovery

    func testAPIDiscovery() async -> PreLoginCheckResult {
        let startTime = Date()
        let rootURLString = await discoverAPIRoot(siteURL.absoluteString)
        let timeFormatted = String(format: "%.0fms", Date().timeIntervalSince(startTime) * 1000)

        if let rootURLString, let rootURL = URL(string: rootURLString) {
            restAPIRootURL = rootURL
            return (.success(Localization.SuccessInfo.apiDiscovered),
                    "API root: \(rootURLString)\nTime: \(timeFormatted)")
        }

        // Fall back to ?rest_route=/ so subsequent checks can still run.
        var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false)
        components?.path = "/"
        components?.queryItems = [URLQueryItem(name: Constants.restRouteKey, value: "/")]
        restAPIRootURL = components?.url
        return (.error(Localization.ErrorMessage.apiDiscoveryFailed),
                "No REST API Link header found for \(siteURL.absoluteString)\nFallback: \(String(describing: restAPIRootURL))\nTime: \(timeFormatted)")
    }

    // MARK: Test 3: WordPress REST API

    func testWordPressRESTAPI() async -> PreLoginCheckResult {
        guard let apiRoot = restAPIRootURL else {
            return (.error(Localization.ErrorMessage.noRESTAPI), "No API root URL from discovery")
        }

        switch await performRequest(url: apiRoot) {
        case .success(let result):
            guard (200...299).contains(result.statusCode) else {
                return (.error(Localization.ErrorMessage.noRESTAPI), result.detail.formatted)
            }
            if let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
               json[Constants.namespacesKey] != nil || json[Constants.nameKey] != nil {
                restAPIRootJSON = json
                return (.success(Localization.SuccessInfo.restAPIAvailable), result.detail.formatted)
            }
            return (.error(Localization.ErrorMessage.noRESTAPI), result.detail.formatted)

        case .failure(let detail):
            return (.error(Localization.ErrorMessage.noRESTAPI), detail.formatted)
        }
    }

    // MARK: Test 4: WooCommerce API

    func testWooCommerceAPI() async -> PreLoginCheckResult {
        guard let json = restAPIRootJSON else {
            return (.error(Localization.ErrorMessage.noWooCommerce), "No REST API root response")
        }
        let namespaces = json[Constants.namespacesKey] as? [String] ?? []
        let wcNamespaces = namespaces.filter { $0.hasPrefix(Constants.wooCommerceNamespace) }
        if wcNamespaces.isEmpty == false {
            return (.success(Localization.SuccessInfo.wooCommerceActive), "WooCommerce namespaces: \(wcNamespaces.joined(separator: ", "))")
        }
        return (.error(Localization.ErrorMessage.noWooCommerce), "Namespaces: \(namespaces)")
    }

    // MARK: Test 5: Application Passwords

    func testApplicationPasswords() async -> PreLoginCheckResult {
        guard let json = restAPIRootJSON else {
            return (.error(Localization.ErrorMessage.applicationPasswordsUnavailable), "No REST API root response")
        }
        let authentication = json[Constants.authenticationKey] as? [String: Any]
        let appPasswords = authentication?[Constants.applicationPasswordsKey] as? [String: Any]
        let endpoints = appPasswords?[Constants.endpointsKey] as? [String: Any]
        if let authorization = endpoints?[Constants.authorizationKey] {
            return (.success(Localization.SuccessInfo.applicationPasswordsAvailable), "Authorization endpoint: \(authorization)")
        }
        return (.error(Localization.ErrorMessage.applicationPasswordsUnavailable),
                "No application-passwords authorization endpoint found in the REST API root response")
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

    enum RequestOutcome {
        case success(RequestResult)
        case failure(RequestDetail)
    }

    struct RequestResult {
        let data: Data
        let statusCode: Int
        let detail: RequestDetail
    }

    /// Diagnostic detail for an HTTP request, used for Zendesk support attachment. Not user-facing.
    ///
    struct RequestDetail {
        let url: String
        let timeTaken: TimeInterval
        let statusCode: Int?
        let headers: [String: String]
        let responseBody: String

        var formatted: String {
            var lines: [String] = []
            lines.append("- **URL:** \(url)")
            lines.append("- **Time:** \(String(format: "%.0fms", timeTaken * 1000))")
            if let statusCode {
                lines.append("- **Status:** \(statusCode)")
            }
            if !headers.isEmpty {
                let headerLines = headers.map { "  - `\($0.key)`: \($0.value)" }.sorted().joined(separator: "\n")
                lines.append("- **Headers:**\n\(headerLines)")
            }
            if !responseBody.isEmpty {
                lines.append("- **Response:**\n```\n\(String(responseBody))\n```")
            }
            return lines.joined(separator: "\n")
        }
    }

    func performRequest(url: URL, method: String = "GET") async -> RequestOutcome {
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
            let sensitiveHeaders: Set<String> = ["set-cookie", "cookie", "authorization"]
            let headers = Dictionary(uniqueKeysWithValues:
                httpResponse.allHeaderFields.compactMap { key, value -> (String, String)? in
                    let name = String(describing: key)
                    guard !sensitiveHeaders.contains(name.lowercased()) else { return nil }
                    return (name, String(describing: value))
                }
            )
            let detail = RequestDetail(url: url.absoluteString,
                                       timeTaken: Date().timeIntervalSince(startTime),
                                       statusCode: httpResponse.statusCode,
                                       headers: headers,
                                       responseBody: body)
            return .success(RequestResult(data: data, statusCode: httpResponse.statusCode, detail: detail))
        } catch {
            let detail = RequestDetail(url: url.absoluteString,
                                       timeTaken: Date().timeIntervalSince(startTime),
                                       statusCode: nil,
                                       headers: [:],
                                       responseBody: String(describing: error))
            return .failure(detail)
        }
    }
}

// MARK: - ConnectivityTest Card Properties
//
extension PreLoginConnectivityToolViewModel.ConnectivityTest {

    var title: String {
        switch self {
        case .siteInfo: Localization.siteInfo
        case .apiDiscovery: Localization.apiDiscovery
        case .wordPressRESTAPI: Localization.wordPressRESTAPI
        case .wooCommerceAPI: Localization.wooCommerceAPI
        case .applicationPasswords: Localization.applicationPasswords
        }
    }

    private enum Localization {
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
    enum Localization {
        enum ErrorMessage {
            static let siteInfoFailed = NSLocalizedString(
                "preLoginConnectivityTool.error.siteInfoFailed",
                value: "Could not retrieve site information.",
                comment: "Error message when site info lookup fails in the pre-login connectivity tool"
            )
            static let apiDiscoveryFailed = NSLocalizedString(
                "preLoginConnectivityTool.error.apiDiscoveryFailed",
                value: "REST API endpoint not found.",
                comment: "Error message when REST API discovery fails in the pre-login connectivity tool"
            )
            static let noRESTAPI = NSLocalizedString(
                "preLoginConnectivityTool.error.noRESTAPI",
                value: "WordPress REST API is not accessible on your site.",
                comment: "Error message when REST API is unavailable in the pre-login connectivity tool"
            )
            static let noWooCommerce = NSLocalizedString(
                "preLoginConnectivityTool.error.noWooCommerce",
                value: "WooCommerce API is not accessible on your site.",
                comment: "Error message when WooCommerce is not active in the pre-login connectivity tool"
            )
            static let applicationPasswordsDisabled = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsDisabled",
                value: "Application Passwords are disabled.",
                comment: "Error message when application passwords are disabled in the pre-login connectivity tool"
            )
            static let applicationPasswordsUnavailable = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsUnavailable",
                value: "Application Passwords not available.",
                comment: "Error message when application passwords are not available in the pre-login connectivity tool"
            )
        }

        enum SuccessInfo {
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
                "preLoginConnectivityTool.success.applicationPasswordsLikelyAvailable",
                value: "Application Passwords appear to be supported.",
                comment: "Success info when application passwords are likely available in the pre-login connectivity tool"
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
}
