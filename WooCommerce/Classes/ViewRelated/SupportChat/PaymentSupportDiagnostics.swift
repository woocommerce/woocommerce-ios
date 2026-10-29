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
            guard country != .unknown,
                  let currency = settings.first(where: { $0.settingID == "woocommerce_currency" })?.value,
                  !currency.isEmpty else {
                return failure(Localization.missingSettings, detail: "missing_country_or_currency")
            }
            let configuration = CardPresentPaymentsConfiguration(country: country)
            guard configuration.isSupportedCountry else {
                return failure(Localization.unsupportedCountry, detail: "country_not_supported")
            }
            guard !active.isEmpty else {
                let hasInactiveProvider = report.inactivePlugins.contains { plugin in
                    CardPresentPaymentsPlugin.allCases.contains {
                        configuration.paymentGateways.contains($0.gatewayID) && Plugin(systemPlugin: plugin) == $0.plugin
                    }
                }
                return failure(hasInactiveProvider ? Localization.inactivePlugin : Localization.noActivePlugin,
                               detail: hasInactiveProvider ? "payment_plugin_inactive" : "no_active_payment_plugin")
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
                return failure(Localization.chooseGateway, detail: "payment_gateway_selection_required")
            }
            guard let support = configuration.supportedPluginVersions.first(where: { $0.plugin == gateway }),
                  configuration.paymentGateways.contains(gateway.gatewayID) else {
                return failure(Localization.unsupportedGateway, detail: "gateway_not_supported_in_country")
            }
            guard let plugin = report.activePlugins.first(where: { Plugin(systemPlugin: $0) == gateway.plugin }),
                  VersionHelpers.isVersionSupported(version: plugin.version, minimumRequired: support.minimumVersion) else {
                return failure(Localization.oldPlugin, detail: "payment_plugin_version_unsupported")
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
                return failure(Localization.incompleteAddress, detail: "store_address_incomplete")
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
        if status == .noAccount {
            return failure(Localization.setupIncomplete, detail: "account_setup_incomplete")
        }
        // Matches onboarding: test mode blocks only a live account.
        if account.isInTestMode && account.isLive {
            return failure(Localization.testMode, detail: "payment_gateway_in_test_mode")
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
            return failure(Localization.overdueRequirements, detail: "account_overdue_requirements")
        case .rejectedFraud, .rejectedListed, .rejectedTermsOfService, .rejectedOther:
            return failure(Localization.rejectedAccount, detail: "account_rejected")
        case .noAccount, .unknown:
            return failure(Localization.unknownAccount, detail: "account_status_unknown")
        }
        // Stripe's flag also reflects disabled charges; older WooPayments summaries may omit it.
        guard account.isLive || gateway == .wcPay else {
            return failure(Localization.accountNotLive, detail: "live_account_unavailable")
        }
        // Older account responses can omit supported currencies.
        if !account.supportedCurrencies.isEmpty,
           !account.supportedCurrencies.contains(where: { $0.caseInsensitiveCompare(currency) == .orderedSame }) {
            return failure(Localization.accountCurrency, detail: "account_currency_not_supported")
        }
        let hasPendingRequirements = account.hasPendingRequirements || status == .restrictedSoon
        return .init(test: .paymentConfiguration,
                     isSuccess: true,
                     errorMessage: nil,
                     technicalDetails: evidence((account.isLive ? "configuration_checks_passed" : "configuration_checks_inconclusive") +
                        "; gateway=\(gateway.gatewayID)." +
                        " Reader, location, network stability, payment collection and capture were not tested."),
                     suggestedAction: nil,
                     advisoryMessage: hasPendingRequirements ? Localization.pendingRequirements : nil,
                     isInconclusive: !account.isLive)
    }

    func requestFailure(_ error: Error, stage: String) -> SupportDiagnosticsService.Result {
        let code = (error as? UnexpectedStoreResponseError)?.statusCode ??
            (error as? NetworkRequestError)?.responseCode ?? (error as? AFError)?.responseCode
        let reason: String
        let message: String
        let isTunnelTimeout: Bool
        if let connectionError = error as? DotcomError, case let .requestFailed(message, _) = connectionError {
            isTunnelTimeout = message?.localizedCaseInsensitiveContains("cURL error 28:") == true
        } else {
            isTunnelTimeout = false
        }
        if error.isTimeoutError || code == 408 || isTunnelTimeout {
            reason = "request_timeout"
            message = Localization.timeout
        } else if let code, (500...599).contains(code) {
            reason = "server_error; http_status=\(code)"
            message = Localization.serverError
        } else if code == 401 || code == 403 || isAccessDenied(error) {
            reason = "access_denied" + (code.map { "; http_status=\($0)" } ?? "")
            message = Localization.accessDenied
        } else if error is DecodingError || (error as? UnexpectedStoreResponseError)?.kind == .unexpectedContent {
            reason = "invalid_response"
            message = Localization.invalidResponse
        } else {
            reason = "request_failed" + (code.map { "; http_status=\($0)" } ?? "")
            message = Localization.requestFailed
        }
        // Do not attach response bodies, account IDs, statement descriptors, or raw error descriptions.
        return failure(message, detail: "stage=\(stage); \(reason)", retry: true)
    }

    private func isAccessDenied(_ error: Error) -> Bool {
        let deniedCodes = ["rest_forbidden", "rest_not_logged_in", "woocommerce_rest_cannot_view", "rest_forbidden_context"]
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

    private func failure(_ message: String, detail: String, retry: Bool = false) -> SupportDiagnosticsService.Result {
        .failure(test: .paymentConfiguration,
                 failure: .init(errorMessage: message,
                                technicalDetails: evidence(detail),
                                suggestedAction: retry ? .retryDiagnostics : nil))
    }

    private func evidence(_ detail: String) -> String {
        "checked_at=\(ISO8601DateFormatter().string(from: Date())); \(detail)"
    }
}

