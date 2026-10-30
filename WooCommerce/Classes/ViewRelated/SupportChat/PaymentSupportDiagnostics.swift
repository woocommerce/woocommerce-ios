import Foundation
import Yosemite
import class WooFoundation.VersionHelpers
import enum Alamofire.AFError
import enum NetworkingCore.DotcomError
import enum NetworkingCore.WordPressApiError

/// Reads fresh store data without the stored-account writes that `CardPresentPaymentsOnboardingUseCase` makes.
@MainActor
struct PaymentSupportDiagnostics {
    let siteID: Int64
    let stores: StoresManager

    func run() async -> SupportDiagnosticsService.Result {
        var stage = "system_status"
        do {
            let report: Yosemite.SystemStatusReport = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(SystemStatusAction.fetchSystemStatusReport(siteID: siteID, detectUnexpectedResponses: true) {
                    continuation.resume(with: $0)
                })
            }
            let active = CardPresentPaymentsPlugin.allCases.filter { gateway in
                report.activePlugins.contains { Plugin(systemPlugin: $0) == gateway.plugin }
            }
            stage = "settings/general"
            let settings: [SiteSetting] = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(SettingAction.retrieveGeneralSiteSettings(siteID: siteID) {
                    continuation.resume(with: $0)
                })
            }
            let address = SiteAddress(siteSettings: settings)
            let country = address.countryCode
            let countrySetting = settings.first(where: { $0.settingID == "woocommerce_default_country" })?.value ?? ""
            guard !countrySetting.isEmpty else {
                return failure(Localization.missingCountry, detail: "missing_country", action: .openStoreSettings)
            }
            guard let currency = settings.first(where: { $0.settingID == "woocommerce_currency" })?.value, !currency.isEmpty else {
                return failure(Localization.missingCurrency, detail: "missing_currency", action: .openStoreSettings)
            }
            let configuration = CardPresentPaymentsConfiguration(country: country)
            guard country != .unknown, configuration.isSupportedCountry else {
                return failure(Localization.unsupportedCountry, detail: "country_not_supported", action: .openStoreSettings)
            }
            guard !active.isEmpty else {
                let hasInactiveProvider = report.inactivePlugins.contains { plugin in
                    CardPresentPaymentsPlugin.allCases.contains {
                        configuration.paymentGateways.contains($0.gatewayID) && Plugin(systemPlugin: plugin) == $0.plugin
                    }
                }
                return failure(hasInactiveProvider ? Localization.inactivePlugin : Localization.noActivePlugin,
                               detail: hasInactiveProvider ? "payment_plugin_inactive" : "no_active_payment_plugin",
                               action: .openPlugins)
            }

