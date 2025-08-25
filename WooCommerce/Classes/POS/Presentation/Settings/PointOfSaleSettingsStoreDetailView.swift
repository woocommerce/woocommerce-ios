import Yosemite
import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shouldShowReceiptInformation = false
    @State private var posSettings: PointOfSaleSettings = .empty
    @State private var isLoadingSettings = true

    var storeName: String {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return "Not set"
        }
        return site.name
    }

    var storeAddress: String {
        SiteAddress().address
    }

    var storeEmail: String {
        "Not set" // TBD
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Group {
                    Text("Store Information")
                        .font(.title2)

                    Text("Store name")
                    Text(storeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Address")
                    Text(storeAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Email")
                    Text(storeEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Group {
                    Spacer()
                    Text("Receipt Information")
                        .font(.title2)
                    Text("Store name")
                    Text(isLoadingSettings ? "Loading..." : posSettings.storeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Physical address")
                    Text(isLoadingSettings ? "Loading..." : posSettings.storeAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Phone number")
                    Text(isLoadingSettings ? "Loading..." : posSettings.storePhone)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Email")
                    Text(isLoadingSettings ? "Loading..." : posSettings.storeEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Refund & Returns Policy")
                    Text(isLoadingSettings ? "Loading..." : posSettings.refundReturnsPolicy)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                }
                .renderedIf(shouldShowReceiptInformation)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            shouldShowReceiptInformation = await isPluginSupported(.wooCommerce, minimumVersion: "10.0")
        }
        .task {
            let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
            let action = SettingAction.retrievePointOfSaleSettings(siteID: siteID) { result in
                switch result {
                case .success(let siteSettings):
                    self.posSettings = PointOfSaleSettings(from: siteSettings)
                    self.isLoadingSettings = false
                case .failure(let error):
                    DDLogError("Failed to load POS settings: \(error)")
                    self.posSettings = .empty
                    self.isLoadingSettings = false
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
    }
}

struct PointOfSaleSettings {
    let storeName: String
    let storeAddress: String
    let storePhone: String
    let storeEmail: String
    let refundReturnsPolicy: String

    init(from siteSettings: [SiteSetting]) {
        self.storeName = siteSettings.first { $0.settingID == "woocommerce_pos_store_name" }?.value ?? "Not set"
        self.storeAddress = siteSettings.first { $0.settingID == "woocommerce_pos_store_address" }?.value ?? "Not set"
        self.storePhone = siteSettings.first { $0.settingID == "woocommerce_pos_store_phone" }?.value ?? "Not set"
        self.storeEmail = siteSettings.first { $0.settingID == "woocommerce_pos_store_email" }?.value ?? "Not set"
        self.refundReturnsPolicy = siteSettings.first { $0.settingID == "woocommerce_pos_refund_returns_policy" }?.value ?? "Not set"
    }

    static let empty = PointOfSaleSettings(from: [])
}

private extension PointOfSaleSettingsStoreDetailView {
    @MainActor
    func isPluginSupported(_ plugin: Plugin, minimumVersion: String) async -> Bool {
        let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
        let storageManager = ServiceLocator.storageManager
        let pluginsService = PluginsService(storageManager: storageManager)
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true),
              systemPlugin.active else {
            return false
        }

        let isSupported = VersionHelpers.isVersionSupported(version: systemPlugin.version,
                                                            minimumRequired: minimumVersion)
        return isSupported
    }
}


#Preview {
    PointOfSaleSettingsStoreDetailView()
}
