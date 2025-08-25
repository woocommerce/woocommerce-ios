import SwiftUI
import Yosemite

struct PointOfSaleSettingsStoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shouldShowReceiptInformation = true
    @State private var posSettingsService = PointOfSaleSettingsService()

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
                }

                Group {
                    Spacer()
                    Text("Receipt Information")
                        .font(.title2)
                    Text("Store name")
                    Text(posSettingsService.isLoading ? "Loading..." : posSettingsService.receiptStoreName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Physical address")
                    Text(posSettingsService.isLoading ? "Loading..." : posSettingsService.receiptStoreAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Phone number")
                    Text(posSettingsService.isLoading ? "Loading..." : posSettingsService.receiptStorePhone)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Email")
                    Text(posSettingsService.isLoading ? "Loading..." : posSettingsService.receiptStoreEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Refund & Returns Policy")
                    Text(posSettingsService.isLoading ? "Loading..." : posSettingsService.receiptRefundReturnsPolicy)
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
            await posSettingsService.loadSettings()
        }
    }
}

#Preview {
    PointOfSaleSettingsStoreDetailView()
}