            // AppSettingsStore reads local settings and calls back before `dispatch` returns.
            var preferred: CardPresentPaymentsPlugin?
            stores.dispatch(AppSettingsAction.getPreferredInPersonPaymentGateway(siteID: siteID) {
                preferred = $0.flatMap(CardPresentPaymentsPlugin.with(gatewayID:))
            })
            let gateway: CardPresentPaymentsPlugin
            if active.count == 1, let only = active.first {
                gateway = only
            } else if !configuration.paymentGateways.contains(CardPresentPaymentsPlugin.stripe.gatewayID) {
                gateway = .wcPay
            } else if let preferred {
                gateway = preferred
            } else {
                return failure(Localization.chooseGateway, detail: "payment_gateway_selection_required", action: .retryDiagnostics)
            }
            guard let support = configuration.supportedPluginVersions.first(where: { $0.plugin == gateway }),
                  configuration.paymentGateways.contains(gateway.gatewayID) else {
                return failure(Localization.unsupportedGateway, detail: "gateway_not_supported_in_country", action: .openPlugins)
            }
            guard let plugin = report.activePlugins.first(where: { Plugin(systemPlugin: $0) == gateway.plugin }),
                  VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: support.minimumVersion) else {
                return failure(Localization.oldPlugin, detail: "payment_plugin_version_unsupported", action: .openPlugins)
            }
            guard configuration.currencies.contains(where: { $0.rawValue.caseInsensitiveCompare(currency) == .orderedSame }) else {
                return failure(Localization.unsupportedCurrency, detail: "store_currency_not_supported")
            }

            stage = gateway.gatewayID + "/accounts"
            let account: PaymentGatewayAccount = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(CardPresentPaymentAction.fetchPaymentGatewayAccount(siteID: siteID, gateway: gateway) {
                    continuation.resume(with: $0)
                })
            }
            let result = evaluate(account: account, gateway: gateway, currency: currency, country: country.rawValue)
            // Both payment plugins need these fields to find or create the card reader location.
            guard !result.isSuccess || [address.address, address.city, address.postalCode].allSatisfy({ !$0.isEmpty }) else {
                return failure(Localization.incompleteAddress, detail: "store_address_incomplete", action: .openStoreSettings)
            }
            return result
        } catch {
            return requestFailure(error, stage: stage)
        }
    }

    func evaluate(account: PaymentGatewayAccount,
                  gateway: CardPresentPaymentsPlugin,
                  currency: String,
                  country: String) -> SupportDiagnosticsService.Result {
        let status = WCPayAccountStatusEnum(rawValue: account.status)
        let openProvider = SupportDiagnosticsService.Action.openPaymentProvider(gateway)
        if status == .noAccount {
            return failure(Localization.setupIncomplete, detail: "account_setup_incomplete", action: openProvider)
        }
        // Matches onboarding: test mode blocks only a live account.
        if account.isInTestMode && account.isLive {
            return failure(Localization.testMode, detail: "payment_gateway_in_test_mode", action: openProvider)
        }
        // Terminal location APIs normalize Puerto Rico to the US account country.
        let accountCountry = account.country.uppercased()
        let storeCountry = country.uppercased()
        guard accountCountry == storeCountry || (storeCountry == "PR" && accountCountry == "US") else {
            return failure(Localization.countryMismatch, detail: "account_country_mismatch")
        }
        switch status {
        case .complete, .enabled, .pendingVerification, .restrictedSoon:
            break
        case .restricted where account.hasPendingRequirements && !account.hasOverdueRequirements:
            break
        case .restricted where !account.hasOverdueRequirements:
            return failure(Localization.accountUnderReview, detail: "account_under_review")
        case .restricted:
            return failure(Localization.overdueRequirements, detail: "account_overdue_requirements", action: openProvider)
        case .rejectedFraud, .rejectedListed, .rejectedTermsOfService, .rejectedOther:
            return failure(Localization.rejectedAccount, detail: "account_rejected")
        case .noAccount, .unknown:
            return failure(Localization.unknownAccount, detail: "account_status_unknown", action: openProvider)
        }
        // Stripe's flag also reflects disabled charges, so only WooPayments continues without a live account.
        guard account.isLive || gateway == .wcPay else {
            return failure(Localization.accountNotLive, detail: "live_account_unavailable", action: .retryDiagnostics)
        }
        // Older account responses can omit supported currencies.
        if !account.supportedCurrencies.isEmpty,
           !account.supportedCurrencies.contains(where: { $0.caseInsensitiveCompare(currency) == .orderedSame }) {
            return failure(Localization.accountCurrency, detail: "account_currency_not_supported")
        }
        let hasPendingRequirements = account.hasPendingRequirements || status == .restrictedSoon
        let notLive: (finding: Finding, detail: String)? = account.isLive ? nil :
            (account.isInTestMode ? (Localization.testModeOnly, "account_in_test_mode") : (Localization.wooPaymentsNotLive, "account_not_live"))
        return .init(test: .paymentConfiguration,
                     isSuccess: true,
                     errorMessage: notLive?.finding.message,
                     technicalDetails: evidence((notLive?.detail ?? "configuration_checks_passed") +
                        "; gateway=\(gateway.gatewayID)." +
                        " Reader, location, network stability, payment collection and capture were not tested."),
                     suggestedAction: notLive != nil || hasPendingRequirements ? openProvider : nil,
                     advisoryMessage: hasPendingRequirements ? Localization.pendingRequirements : nil,
                     isInconclusive: notLive != nil,
                     headline: notLive?.finding.headline)
    }

    func requestFailure(_ error: Error, stage: String) -> SupportDiagnosticsService.Result {
        let code = (error as? UnexpectedStoreResponseError)?.statusCode ??
            (error as? NetworkRequestError)?.responseCode ?? (error as? AFError)?.responseCode
        let status = code.map { "; http_status=\($0)" } ?? ""
        let reason: String
        let finding: Finding
        let isTunnelTimeout: Bool
        if let connectionError = error as? DotcomError, case let .requestFailed(message, _) = connectionError {
            isTunnelTimeout = message?.localizedCaseInsensitiveContains("cURL error 28:") == true
        } else {
            isTunnelTimeout = false
        }
        // The internet check runs first, so a timeout here points to a slow store.
        if error.isTimeoutError || code == 408 || isTunnelTimeout {
            (reason, finding) = ("request_timeout", Localization.siteError)
        } else if let code, (500...599).contains(code) {
            (reason, finding) = ("server_error" + status, Localization.siteError)
        } else if isAccessDenied(error) {
            (reason, finding) = ("access_denied" + status, Localization.accessDenied)
        } else if code == 401 || code == 403 {
            (reason, finding) = ("request_blocked" + status, Localization.blocked)
        } else if error is DecodingError || (error as? UnexpectedStoreResponseError)?.kind == .unexpectedContent {
            (reason, finding) = ("invalid_response", Localization.siteError)
        } else {
            (reason, finding) = ("request_failed" + status, Localization.requestFailed)
        }
        // WordPress.com hosts these stores, so support can check the site instead of a hosting provider.
        let isSiteProblem = [Localization.siteError, Localization.blocked].contains(finding)
        let shownFinding = isSiteProblem && stores.sessionManager.defaultSite?.isWordPressComStore == true ?
            Finding(headline: finding.headline, message: Localization.hostedSiteMessage) : finding
        // Do not attach response bodies, account IDs, statement descriptors, or raw error descriptions.
        return failure(shownFinding, detail: "stage=\(stage); \(reason)", action: .retryDiagnostics)
    }

    /// WordPress refused the login or its permissions. Other 401 and 403 replies usually come from a firewall or security plugin.
    private func isAccessDenied(_ error: Error) -> Bool {
        let deniedCodes = ["rest_forbidden", "rest_not_logged_in", "woocommerce_rest_cannot_view", "rest_forbidden_context"]
        if let networkError = error as? NetworkRequestError, let code = networkError.errorCode {
            return deniedCodes.contains(code)
        }
        if let apiError = error as? WordPressApiError, case let .unknown(code, _) = apiError {
            return deniedCodes.contains(code)
        }
        guard let connectionError = error as? DotcomError else { return false }
        switch connectionError {
        case .unauthorized, .invalidToken:
            return true
        case .unknown(let code, _, _):
            return deniedCodes.contains(code)
        default:
            return false
        }
    }

    private func failure(_ finding: Finding,
                         detail: String,
                         action: SupportDiagnosticsService.Action? = nil) -> SupportDiagnosticsService.Result {
        .failure(test: .paymentConfiguration,
                 failure: .init(errorMessage: finding.message,
                                technicalDetails: evidence(detail),
                                suggestedAction: action,
                                headline: finding.headline))
    }
    private func evidence(_ detail: String) -> String {
        "checked_at=\(ISO8601DateFormatter().string(from: Date())); \(detail)"
    }
}

