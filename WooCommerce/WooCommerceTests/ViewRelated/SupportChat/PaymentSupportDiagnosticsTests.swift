import Foundation
import Testing
import Fakes
import Yosemite
import enum NetworkingCore.DotcomError
import enum NetworkingCore.WordPressApiError
@testable import WooCommerce

@Suite(.serialized, .timeLimit(.minutes(5)))
@MainActor
struct PaymentSupportDiagnosticsTests {
    @Test func test_payment_issue_when_selected_then_runs_read_only_store_and_device_checks() {
        // When
        let tests = SupportIssueType.inPersonPayments.testsToRun

        // Then
        #expect(tests == [.internetConnection, .paymentConfiguration, .paymentDevice])
    }

    @Test func test_run_when_no_active_gateway_then_does_not_load_accounts() async {
        // Given
        let sut = makeSUT(plugins: [])
        // When
        let result = await sut.run()
        // Then
        #expect(!result.isSuccess)
        #expect(result.technicalDetails?.contains("no_active_payment_plugin") == true)
    }

    @Test func test_run_when_country_unsupported_and_no_plugin_then_does_not_recommend_installing_provider() async {
        // Given
        let sut = makeSUT(plugins: [], country: "LT", currency: "EUR")
        // When
        let result = await sut.run()
        // Then
        #expect(result.technicalDetails?.contains("country_not_supported") == true)
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.unsupportedCountry.message)
        #expect(requestedGateways(sut).isEmpty)
    }

    @Test func test_run_when_provider_installed_but_inactive_then_recommends_activation() async {
        // Given
        let sut = makeSUT(plugins: [], inactivePlugins: [plugin(.wcPay).copy(active: false)])
        // When
        let result = await sut.run()
        // Then
        #expect(result.technicalDetails?.contains("payment_plugin_inactive") == true)
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.inactivePlugin.message)
        #expect(result.headline == PaymentSupportDiagnostics.Localization.inactivePlugin.headline)
        #expect(result.reason == "payment_plugin_inactive")
        #expect(result.suggestedAction == .openPlugins)
        #expect(requestedGateways(sut).isEmpty)
    }

    @Test(arguments: [CardPresentPaymentsPlugin.wcPay, .stripe])
    func test_evaluate_when_restricted_without_requirements_then_reports_apparent_review(gateway: CardPresentPaymentsPlugin) {
        // Given
        let sut = makeSUT()
        let account = account().copy(status: "restricted", hasPendingRequirements: false, hasOverdueRequirements: false, isLive: false)
        // When
        let result = sut.evaluate(account: account, gateway: gateway, currency: "USD", country: "US")
        // Then
        #expect(!result.isSuccess)
        #expect(result.technicalDetails?.contains("account_under_review") == true)
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.accountUnderReview.message)
        #expect(result.suggestedAction == nil)
    }

    @Test func test_run_when_settings_request_fails_then_reports_unknown_instead_of_incomplete_setup() async {
        // Given
        let sut = makeSUT(settingsError: NetworkRequestError.unacceptableStatusCode(statusCode: 503))
        // When
        let result = await sut.run()
        // Then
        #expect(!result.isSuccess)
        #expect(result.technicalDetails?.contains("stage=settings/general; server_error; http_status=503") == true)
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.siteError.message)
        #expect(result.suggestedAction == .retryDiagnostics)
    }

    @Test(arguments: [["", "San Francisco", "94110"], ["1 Main Street", "", "94110"], ["1 Main Street", "San Francisco", ""]])
    func test_run_when_store_address_incomplete_then_reports_address(storeAddress: [String]) async {
        // Given
        let sut = makeSUT(storeAddress: storeAddress)

        // When
        let result = await sut.run()

        // Then
        #expect(!result.isSuccess)
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.incompleteAddress.message)
        #expect(result.suggestedAction == .openStoreSettings)
        #expect(result.technicalDetails?.contains("store_address_incomplete") == true)
    }

    @Test func test_run_when_account_blocks_and_store_address_incomplete_then_reports_account_first() async {
        // Given
        let sut = makeSUT(account: account().copy(status: "NOACCOUNT"), storeAddress: ["", "", ""])

        // When
        let result = await sut.run()

        // Then
        #expect(result.technicalDetails?.contains("account_setup_incomplete") == true)
    }

    @Test func test_run_when_both_gateways_active_without_selection_then_asks_for_selection() async {
        // Given
        let sut = makeSUT(plugins: [plugin(.wcPay), plugin(.stripe)])
        // When
        let result = await sut.run()
        // Then
        #expect(result.technicalDetails?.contains("payment_gateway_selection_required") == true)
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.chooseGateway.message)
        #expect(result.suggestedAction == .retryDiagnostics)
    }

    @Test func test_run_when_selected_gateway_fails_then_other_gateway_does_not_mask_error() async {
        // Given
        let sut = makeSUT(plugins: [plugin(.wcPay), plugin(.stripe)], preferred: .stripe,
                          accountError: NetworkRequestError.unacceptableStatusCode(statusCode: 503))
        // When
        let result = await sut.run()
        // Then
        #expect(!result.isSuccess)
        #expect(requestedGateways(sut) == [.stripe])
        #expect(result.technicalDetails?.contains("stage=woocommerce-stripe/accounts; server_error; http_status=503") == true)
    }

    @Test func test_run_when_saved_gateway_inactive_then_checks_active_provider_used_by_app() async {
        // Given
        let sut = makeSUT(preferred: .stripe)
        // When
        let result = await sut.run()
        // Then
        #expect(result.isSuccess)
        #expect(requestedGateways(sut) == [.wcPay])
    }

    @Test(arguments: [("", "USD", "missing_country"),
                      ("ZZ", "USD", "country_not_supported"),
                      ("US", "", "missing_currency"),
                      ("LT", "EUR", "country_not_supported"),
                      ("US", "EUR", "store_currency_not_supported")])
    func test_run_when_store_settings_invalid_then_identifies_configuration_reason(country: String, currency: String, reason: String) async {
        // Given
        let sut = makeSUT(country: country, currency: currency)
        // When
        let result = await sut.run()
        // Then
        #expect(!result.isSuccess)
        #expect(result.technicalDetails?.contains(reason) == true)
    }

    @Test(arguments: [true, false])
    func test_run_when_test_mode_then_blocks_only_live_account(isLive: Bool) async {
        // Given
        let sut = makeSUT(account: account().copy(isLive: isLive, isInTestMode: true))
        // When
        let result = await sut.run()
        // Then
        #expect(result.technicalDetails?.contains("payment_gateway_in_test_mode") == isLive)
        #expect((result.errorMessage == PaymentSupportDiagnostics.Localization.testMode.message) == isLive)
        #expect(result.isInconclusive == !isLive)
        #expect(result.suggestedAction == .openPaymentProvider(.wcPay))
        if !isLive {
            #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.testPaymentsOnly.message)
            #expect(result.headline == PaymentSupportDiagnostics.Localization.testPaymentsOnly.headline)
            #expect(result.technicalDetails?.contains("account_in_test_mode") == true)
        }
    }

    @Test func test_run_when_response_changes_between_checks_then_uses_fresh_account() async {
        // Given
        let stores = stores()
        var attempt = 0
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .fetchPaymentGatewayAccount(_, _, let completion) = action {
                attempt += 1
                completion(.success(account().copy(isInTestMode: attempt == 2)))
            } else {
                Issue.record("Diagnostics must not change gateway selection, cache or reader state")
            }
        }
        let sut = PaymentSupportDiagnostics(siteID: 123, stores: stores)
        // When
        let first = await sut.run()
        let second = await sut.run()
        // Then
        #expect(first.isSuccess)
        #expect(!second.isSuccess)
        #expect(attempt == 2)
    }

    @Test(arguments: [("NOACCOUNT", "account_setup_incomplete"),
                      ("restricted", "account_under_review"),
                      ("rejected.fraud", "account_rejected"),
                      ("unrecognized", "account_status_unknown")])
    func test_evaluate_when_account_status_blocks_then_reports_specific_reason(status: String, reason: String) {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.evaluate(account: account().copy(status: status), gateway: .wcPay, currency: "USD", country: "US")
        // Then
        #expect(!result.isSuccess)
        #expect(result.technicalDetails?.contains(reason) == true)
    }

    @Test(arguments: ["restricted", "restricted_soon"])
    func test_evaluate_when_pending_requirements_then_does_not_claim_payments_are_blocked(status: String) {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.evaluate(account: account().copy(status: status, hasPendingRequirements: true),
                                  gateway: .wcPay, currency: "USD", country: "US")
        // Then
        #expect(result.isSuccess)
        #expect(result.advisoryMessage == PaymentSupportDiagnostics.Localization.pendingRequirements)
        #expect(result.suggestedAction == .openPaymentProvider(.wcPay))
        #expect(result.technicalDetails?.contains("capture were not tested") == true)
    }

    @Test func test_run_when_only_stripe_active_in_country_without_stripe_then_reports_provider_not_supported() async {
        // Given
        let sut = makeSUT(plugins: [plugin(.stripe)], country: "CA", currency: "CAD")
        // When
        let result = await sut.run()
        // Then
        #expect(result.headline == PaymentSupportDiagnostics.Localization.providerNotSupported.headline)
        #expect(result.technicalDetails?.contains("gateway_not_supported_in_country") == true)
        #expect(result.suggestedAction == .openPlugins)
        #expect(requestedGateways(sut).isEmpty)
    }

    @Test func test_evaluate_when_stripe_in_test_mode_then_warns_instead_of_failing() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.evaluate(account: account().copy(isLive: false, isInTestMode: true), gateway: .stripe, currency: "USD", country: "US")
        // Then
        #expect(result.isSuccess)
        #expect(result.isInconclusive)
        #expect(result.headline == PaymentSupportDiagnostics.Localization.testPaymentsOnly.headline)
        #expect(result.suggestedAction == .openPaymentProvider(.stripe))
    }

    @Test func test_evaluate_when_account_is_healthy_then_passes_without_action() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.evaluate(account: account(), gateway: .wcPay, currency: "USD", country: "US")
        // Then
        #expect(result.isSuccess)
        #expect(!result.isInconclusive)
        #expect(result.suggestedAction == nil)
    }

    @Test func test_evaluate_when_restricted_overdue_then_identifies_requirements() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.evaluate(account: account().copy(status: "restricted", hasOverdueRequirements: true),
                                  gateway: .wcPay, currency: "USD", country: "US")
        // Then
        #expect(result.technicalDetails?.contains("account_overdue_requirements") == true)
    }

    @Test(arguments: [CardPresentPaymentsPlugin.wcPay, .stripe])
    func test_evaluate_when_live_status_false_then_distinguishes_legacy_wcpay_from_disabled_stripe(gateway: CardPresentPaymentsPlugin) {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.evaluate(account: account().copy(isLive: false, isInTestMode: false),
                                  gateway: gateway, currency: "USD", country: "US")
        // Then
        #expect(result.isSuccess == (gateway == .wcPay))
        #expect(result.suggestedAction == (gateway == .wcPay ? .openPaymentProvider(gateway) : .retryDiagnostics))
        if gateway == .wcPay {
            #expect(result.isInconclusive)
            #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.accountNotLiveYet.message)
            #expect(result.technicalDetails?.contains("account_not_live") == true)
            #expect(result.advisoryMessage == nil)
            #expect(result.troubleshootingDescription().contains("Result: \(PaymentSupportDiagnostics.Localization.accountNotLiveYet.message)"))
        } else {
            #expect(result.technicalDetails?.contains("live_account_unavailable") == true)
        }
    }

    @Test func test_evaluate_when_puerto_rico_store_uses_us_account_then_accepts_country_normalization() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.evaluate(account: account(), gateway: .wcPay, currency: "USD", country: "PR")
        // Then
        #expect(result.isSuccess)
    }

    @Test(arguments: [401, 403, 502, 503])
    func test_requestFailure_when_http_error_then_keeps_status_without_response_body(status: Int) {
        // Given
        let sut = makeSUT()
        let error = NetworkRequestError.unacceptableStatusCode(statusCode: status, response: Data("secret account data".utf8))
        // When
        let result = sut.requestFailure(error, stage: "system_status")
        // Then
        #expect(!result.isSuccess)
        #expect(result.technicalDetails?.contains("http_status=\(status)") == true)
        #expect(result.technicalDetails?.contains("secret") == false)
        #expect(result.technicalDetails?.contains("checked_at=") == true)
        let expected = status < 500 ? PaymentSupportDiagnostics.Localization.blocked : PaymentSupportDiagnostics.Localization.siteError
        #expect(result.errorMessage == expected.message)
        #expect(result.headline == expected.headline)
        #expect(result.reason == (status < 500 ? "request_blocked" : "server_error"))
    }

    @Test func test_requestFailure_when_direct_REST_reply_has_wordpress_permission_code_then_reports_access_denied() {
        // Given
        let sut = makeSUT()
        let error = NetworkRequestError.unacceptableStatusCode(statusCode: 403, response: Data(#"{"code":"woocommerce_rest_cannot_view"}"#.utf8))
        // When
        let result = sut.requestFailure(error, stage: "woocommerce-payments/accounts")
        // Then
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.accessDenied.message)
        #expect(result.technicalDetails?.contains("access_denied; http_status=403") == true)
    }

    @Test(arguments: [false, true])
    func test_requestFailure_when_store_blocks_request_then_points_to_the_party_that_hosts_the_site(isHostedByWordPressCom: Bool) {
        // Given
        let site = Site.fake().copy(isWordPressComStore: isHostedByWordPressCom)
        let sut = PaymentSupportDiagnostics(siteID: 123,
                                            stores: MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site)))
        // When
        let result = sut.requestFailure(UnexpectedStoreResponseError(kind: .unacceptableStatusCode, statusCode: 403), stage: "system_status")
        // Then
        #expect(result.headline == PaymentSupportDiagnostics.Localization.blocked.headline)
        #expect(result.errorMessage == (isHostedByWordPressCom ?
                                        PaymentSupportDiagnostics.Localization.hostedSiteMessage :
                                        PaymentSupportDiagnostics.Localization.blocked.message))
    }

    @Test func test_requestFailure_when_connection_fails_then_asks_to_check_connection() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.requestFailure(URLError(.networkConnectionLost), stage: "system_status")
        // Then
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.requestFailed.message)
        #expect(result.suggestedAction == .retryDiagnostics)
    }

    @Test func test_requestFailure_when_timeout_then_keeps_unknown_outcome_and_diagnostic_retry() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.requestFailure(URLError(.timedOut), stage: "accounts")
        // Then
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.siteError.message)
        #expect(result.technicalDetails?.contains("request_timeout") == true)
        #expect(result.suggestedAction == .retryDiagnostics)
    }

    @Test(arguments: ["system_status", "settings/general", "woocommerce-payments/accounts", "woocommerce-stripe/accounts"])
    func test_requestFailure_when_unreadable_response_then_names_the_failed_request(stage: String) {
        // Given
        let sut = makeSUT()
        let error = UnexpectedStoreResponseError(kind: .unexpectedContent, statusCode: 200)
        // When
        let result = sut.requestFailure(error, stage: stage)
        // Then
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.siteError.message)
        #expect(result.technicalDetails?.contains("stage=\(stage); invalid_response") == true)
    }

    @Test(arguments: ["CA", "PR", "AU"])
    func test_run_when_stripe_unsupported_and_both_plugins_active_then_checks_wcpay(country: String) async {
        // Given
        let currency = country == "CA" ? "CAD" : (country == "AU" ? "AUD" : "USD")
        let account = account().copy(supportedCurrencies: [currency], country: country == "PR" ? "US" : country)
        for preferred in [nil, CardPresentPaymentsPlugin.stripe] {
            let sut = makeSUT(plugins: [plugin(.wcPay), plugin(.stripe)], preferred: preferred,
                              country: country, currency: currency, account: account)
            // When
            let result = await sut.run()
            // Then
            #expect(result.isSuccess)
            #expect(requestedGateways(sut) == [.wcPay])
        }
    }

    @Test func test_requestFailure_when_sanitized_server_error_then_preserves_http_status() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.requestFailure(UnexpectedStoreResponseError(kind: .unacceptableStatusCode, statusCode: 503), stage: "accounts")
        // Then
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.siteError.message)
        #expect(result.technicalDetails?.contains("http_status=503") == true)
    }

    @Test func test_requestFailure_when_wordpress_forbidden_then_reports_access_without_inventing_status() {
        // Given
        let sut = makeSUT()
        // When
        let result = sut.requestFailure(WordPressApiError.unknown(code: "rest_forbidden", message: "private response"), stage: "accounts")
        // Then
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.accessDenied.message)
        #expect(result.technicalDetails?.contains("access_denied") == true)
        #expect(result.technicalDetails?.contains("http_status=") == false)
        #expect(result.technicalDetails?.contains("private response") == false)
    }

    @Test func test_requestFailure_when_tunnel_curl_timeout_then_reports_timeout_without_raw_message() {
        // Given
        let sut = makeSUT()
        let error = DotcomError.requestFailed(message: "cURL error 28: Operation timed out; private data")
        // When
        let result = sut.requestFailure(error, stage: "accounts")
        // Then
        #expect(result.errorMessage == PaymentSupportDiagnostics.Localization.siteError.message)
        #expect(result.technicalDetails?.contains("request_timeout") == true)
        #expect(result.technicalDetails?.contains("private data") == false)
    }

    private func requestedGateways(_ sut: PaymentSupportDiagnostics) -> [CardPresentPaymentsPlugin] {
        (sut.stores as? MockStoresManager)?.receivedActions.compactMap { action in
            guard let action = action as? CardPresentPaymentAction,
                  case let .fetchPaymentGatewayAccount(_, gateway, _) = action else { return nil }
            return gateway
        } ?? []
    }

    private func makeSUT(plugins: [Yosemite.SystemPlugin]? = nil,
                         inactivePlugins: [Yosemite.SystemPlugin] = [],
                         preferred: CardPresentPaymentsPlugin? = nil,
                         country: String = "US",
                         currency: String = "USD",
                         account: PaymentGatewayAccount? = nil,
                         accountError: Error? = nil,
                         settingsError: Error? = nil,
                         storeAddress: [String] = ["1 Main Street", "San Francisco", "94110"]) -> PaymentSupportDiagnostics {
        PaymentSupportDiagnostics(siteID: 123,
                                  stores: stores(plugins: plugins, inactivePlugins: inactivePlugins, preferred: preferred, country: country, currency: currency,
                                                 account: account, accountError: accountError, settingsError: settingsError,
                                                 storeAddress: storeAddress))
    }

    private func stores(plugins: [Yosemite.SystemPlugin]? = nil,
                        inactivePlugins: [Yosemite.SystemPlugin] = [],
                        preferred: CardPresentPaymentsPlugin? = nil,
                        country: String = "US",
                        currency: String = "USD",
                        account: PaymentGatewayAccount? = nil,
                        accountError: Error? = nil,
                        settingsError: Error? = nil,
                        storeAddress: [String] = ["1 Main Street", "San Francisco", "94110"]) -> MockStoresManager {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        let report = Yosemite.SystemStatusReport(activePlugins: plugins ?? [plugin(.wcPay)], inactivePlugins: inactivePlugins, environment: nil,
                                                 database: nil, dropinPlugins: [], mustUsePlugins: [], theme: nil, settings: nil,
                                                 pages: [], postTypeCounts: [], security: nil)
        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            if case .fetchSystemStatusReport(_, _, let completion) = action {
                completion(.success(report))
            } else {
                Issue.record("Unexpected diagnostic mutation")
            }
        }
        let addressIDs = ["woocommerce_store_address", "woocommerce_store_city", "woocommerce_store_postcode"]
        let settings = [SiteSetting.fake().copy(settingID: "woocommerce_default_country", value: country),
                        SiteSetting.fake().copy(settingID: "woocommerce_currency", value: currency)] +
            zip(addressIDs, storeAddress).map { SiteSetting.fake().copy(settingID: $0, value: $1) }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            if case .retrieveGeneralSiteSettings(_, let completion) = action {
                completion(settingsError.map { .failure($0) } ?? .success(settings))
            } else {
                Issue.record("Unexpected settings mutation")
            }
        }
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            if case .getPreferredInPersonPaymentGateway(_, let completion) = action {
                completion(preferred?.gatewayID)
            } else {
                Issue.record("Unexpected gateway preference mutation")
            }
        }
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case .fetchPaymentGatewayAccount(_, _, let completion) = action {
                completion(accountError.map { .failure($0) } ?? .success(account ?? self.account()))
            } else {
                Issue.record("Diagnostics must not change gateway selection, cache or reader state")
            }
        }
        return stores
    }

    private func plugin(_ gateway: CardPresentPaymentsPlugin) -> Yosemite.SystemPlugin {
        Yosemite.SystemPlugin.fake().copy(plugin: gateway.fileNameWithPathExtension + ".php", version: "99.0.0", active: true)
    }

    private func account() -> PaymentGatewayAccount {
        PaymentGatewayAccount.fake().copy(siteID: 123, gatewayID: CardPresentPaymentsPlugin.wcPay.gatewayID, status: "complete",
                                           hasPendingRequirements: false, hasOverdueRequirements: false,
                                           defaultCurrency: "usd", supportedCurrencies: ["usd"], country: "US",
                                           isCardPresentEligible: true, isLive: true, isInTestMode: false)
    }
}
