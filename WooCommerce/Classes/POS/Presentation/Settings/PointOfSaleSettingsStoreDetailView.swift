import SwiftUI
import Yosemite

struct PointOfSaleSettingsStoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shouldShowReceiptInformation = true
    @State private var posSettingsService: PointOfSaleSettingsService = .empty
    @State private var isLoadingSettings = true

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Group {
                    Text("Store Information")
                        .font(.title2)

                    Text("Store name")
                    Text(posSettingsService.storeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Address")
                    Text(posSettingsService.storeAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Email")
                    Text(posSettingsService.storeEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Group {
                    Spacer()
                    Text("Receipt Information")
                        .font(.title2)
                    Text("Store name")
                    Text(isLoadingSettings ? "Loading..." : posSettingsService.receiptStoreName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Physical address")
                    Text(isLoadingSettings ? "Loading..." : posSettingsService.receiptStoreAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Phone number")
                    Text(isLoadingSettings ? "Loading..." : posSettingsService.receiptStorePhone)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Email")
                    Text(isLoadingSettings ? "Loading..." : posSettingsService.receiptStoreEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Refund & Returns Policy")
                    Text(isLoadingSettings ? "Loading..." : posSettingsService.receiptRefundReturnsPolicy)
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
            shouldShowReceiptInformation = await posSettingsService.isPluginSupported(.wooCommerce, minimumVersion: "10.0")
        }
        .task {
            let siteID = ServiceLocator.stores.sessionManager.defaultSite?.siteID ?? 0
            let action = SettingAction.retrievePointOfSaleSettings(siteID: siteID) { result in
                switch result {
                case .success(let siteSettings):
                    self.posSettingsService = PointOfSaleSettingsService(from: siteSettings)
                    self.isLoadingSettings = false
                case .failure(let error):
                    DDLogError("Failed to load POS settings: \(error)")
                    self.posSettingsService = .empty
                    self.isLoadingSettings = false
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
    }
}

#Preview {
    PointOfSaleSettingsStoreDetailView()
}