extension PaymentSupportDiagnostics {
    enum Localization {
        static let title = NSLocalizedString(
            "paymentSupportDiagnostics.title",
            value: "Checking your store's payment setup",
            comment: "Progress step in support chat while the app checks the store's payment setup for card readers and Tap to Pay"
        )
        static let noActivePlugin = NSLocalizedString(
            "paymentSupportDiagnostics.noActivePlugin",
            value: "No payment plugin that supports in-person payments is active. In your store admin, install and activate one " +
                "for your country, then finish its setup.",
            comment: "Payment setup check result when neither WooPayments nor Stripe is active for the store country"
        )
        static let inactivePlugin = NSLocalizedString(
            "paymentSupportDiagnostics.inactivePlugin",
            value: "A payment plugin is installed but not active. In your store admin, activate it and finish its setup.",
            comment: "Payment setup check result when WooPayments or Stripe is installed but not activated"
        )
        static let missingSettings = NSLocalizedString(
            "paymentSupportDiagnostics.missingSettings",
            value: "The app could not check your store country or currency. Check General settings in your store admin, " +
                "then run these checks again.",
            comment: "Payment setup check result when the store country or currency is empty"
        )
        static let unsupportedCountry = NSLocalizedString(
            "paymentSupportDiagnostics.unsupportedCountry",
            value: "The app does not support in-person payments in your store country. Check your store address in your store admin.",
            comment: "Payment setup check result when the store country does not support card reader payments in the app"
        )
        static let chooseGateway = NSLocalizedString(
            "paymentSupportDiagnostics.chooseGateway",
            value: "WooPayments and Stripe are both active. Choose one under Payment Provider in Payments settings, then run " +
                "these checks again. You do not need to deactivate either plugin.",
            comment: "Payment setup check result when both payment plugins are active and the merchant has not chosen one in the app"
        )
        static let unsupportedGateway = NSLocalizedString(
            "paymentSupportDiagnostics.unsupportedGateway",
            value: "Your payment provider does not support in-person payments in your store country. Check Payment Provider " +
                "in Payments settings.",
            comment: "Payment setup check result when the chosen payment provider does not support card readers in the store country"
        )
        static let oldPlugin = NSLocalizedString(
            "paymentSupportDiagnostics.oldPlugin",
            value: "Your payment plugin is too old for in-person payments. Update it in your store admin, then run these checks again.",
            comment: "Payment setup check result when the WooPayments or Stripe plugin version is below the app's minimum"
        )
        static let unsupportedCurrency = NSLocalizedString(
            "paymentSupportDiagnostics.unsupportedCurrency",
            value: "In-person payments do not support your store currency in this country. Check your store currency before " +
                "you change other settings.",
            comment: "Payment setup check result when the store currency is not supported for card reader payments in the store country"
        )
        static let incompleteAddress = NSLocalizedString(
            "paymentSupportDiagnostics.incompleteAddress",
            value: "Your store address is incomplete. Card readers and Tap to Pay need a street address, city and postcode. " +
                "Add them in General settings in your store admin.",
            comment: "Payment setup check result when the store address is missing the street address, city or postcode"
        )
        static let setupIncomplete = NSLocalizedString(
            "paymentSupportDiagnostics.setupIncomplete",
            value: "Your payment provider has not set up an account for this store. Finish setup in your store admin or " +
                "contact payment support.",
            comment: "Payment setup check result when the payment plugin reports no connected account"
        )
        static let testMode = NSLocalizedString(
            "paymentSupportDiagnostics.testMode",
            value: "Your payment provider is in test mode. Check its settings in your store admin before you take a live payment.",
            comment: "Payment setup check result when a live payment account is in test mode"
        )
        static let pendingRequirements = NSLocalizedString(
            "paymentSupportDiagnostics.pendingRequirements",
            value: "Your payment account has pending requirements. Payments may keep working until the deadline. Review them " +
                "in your payment provider dashboard.",
            comment: "Extra note under a passed payment setup check when the payment account has requirements that are due but not overdue"
        )
        static let accountNotLive = NSLocalizedString(
            "paymentSupportDiagnostics.accountNotLive",
            value: "Your payment provider does not report a live account that can accept charges. Check the account in your " +
                "payment provider dashboard or contact payment support.",
            comment: "Payment setup check result when the Stripe account is not live or cannot accept charges"
        )
        static let countryMismatch = NSLocalizedString(
            "paymentSupportDiagnostics.countryMismatch",
            value: "Your payment account country does not match your store country. Ask your payment provider before you " +
                "change the store address.",
            comment: "Payment setup check result when the payment account country differs from the store country"
        )
        static let overdueRequirements = NSLocalizedString(
            "paymentSupportDiagnostics.overdueRequirements",
            value: "Your payment account summary shows overdue requirements. Check them in your payment provider dashboard. " +
                "If none show there, ask support to compare. Some payments may be restricted.",
            comment: "Payment setup check result when the payment account is restricted because requirements are overdue"
        )
        static let accountUnderReview = NSLocalizedString(
            "paymentSupportDiagnostics.accountUnderReview",
            value: "Your payment account appears to be under review. Check its status with your payment provider. Your store's " +
                "account summary shows no pending or overdue requirements to submit.",
            comment: "Payment setup check result when the payment account is restricted but has no pending or overdue requirements"
        )
        static let rejectedAccount = NSLocalizedString(
            "paymentSupportDiagnostics.rejectedAccount",
            value: "Your payment provider has rejected the account. Contact payment support to review the account status.",
            comment: "Payment setup check result when the payment provider rejected the account"
        )
        static let unknownAccount = NSLocalizedString(
            "paymentSupportDiagnostics.unknownAccount",
            value: "The app could not confirm your payment account status. Contact support before you change the account.",
            comment: "Payment setup check result when the payment account status is not one the app knows"
        )
        static let accountCurrency = NSLocalizedString(
            "paymentSupportDiagnostics.accountCurrency",
            value: "Your payment account does not support your store currency. Check the currency settings with your payment provider.",
            comment: "Payment setup check result when the payment account does not list the store currency"
        )
        static let timeout = NSLocalizedString(
            "paymentSupportDiagnostics.timeout",
            value: "A store request timed out. This does not show a reader fault. Check your connection, then ask your host " +
                "to check the server logs.",
            comment: "Payment setup check result when a request to the store times out"
        )
        static let serverError = NSLocalizedString(
            "paymentSupportDiagnostics.serverError",
            value: "Your store returned a server error. A hosting or plugin problem can cause this. Ask your host or support " +
                "to check the error logs.",
            comment: "Payment setup check result when the store returns an HTTP 5xx error"
        )
        static let accessDenied = NSLocalizedString(
            "paymentSupportDiagnostics.accessDenied",
            value: "Your store blocked a setup check. A permission or security rule can cause this. It does not show that " +
                "payment setup is incomplete. Ask support to check.",
            comment: "Payment setup check result when the store denies a request with HTTP 401 or 403"
        )
        static let invalidResponse = NSLocalizedString(
            "paymentSupportDiagnostics.invalidResponse",
            value: "The app could not read a reply from your store, so your payment setup is unknown. Ask support to check it. " +
                "This does not show a reader fault.",
            comment: "Payment setup check result when the store returns data in an unexpected format"
        )
        static let requestFailed = NSLocalizedString(
            "paymentSupportDiagnostics.requestFailed",
            value: "A store request failed, so your payment setup is unknown. Check your connection and run the checks again, " +
                "or contact support.",
            comment: "Payment setup check result when a request to the store fails for another reason"
        )
    }
}
