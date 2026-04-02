import Foundation
import struct NetworkingCore.WordPressAPIDiscovery
import class WordPressAuthenticator.WordPressComSiteInfo

/// Individual test implementations for the pre-login connectivity tool.
///
extension PreLoginConnectivityToolViewModel {

    enum Endpoint {
        static let siteInfoBase = "https://public-api.wordpress.com/rest/v1.1/connect/site-info/?url="
        static let wooCommerceAPI = "wc/v3"
        static let applicationPasswords = "wp/v2/users/me/application-passwords"
        static let loginPage = "wp-login.php"
    }

    // MARK: - Test 1: Internet Connectivity

    func testInternetConnectivity() -> PreLoginCheckState {
        let status = connectivityObserver.currentStatus
        if case .reachable = status {
            return .success(summary: Localization.SuccessInfo.internetConnected,
                            detail: PreLoginCheckDetail.local("Status: reachable"))
        }
        return .error(summary: Localization.ErrorMessage.noInternet,
                      detail: PreLoginCheckDetail.local("Status: \(status)"))
    }

    // MARK: - Test 2: Site Info

    func testSiteInfo() async -> PreLoginCheckState {
        let siteInfoURLString = Endpoint.siteInfoBase + siteURL.absoluteString
        guard let url = URL(string: siteInfoURLString) else {
            return .error(summary: Localization.ErrorMessage.siteInfoFailed,
                          detail: PreLoginCheckDetail.local("Invalid URL: \(siteInfoURLString)"))
        }

        let startTime = Date()
        do {
            let (data, response, body) = try await makeRequest(url: url)
            let headers = response.allHeaderFields as? [String: String] ?? [:]
            let detail = PreLoginCheckDetail(url: url.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: response.statusCode,
                                             headers: headers,
                                             responseBody: body)

            guard (200...299).contains(response.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any] else {
                return .error(summary: Localization.ErrorMessage.siteInfoFailed, detail: detail.formatted)
            }

            let info = WordPressComSiteInfo(remote: json)
            let summary = formatSiteInfoSummary(info)
            return .success(summary: summary, detail: detail.formatted)
        } catch {
            let detail = PreLoginCheckDetail(url: url.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: nil,
                                             headers: [:],
                                             responseBody: String(describing: error))
            return .error(summary: Localization.ErrorMessage.siteInfoFailed, detail: detail.formatted)
        }
    }

    // MARK: - Test 3: API Discovery

    func testAPIDiscovery() async -> PreLoginCheckState {
        let discovery = WordPressAPIDiscovery(session: session)
        let startTime = Date()
        let rootURLString = await discovery.discoverRESTAPIRootURL(for: siteURL.absoluteString)
        let timeTaken = Date().timeIntervalSince(startTime)

        if let rootURLString, let rootURL = URL(string: rootURLString) {
            restAPIRootURL = rootURL
            return .success(summary: Localization.SuccessInfo.apiDiscovered,
                            detail: PreLoginCheckDetail.local("API root: \(rootURLString)\nTime: \(String(format: "%.0fms", timeTaken * 1000))"))
        }

        return .error(summary: Localization.ErrorMessage.apiDiscoveryFailed,
                      detail: PreLoginCheckDetail.local("Site: \(siteURL.absoluteString)\nTime: \(String(format: "%.0fms", timeTaken * 1000))"))
    }

    // MARK: - Test 4: WordPress REST API

