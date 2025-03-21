import SwiftUI
import AppIntents
import Foundation
import WidgetKit
import KeychainAccess
@preconcurrency import Networking
import WooFoundation

struct GetTodayRevenueAppIntent: AppIntent {
    private let orderStatsRemoteV4: OrderStatsRemoteV4

    /// Network helper.
    ///
    private let network: AlamofireNetwork
    private let storeID: Int64

    init() {
        let dependencies = Self.fetchDependencies()!
        network = AlamofireNetwork(credentials: dependencies.credentials)
        orderStatsRemoteV4 = OrderStatsRemoteV4(network: network)
        storeID = dependencies.storeID
    }


    static var title = LocalizedStringResource("Get Caffeine Intake")
    static var description = IntentDescription("Shows how much caffeine you've had today.")

    func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
        let revenueAndOrders = try await fetchTodaysRevenueAndOrders()

        return .result(value: Double(truncating: revenueAndOrders.totals.grossRevenue as NSNumber),
                       dialog: .init(stringLiteral: "You've had \(revenueAndOrders.totals.grossRevenue)$"))

    }
}

private extension GetTodayRevenueAppIntent {
    struct Dependencies {
        let credentials: Credentials
        let storeID: Int64
        let storeName: String
        let storeCurrencySettings: CurrencySettings
    }

    static func fetchDependencies() -> Dependencies? {
        let keychain = Keychain(service: WooConstants.keychainServiceName)
        guard let storeID = UserDefaults.group?[.defaultStoreID] as? Int64,
              let storeName = UserDefaults.group?[.defaultStoreName] as? String,
              let storeCurrencySettingsData = UserDefaults.group?[.defaultStoreCurrencySettings] as? Data,
              let storeCurrencySettings = try? JSONDecoder().decode(CurrencySettings.self, from: storeCurrencySettingsData) else {
            print("⛔️ missing store info")
            return nil
        }
        let credentials: Credentials? = {
            if let authToken = keychain[WooConstants.authToken] {
                return Credentials(authToken: authToken)
            } else if let username = UserDefaults.group?[.defaultUsername] as? String,
                      let password = keychain[WooConstants.siteCredentialPassword],
                      let siteAddress = UserDefaults.group?[.defaultSiteAddress] as? String {
                return .wporg(username: username, password: password, siteAddress: siteAddress)
            } else if let username = UserDefaults.group?[.defaultUsername] as? String,
                      let password = keychain[WooConstants.applicationPassword],
                      let siteAddress = UserDefaults.group?[.defaultSiteAddress] as? String {
                return .applicationPassword(username: username, password: password, siteAddress: siteAddress)
            }
            return nil
        }()
        guard let credentials else {
            print("⛔️ missing credentials")
            return nil
        }
        return Dependencies(credentials: credentials,
                            storeID: storeID,
                            storeName: storeName,
                            storeCurrencySettings: storeCurrencySettings)
    }

    func fetchTodaysRevenueAndOrders() async throws -> OrderStatsV4 {
        try await withCheckedThrowingContinuation { continuation in
            // `WKWebView` is accessed internally, we are forced to dispatch the call in the main thread.
            Task { @MainActor in
                orderStatsRemoteV4.loadOrderStats(for: storeID,
                                                  unit: .hourly,
                                                  timeZone: TimeZone.current,
                                                  earliestDateToInclude: Date().startOfDay(timezone: .current),
                                                  latestDateToInclude: Date().endOfDay(timezone: .current),
                                                  quantity: 24,
                                                  forceRefresh: true) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
}
