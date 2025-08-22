import Yosemite
import SwiftUI

struct PointOfSaleSettingsStoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shouldShowReceiptInformation = false

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
                    Text("WIP")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Physical address")
                    Text("WIP")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Phone number")
                    Text("WIP")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Email")
                    Text("WIP")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Refund & Returns Policy")
                    Text("WIP")
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
            /**
             TODO - WOOMOB-1160: retrieval for woocommerce_pos_ settings
             woocommerce_pos_store_name
             woocommerce_pos_store_address
             woocommerce_pos_store_phone
             woocommerce_pos_store_email
             woocommerce_pos_refund_returns_policy
             */
        }
    }
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