    func testWordPressRESTAPI() async -> PreLoginCheckState {
        guard let apiRoot = restAPIRootURL else {
            return .error(summary: Localization.ErrorMessage.noRESTAPI,
                          detail: PreLoginCheckDetail.local("No API root URL available from discovery"))
        }

        let startTime = Date()
        do {
            let (data, response, body) = try await makeRequest(url: apiRoot)
            let headers = response.allHeaderFields as? [String: String] ?? [:]
            let detail = PreLoginCheckDetail(url: apiRoot.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: response.statusCode,
                                             headers: headers,
                                             responseBody: body)

            guard (200...299).contains(response.statusCode) else {
                return .error(summary: Localization.ErrorMessage.noRESTAPI, detail: detail.formatted)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["namespaces"] != nil || json["name"] != nil {
                return .success(summary: Localization.SuccessInfo.restAPIAvailable, detail: detail.formatted)
            }

            return .error(summary: Localization.ErrorMessage.noRESTAPI, detail: detail.formatted)
        } catch {
            let detail = PreLoginCheckDetail(url: apiRoot.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: nil,
                                             headers: [:],
                                             responseBody: String(describing: error))
            return .error(summary: Localization.ErrorMessage.noRESTAPI, detail: detail.formatted)
        }
    }

    // MARK: - Test 5: WooCommerce API

    func testWooCommerceAPI() async -> PreLoginCheckState {
        guard let apiRoot = restAPIRootURL else {
            return .error(summary: Localization.ErrorMessage.noWooCommerce,
                          detail: PreLoginCheckDetail.local("No API root URL available from discovery"))
        }

        let wcURL = apiRoot.appending(path: Endpoint.wooCommerceAPI)
        let startTime = Date()
        do {
            let (data, response, body) = try await makeRequest(url: wcURL)
            let headers = response.allHeaderFields as? [String: String] ?? [:]
            let detail = PreLoginCheckDetail(url: wcURL.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: response.statusCode,
                                             headers: headers,
                                             responseBody: body)

            guard (200...299).contains(response.statusCode) else {
                return .error(summary: Localization.ErrorMessage.noWooCommerce, detail: detail.formatted)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let namespace = json["namespace"] as? String, namespace.contains("wc") {
                    return .success(summary: Localization.SuccessInfo.wooCommerceActive, detail: detail.formatted)
                }
                if let routes = json["routes"] as? [String: Any],
                   routes.keys.contains(where: { $0.contains("/wc/") }) {
                    return .success(summary: Localization.SuccessInfo.wooCommerceActive, detail: detail.formatted)
                }
            }

            return .error(summary: Localization.ErrorMessage.noWooCommerce, detail: detail.formatted)
        } catch {
            let detail = PreLoginCheckDetail(url: wcURL.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: nil,
                                             headers: [:],
                                             responseBody: String(describing: error))
            return .error(summary: Localization.ErrorMessage.noWooCommerce, detail: detail.formatted)
        }
    }

    // MARK: - Test 6: Application Passwords

    func testApplicationPasswords() async -> PreLoginCheckState {
        guard let apiRoot = restAPIRootURL else {
            return .error(summary: Localization.ErrorMessage.applicationPasswordsUnavailable,
                          detail: PreLoginCheckDetail.local("No API root URL available from discovery"))
        }

        let appPasswordsURL = apiRoot.appending(path: Endpoint.applicationPasswords)
        let startTime = Date()
        do {
            let (data, response, body) = try await makeRequest(url: appPasswordsURL)
            let headers = response.allHeaderFields as? [String: String] ?? [:]
            let detail = PreLoginCheckDetail(url: appPasswordsURL.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: response.statusCode,
                                             headers: headers,
                                             responseBody: body)

            switch response.statusCode {
            case 401:
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = json["code"] as? String,
                   code == "application_passwords_disabled" {
                    return .error(summary: Localization.ErrorMessage.applicationPasswordsDisabled, detail: detail.formatted)
                }
                // 401 with standard challenge means the endpoint exists (auth required)
                return .success(summary: Localization.SuccessInfo.applicationPasswordsAvailable, detail: detail.formatted)

            case 200...299:
                return .success(summary: Localization.SuccessInfo.applicationPasswordsAvailable, detail: detail.formatted)

            default:
                return .error(summary: Localization.ErrorMessage.applicationPasswordsUnavailable, detail: detail.formatted)
            }
        } catch {
            let detail = PreLoginCheckDetail(url: appPasswordsURL.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: nil,
                                             headers: [:],
                                             responseBody: String(describing: error))
            return .error(summary: Localization.ErrorMessage.applicationPasswordsUnavailable, detail: detail.formatted)
        }
    }

    // MARK: - Test 7: Login Page Analysis

    func testLoginPage() async -> PreLoginCheckState {
        let loginURL = siteURL.appending(path: Endpoint.loginPage)
        let startTime = Date()
        do {
            let (_, response, body) = try await makeRequest(url: loginURL)
            let headers = response.allHeaderFields as? [String: String] ?? [:]
            let detail = PreLoginCheckDetail(url: loginURL.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: response.statusCode,
                                             headers: headers,
                                             responseBody: body)
            let issues = analyzeLoginPageHTML(body)

            if issues.isEmpty {
                return .success(summary: Localization.SuccessInfo.loginPageClean, detail: detail.formatted)
            }

            let summary = Localization.ErrorMessage.loginPageIssues + "\n\n" + issues.joined(separator: "\n")
            return .error(summary: summary, detail: detail.formatted)
        } catch {
            let detail = PreLoginCheckDetail(url: loginURL.absoluteString,
                                             timeTaken: Date().timeIntervalSince(startTime),
                                             statusCode: nil,
                                             headers: [:],
                                             responseBody: String(describing: error))
            // If we can't reach the login page, don't fail — it's informational
            return .success(summary: Localization.SuccessInfo.loginPageClean, detail: detail.formatted)
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

// MARK: - Login Page Analysis
//
private extension PreLoginConnectivityToolViewModel {

    /// Analyzes login page HTML for common issues that affect mobile authentication.
    ///
    func analyzeLoginPageHTML(_ html: String) -> [String] {
        let body = html.lowercased()
        var issues: [String] = []

        // CAPTCHA detection
        if body.contains("recaptcha") || body.contains("g-recaptcha") {
            issues.append(Localization.LoginPageIssue.recaptcha)
        }
        if body.contains("hcaptcha") || body.contains("h-captcha") {
            issues.append(Localization.LoginPageIssue.hcaptcha)
        }
        if body.contains("cf-turnstile") || body.contains("challenges.cloudflare.com/turnstile") {
            issues.append(Localization.LoginPageIssue.cloudflareTurnstile)
        }

        // 2FA detection
        if body.contains("two-factor") || body.contains("2fa") || body.contains("two_factor") {
            issues.append(Localization.LoginPageIssue.twoFactor)
        }

        // Social login detection
        if body.contains("social-login") || body.contains("sociallogin") || body.contains("oauth") {
            issues.append(Localization.LoginPageIssue.socialLogin)
        }

        // Custom login plugins
        if body.contains("user-registration-pro") || body.contains("user_registration") {
            issues.append(Localization.LoginPageIssue.userRegistrationPro)
        }
        if body.contains("theme-my-login") || body.contains("tml-login") {
            issues.append(Localization.LoginPageIssue.themeMyLogin)
        }

        return issues
    }

    enum Localization {
        enum LoginPageIssue {
            static let recaptcha = NSLocalizedString(
                "preLoginConnectivityTool.loginPageIssue.recaptcha",
                value: "reCAPTCHA detected on login page",
                comment: "Login page issue when reCAPTCHA is detected"
            )
            static let hcaptcha = NSLocalizedString(
                "preLoginConnectivityTool.loginPageIssue.hcaptcha",
                value: "hCaptcha detected on login page",
                comment: "Login page issue when hCaptcha is detected"
            )
            static let cloudflareTurnstile = NSLocalizedString(
                "preLoginConnectivityTool.loginPageIssue.cloudflareTurnstile",
                value: "Cloudflare Turnstile detected on login page",
                comment: "Login page issue when Cloudflare Turnstile is detected"
            )
            static let twoFactor = NSLocalizedString(
                "preLoginConnectivityTool.loginPageIssue.twoFactor",
                value: "Two-factor authentication plugin detected",
                comment: "Login page issue when a 2FA plugin is detected"
            )
            static let socialLogin = NSLocalizedString(
                "preLoginConnectivityTool.loginPageIssue.socialLogin",
                value: "Social login plugin detected",
                comment: "Login page issue when a social login plugin is detected"
            )
            static let userRegistrationPro = NSLocalizedString(
                "preLoginConnectivityTool.loginPageIssue.userRegistrationPro",
                value: "User Registration Pro plugin detected",
                comment: "Login page issue when User Registration Pro is detected"
            )
            static let themeMyLogin = NSLocalizedString(
                "preLoginConnectivityTool.loginPageIssue.themeMyLogin",
                value: "Theme My Login plugin detected",
                comment: "Login page issue when Theme My Login is detected"
            )
        }

        enum ErrorMessage {
            static let noInternet = NSLocalizedString(
                "preLoginConnectivityTool.error.noInternet",
                value: "It looks like you're not connected to the internet.\n\n" +
                "Ensure your Wi-Fi is turned on. If you're using mobile data, make sure it's enabled in your device settings.",
                comment: "Error message when there is no internet connection in the pre-login connectivity tool"
            )
            static let siteInfoFailed = NSLocalizedString(
                "preLoginConnectivityTool.error.siteInfoFailed",
                value: "Could not retrieve site information.\n\n" +
                "Please check the URL is correct and that your site is online.",
                comment: "Error message when site info lookup fails in the pre-login connectivity tool"
            )
            static let apiDiscoveryFailed = NSLocalizedString(
                "preLoginConnectivityTool.error.apiDiscoveryFailed",
                value: "Could not discover the REST API endpoint for your site.\n\n" +
                "The site may not have a WordPress REST API or it may be disabled.",
                comment: "Error message when REST API discovery fails in the pre-login connectivity tool"
            )
            static let noRESTAPI = NSLocalizedString(
                "preLoginConnectivityTool.error.noRESTAPI",
                value: "The WordPress REST API is not available on your site.\n\n" +
                "Ensure pretty permalinks are enabled, or contact your hosting provider.",
                comment: "Error message when REST API is unavailable in the pre-login connectivity tool"
            )
            static let noWooCommerce = NSLocalizedString(
                "preLoginConnectivityTool.error.noWooCommerce",
                value: "WooCommerce doesn't appear to be active on your site.\n\n" +
                "Make sure the WooCommerce plugin is installed and activated.",
                comment: "Error message when WooCommerce is not active in the pre-login connectivity tool"
            )
            static let applicationPasswordsDisabled = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsDisabled",
                value: "Application Passwords are disabled on your site.\n\n" +
                "This feature is required for the WooCommerce app. Please enable it or contact your hosting provider.",
                comment: "Error message when application passwords are disabled in the pre-login connectivity tool"
            )
            static let applicationPasswordsUnavailable = NSLocalizedString(
                "preLoginConnectivityTool.error.appPasswordsUnavailable",
                value: "Application Passwords are not available on your site.\n\n" +
                "This feature requires WordPress 5.6 or later. Please update WordPress.",
                comment: "Error message when application passwords are not available in the pre-login connectivity tool"
            )
            static let loginPageIssues = NSLocalizedString(
                "preLoginConnectivityTool.error.loginPageIssues",
                value: "Your login page has customizations that may affect app authentication.",
                comment: "Error message when login page issues are found in the pre-login connectivity tool"
            )
        }

        enum SuccessInfo {
            static let internetConnected = NSLocalizedString(
                "preLoginConnectivityTool.success.internetConnected",
                value: "Your device is connected to the internet.",
                comment: "Success info when internet connectivity check passes in the pre-login connectivity tool"
            )
            static let siteInfoRetrieved = NSLocalizedString(
                "preLoginConnectivityTool.success.siteInfoRetrieved",
                value: "Site information retrieved.",
                comment: "Success info when site info check passes in the pre-login connectivity tool"
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
            static let loginPageClean = NSLocalizedString(
                "preLoginConnectivityTool.success.loginPageClean",
                value: "No login page issues detected.",
                comment: "Success info when login page analysis finds no issues in the pre-login connectivity tool"
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
