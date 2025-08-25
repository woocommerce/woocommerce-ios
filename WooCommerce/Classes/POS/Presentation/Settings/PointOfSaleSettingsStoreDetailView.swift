import SwiftUI
import Yosemite

struct PointOfSaleSettingsStoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let posSettingsService: PointOfSaleSettingsService

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
                    settingValueView(for: posSettingsService.receiptStoreName)

                    Text("Physical address")
                    settingValueView(for: posSettingsService.receiptStoreAddress)

                    Text("Phone number")
                    settingValueView(for: posSettingsService.receiptStorePhone)

                    Text("Email")
                    settingValueView(for: posSettingsService.receiptStoreEmail)

                    Text("Refund & Returns Policy")
                    settingValueView(for: posSettingsService.receiptRefundReturnsPolicy)

                }
                .renderedIf(posSettingsService.shouldShowReceiptInformation)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await posSettingsService.loadSettings()
        }
    }

    @ViewBuilder
    private func settingValueView(for value: String) -> some View {
        if posSettingsService.isLoading {
            ProgressView()
                .controlSize(.small)
        } else {
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PointOfSaleSettingsStoreDetailView(posSettingsService: PointOfSaleSettingsService())
}