extension PaymentSupportDiagnostics {
    struct Finding: Equatable {
        let headline: String
        let message: String
    }

    enum Localization {
        static let title = NSLocalizedString(
            "paymentSupportDiagnostics.title",
            value: "Checking your store's payment setup",
            comment: "Progress step in support chat while the app checks the store's payment setup for card readers and Tap to Pay"
        )
        static let hostedSiteMessage = NSLocalizedString(
            "paymentSupportDiagnostics.hostedSite.message",
            value: "Your payment setup is unknown. Continue to chat so we can check your site.",
            comment: "Payment setup check result when a store hosted on WordPress.com blocks, fails or times out a request"
        )
        static let pendingRequirements = NSLocalizedString(
            "paymentSupportDiagnostics.pendingRequirements.note",
            value: "Your payment account has requirements due. Submit them before the deadline to avoid paused payouts.",
            comment: "Note on a payment setup check result when the payment account has pending requirements"
        )
        static let noActivePlugin = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.noActivePlugin.headline",
                value: "No payment plugin is active",
                comment: "Headline of the payment setup check result when neither WooPayments nor Stripe is active for the store country"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.noActivePlugin.message",
                value: "Install and activate WooPayments, then finish its setup.",
                comment: "Payment setup check result when neither WooPayments nor Stripe is active for the store country"
            )
        )
        static let inactivePlugin = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.inactivePlugin.headline",
                value: "Payment plugin is not active",
                comment: "Headline of the payment setup check result when a supported payment plugin is installed but not active"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.inactivePlugin.message",
                value: "Activate the payment plugin, then finish its setup.",
                comment: "Payment setup check result when a supported payment plugin is installed but not active"
            )
        )
        static let missingCountry = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.missingCountry.headline",
                value: "Store country is not set",
                comment: "Headline of the payment setup check result when the store country is empty"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.missingCountry.message",
                value: "Set your store country in your store settings.",
                comment: "Payment setup check result when the store country is empty"
            )
        )
        static let missingCurrency = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.missingCurrency.headline",
                value: "Store currency is not set",
                comment: "Headline of the payment setup check result when the store currency is empty"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.missingCurrency.message",
                value: "Set your store currency in your store settings.",
                comment: "Payment setup check result when the store currency is empty"
            )
        )
        static let unsupportedCountry = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.unsupportedCountry.headline",
                value: "Country not supported",
                comment: "Headline of the payment setup check result when the store country does not support card reader payments"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.unsupportedCountry.message",
                value: "In-person card payments are not available in your store country. If your store address shows the " +
                "wrong country, correct it. You can still take cash payments in the app.",
                comment: "Payment setup check result when the store country does not support card reader payments"
            )
        )
        static let chooseGateway = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.chooseGateway.headline",
                value: "Choose a payment provider",
                comment: "Headline of the payment setup check result when WooPayments and Stripe are both active and no provider is chosen in the app"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.chooseGateway.message",
                value: "WooPayments and Stripe are both active. In the app, go to Menu > Payments, tap Continue setup, and " +
                "choose a provider. You do not need to deactivate either plugin.",
                comment: "Payment setup check result when WooPayments and Stripe are both active and no provider is chosen in the app"
            )
        )
        static let unsupportedGateway = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.unsupportedGateway.headline",
                value: "Provider not available in your country",
                comment: "Headline of the payment setup check result when the chosen payment provider does not support card reader payments in the store country"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.unsupportedGateway.message",
                value: "Your payment plugin does not support in-person payments in your store country. Install and activate " +
                "WooPayments, then go to Menu > Payments and tap Continue setup.",
                comment: "Payment setup check result when the chosen payment provider does not support card reader payments in the store country"
            )
        )
        static let oldPlugin = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.oldPlugin.headline",
                value: "Payment plugin needs an update",
                comment: "Headline of the payment setup check result when the payment plugin version is too old for card reader payments"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.oldPlugin.message",
                value: "This version is too old for in-person payments. Update the plugin.",
                comment: "Payment setup check result when the payment plugin version is too old for card reader payments"
            )
        )
        static let unsupportedCurrency = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.unsupportedCurrency.headline",
                value: "Currency not supported",
                comment: "Headline of the payment setup check result when the store currency is not supported for card reader payments in the store country"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.unsupportedCurrency.message",
                value: "In-person payments do not support your store currency in this country. Changing the currency does " +
                "not convert your product prices, so continue to chat before you change it.",
                comment: "Payment setup check result when the store currency is not supported for card reader payments in the store country"
            )
        )
        static let incompleteAddress = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.incompleteAddress.headline",
                value: "Store address is incomplete",
                comment: "Headline of the payment setup check result when the store address is missing the street address, city or postcode"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.incompleteAddress.message",
                value: "Card readers and Tap to Pay need a street address, city and postcode. Add them in your store settings.",
                comment: "Payment setup check result when the store address is missing the street address, city or postcode"
            )
        )
        static let setupIncomplete = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.setupIncomplete.headline",
                value: "No payment account connected",
                comment: "Headline of the payment setup check result when the payment provider reports no account for the store"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.setupIncomplete.message",
                value: "Your store is not connected to a payment account. Finish the account setup in your store admin.",
                comment: "Payment setup check result when the payment provider reports no account for the store"
            )
        )
        static let testMode = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.testMode.headline",
                value: "Test mode is on",
                comment: "Headline of the payment setup check result when a live payment account is in test mode"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.testMode.message",
                value: "Your payment plugin is in test mode, so real card payments will not work. Turn off test mode in its " +
                "settings. If this is a staging copy of your store, take payments from your live store.",
                comment: "Payment setup check result when a live payment account is in test mode"
            )
        )
        static let testModeOnly = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.testModeOnly.headline",
                value: "Using a test account",
                comment: "Headline of the payment setup check result when the store uses a WooPayments test account that is not live"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.testModeOnly.message",
                value: "Your store uses a WooPayments test account, so real card payments will not work. To take them, set " +
                "up a live account in WooPayments. On a staging site, use your live store instead.",
                comment: "Payment setup check result when the store uses a WooPayments test account that is not live"
            )
        )
        static let wooPaymentsNotLive = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.wooPaymentsNotLive.headline",
                value: "WooPayments account is not live",
                comment: "Headline of the payment setup check result when the WooPayments account is not live and not in test mode"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.wooPaymentsNotLive.message",
                value: "Real card payments will not work until the account is live. Check the account status in WooPayments.",
                comment: "Payment setup check result when the WooPayments account is not live and not in test mode"
            )
        )
        static let accountNotLive = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.accountNotLive.headline",
                value: "Stripe account is not live",
                comment: "Headline of the payment setup check result when the Stripe account is not live or cannot accept charges"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.accountNotLive.message",
                value: "Stripe does not show your account as able to take live card payments. Finish the account setup in " +
                "your Stripe Dashboard, then tap Retry.",
                comment: "Payment setup check result when the Stripe account is not live or cannot accept charges"
            )
        )
        static let countryMismatch = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.countryMismatch.headline",
                value: "Account country does not match",
                comment: "Headline of the payment setup check result when the payment account country does not match the store country"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.countryMismatch.message",
                value: "Check that your store address is correct. Your payment account country cannot be changed, so " +
                "continue to chat before you change other settings.",
                comment: "Payment setup check result when the payment account country does not match the store country"
            )
        )
        static let overdueRequirements = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.overdueRequirements.headline",
                value: "Account has overdue requirements",
                comment: "Headline of the payment setup check result when the payment account is restricted with overdue requirements"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.overdueRequirements.message",
                value: "Payouts or payments can be paused until you submit the requested details. Submit them in your " +
                "payment account settings.",
                comment: "Payment setup check result when the payment account is restricted with overdue requirements"
            )
        )
        static let accountUnderReview = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.accountUnderReview.headline",
                value: "Account may be under review",
                comment: "Headline of the payment setup check result when the payment account is restricted without pending or overdue requirements"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.accountUnderReview.message",
                value: "There is nothing for you to submit now. Continue to chat if you need help with the account review.",
                comment: "Payment setup check result when the payment account is restricted without pending or overdue requirements"
            )
        )
        static let rejectedAccount = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.rejectedAccount.headline",
                value: "Payment account was rejected",
                comment: "Headline of the payment setup check result when the payment provider rejected the account"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.rejectedAccount.message",
                value: "In-person payments are not available with this payment account. Continue to chat to learn about your " +
                "options. You can still take cash payments in the app.",
                comment: "Payment setup check result when the payment provider rejected the account"
            )
        )
        static let unknownAccount = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.unknownAccount.headline",
                value: "Account status is unknown",
                comment: "Headline of the payment setup check result when the payment account status is unknown"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.unknownAccount.message",
                value: "The app could not read your payment account status. Continue to chat for help before you change the account.",
                comment: "Payment setup check result when the payment account status is unknown"
            )
        )
        static let accountCurrency = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.accountCurrency.headline",
                value: "Account does not support currency",
                comment: "Headline of the payment setup check result when the payment account does not support the store currency"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.accountCurrency.message",
                value: "Your payment account cannot take payments in your store currency. Changing the store currency does " +
                "not convert your product prices, so continue to chat before you change it.",
                comment: "Payment setup check result when the payment account does not support the store currency"
            )
        )
        static let accessDenied = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.accessDenied.headline",
                value: "Payment settings access denied",
                comment: "Headline of the payment setup check result when WordPress refuses the request because of the login or its permissions"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.accessDenied.message",
                value: "Your store did not let this login read the payment settings. Log in again with an administrator or " +
                "shop manager account, then tap Retry.",
                comment: "Payment setup check result when WordPress refuses the request because of the login or its permissions"
            )
        )
        static let blocked = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.blocked.headline",
                value: "Setup check was blocked",
                comment: "Headline of the payment setup check result when the store blocks a request with HTTP 401 or 403 without a WordPress error code"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.blocked.message",
                value: "Your payment setup is unknown. A security plugin or a firewall on your site usually causes this. " +
                "Allow requests from the WooCommerce app in that plugin, or ask your hosting provider to allow them. " +
                "You do not need to turn the plugin off.",
                comment: "Payment setup check result when the store blocks a request with HTTP 401 or 403 without a WordPress error code"
            )
        )
        static let siteError = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.siteError.headline",
                value: "Store did not respond correctly",
                comment: "Headline of the payment setup check result when the store times out, fails, or sends an unreadable reply"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.siteError.message",
                value: "Your payment setup is unknown. Ask your hosting provider to check the server error logs.",
                comment: "Payment setup check result when the store times out, fails, or sends an unreadable reply"
            )
        )
        static let requestFailed = Finding(
            headline: NSLocalizedString(
                "paymentSupportDiagnostics.requestFailed.headline",
                value: "Could not check payment setup",
                comment: "Headline of the payment setup check result when a request to the store fails for another reason"
            ),
            message: NSLocalizedString(
                "paymentSupportDiagnostics.requestFailed.message",
                value: "Your payment setup is unknown. Check your internet connection, then tap Retry.",
                comment: "Payment setup check result when a request to the store fails for another reason"
            )
        )
    }
}
