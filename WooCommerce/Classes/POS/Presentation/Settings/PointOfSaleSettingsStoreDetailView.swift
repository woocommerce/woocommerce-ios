import SwiftUI
import Yosemite

final class StoreSettingsViewModel: ObservableObject {
    @Published var receiptInformation = POSReceiptInformation.empty
    @Published var shouldShowReceiptInformation: Bool = false

    private let siteID: Int64
    private let settingsService: PointOfSaleSettingsServiceProtocol
    private let pluginsService: PluginsServiceProtocol

    init(siteID: Int64,
         settingsService: PointOfSaleSettingsServiceProtocol,
         pluginsService: PluginsServiceProtocol) {
        self.siteID = siteID
        self.settingsService = settingsService
        self.pluginsService = pluginsService
    }

    @MainActor
    func retrievePOSReceiptSettings() async {
        shouldShowReceiptInformation = await isPluginSupported(.wooCommerce, minimumVersion: Constants.minimumWooCommerceVersion)

        guard shouldShowReceiptInformation else {
            return
        }
        do {
            let siteSettings = try await settingsService.retrievePointOfSaleSettings()
            updateReceiptSettings(from: siteSettings)
        } catch {
            DDLogError("Failed to load POS settings: \(error)")
        }
    }

    @MainActor
    private func isPluginSupported(_ plugin: Plugin,
                                   minimumVersion: String) async -> Bool {
        guard let systemPlugin = pluginsService.loadPluginInStorage(siteID: siteID, plugin: plugin, isActive: true), systemPlugin.active else {
            return false
        }

        let isSupported = VersionHelpers.isVersionSupported(version: systemPlugin.version,
                                                            minimumRequired: minimumVersion)
        return isSupported
    }

    private func updateReceiptSettings(from siteSettings: [SiteSetting]) {
        receiptInformation = POSReceiptInformation(
            storeName: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_name"),
            storeAddress: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_address"),
            phone: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_phone"),
            email: settingValue(from: siteSettings, settingID: "woocommerce_pos_store_email"),
            refundReturnsPolicy: settingValue(from: siteSettings, settingID: "woocommerce_pos_refund_returns_policy")
        )
    }

    private func settingValue(from siteSettings: [SiteSetting], settingID: String) -> String? {
        let value = siteSettings.first { $0.settingID == settingID }?.value
        return value?.isEmpty == true ? nil : value
    }
}

private extension StoreSettingsViewModel {
    enum Constants {
        static let minimumWooCommerceVersion: String = "10.0"
    }
}

struct PointOfSaleSettingsStoreDetailView: View {
    @State private var isLoading: Bool = true
    @StateObject private var storeViewModel: StoreSettingsViewModel

    let settingsController: PointOfSaleSettingsControllerProtocol

    init(settingsController: PointOfSaleSettingsControllerProtocol) {
        self.settingsController = settingsController
        self._storeViewModel = StateObject(wrappedValue: StoreSettingsViewModel(
            siteID: settingsController.siteID,
            settingsService: settingsController.settingsService,
            pluginsService: settingsController.pluginsService
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.storeName)
                            .font(.posBodyMediumRegular())
                        Text(settingsController.storeName)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.address)
                            .font(.posBodyMediumRegular())
                        Text(settingsController.storeAddress)
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(Localization.storeInformation)
                        .font(.posBodyLargeRegular())
                }

                Section {
                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.receiptStoreName)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: storeViewModel.receiptInformation.storeName)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.physicalAddress)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: storeViewModel.receiptInformation.storeAddress)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.phoneNumber)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: storeViewModel.receiptInformation.phone)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.email)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: storeViewModel.receiptInformation.email)
                    }

                    VStack(alignment: .leading, spacing: POSPadding.small) {
                        Text(Localization.refundReturnsPolicy)
                            .font(.posBodyMediumRegular())
                        settingValueView(for: storeViewModel.receiptInformation.refundReturnsPolicy)
                    }
                } header: {
                    Text(Localization.receiptInformation)
                        .font(.posBodyLargeRegular())
                }
                .renderedIf(storeViewModel.shouldShowReceiptInformation)
            }
            .task {
                isLoading = true
                await storeViewModel.retrievePOSReceiptSettings()
                isLoading = false
            }
        }
    }

    @ViewBuilder
    private func settingValueView(for value: String?) -> some View {
        if isLoading {
            GhostSettingRowView()
        } else {
            Text(value ?? Localization.notSet)
                .font(.posBodyMediumRegular())
                .foregroundStyle(.secondary)
        }
    }
}

// Temporary: Simplified copy from PointOfSaleOrderListView.GhostOrderRowView
private struct GhostSettingRowView: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var minHeight: CGFloat {
        min(Constants.orderCardMinHeight * scale, Constants.maximumOrderCardHeight)
    }

    var body: some View {
        HStack(alignment: .center, spacing: POSSpacing.medium) {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: 70, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()

                Rectangle()
                    .fill(Color.posOnSurfaceVariantLowest)
                    .frame(width: 160, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shimmering()
            }
        }
        .padding(.horizontal, POSPadding.medium * (1 / scale))
        .padding(.vertical, POSPadding.medium * (1 / scale))
        .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? nil : minHeight, alignment: .leading)
        .background(Color.posSurfaceContainerLowest)
        .posItemCardBorderStyles()
        .geometryGroup()
    }

    private enum Constants {
        static let orderCardMinHeight: CGFloat = 90
        static let maximumOrderCardHeight: CGFloat = Constants.orderCardMinHeight * 2
    }
}

private extension PointOfSaleSettingsStoreDetailView {
    enum Localization {
        static let notSet = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.notSet",
            value: "Not set",
            comment: "Text displayed on Point of Sale settings when any setting has not been provided."
        )

        static let storeInformation = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.storeInformation",
            value: "Store Information",
            comment: "Section title for store information in Point of Sale settings."
        )

        static let storeName = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.storeName",
            value: "Store name",
            comment: "Label for store name field in Point of Sale settings."
        )

        static let address = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.address",
            value: "Address",
            comment: "Label for address field in Point of Sale settings."
        )

        static let receiptInformation = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.receiptInformation",
            value: "Receipt Information",
            comment: "Section title for receipt information in Point of Sale settings."
        )

        static let receiptStoreName = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.receiptStoreName",
            value: "Store name",
            comment: "Label for receipt store name field in Point of Sale settings."
        )

        static let physicalAddress = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.physicalAddress",
            value: "Physical address",
            comment: "Label for physical address field in Point of Sale settings."
        )

        static let phoneNumber = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.phoneNumber",
            value: "Phone number",
            comment: "Label for phone number field in Point of Sale settings."
        )

        static let email = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.email",
            value: "Email",
            comment: "Label for email field in Point of Sale settings."
        )

        static let refundReturnsPolicy = NSLocalizedString(
            "pointOfSaleSettingsStoreDetailView.refundReturnsPolicy",
            value: "Refund & Returns Policy",
            comment: "Label for refund and returns policy field in Point of Sale settings."
        )
    }
}

#if DEBUG
#Preview {
    PointOfSaleSettingsStoreDetailView(settingsController: PointOfSaleSettingsPreviewController())
}
#endif
