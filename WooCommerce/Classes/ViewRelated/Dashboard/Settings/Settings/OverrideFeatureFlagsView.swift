import SwiftUI
import Experiments

struct OverrideFeatureFlagsView: View {
    @State private var refreshID = UUID()
    @State private var searchText = ""

    private var filteredFeatureFlags: [FeatureFlag] {
        let allFlags = FeatureFlag.allCases
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allFlags
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allFlags.filter { $0.title.lowercased().contains(query) }
    }

    var body: some View {
        List {
            ForEach(filteredFeatureFlags, id: \.self) { flag in
                FeatureFlagRow(featureFlag: flag)
            }
        }
        .id(refreshID)
        .searchable(text: $searchText, prompt: "Search feature flags")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    ServiceLocator.featureFlagOverrideStore.removeAllOverrides()
                    refreshID = UUID()
                } label: {
                    Text("Reset All")
                }
            }
        }
        .navigationTitle("Override Feature Flags")
    }
}

#Preview {
    OverrideFeatureFlagsView()
}

fileprivate struct FeatureFlagRow: View {
    let featureFlag: FeatureFlag

    // Keep local state so the row updates immediately when you toggle/reset.
    @State private var overrideValue: Bool?

    private var defaultValue: Bool {
        DefaultFeatureFlagService().isFeatureFlagEnabled(featureFlag)
    }

    private var effectiveValue: Bool {
        overrideValue ?? defaultValue
    }

    private var isOverridden: Bool {
        overrideValue != nil
    }

    init(featureFlag: FeatureFlag) {
        self.featureFlag = featureFlag
        // Load the persisted override once for initial rendering.
        _overrideValue = State(initialValue: ServiceLocator.featureFlagOverrideStore.overrideValue(for: featureFlag))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(featureFlag.title)
                    .font(.body)

                Spacer()

                Toggle(isOn: Binding(
                    get: { effectiveValue },
                    set: { newValue in
                        // If the user selects the default value, keep things clean and clear the override.
                        if newValue == defaultValue {
                            overrideValue = nil
                            ServiceLocator.featureFlagOverrideStore.setOverrideValue(nil, for: featureFlag)
                        } else {
                            overrideValue = newValue
                            ServiceLocator.featureFlagOverrideStore.setOverrideValue(newValue, for: featureFlag)
                        }
                    }
                )) {
                }
            }

            HStack(spacing: 12) {
                Text("Default: \(defaultValue ? "Enabled" : "Disabled")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if isOverridden {
                    Button("Reset") {
                        overrideValue = nil
                        ServiceLocator.featureFlagOverrideStore.setOverrideValue(nil, for: featureFlag)
                    }
                    .disabled(!isOverridden)
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

extension FeatureFlag {

    var title: String {
        switch self {
        case .null: "null"
        case .barcodeScanner: "barcodeScanner"
        case .reviews: "reviews"
        case .inbox: "inbox"
        case .showInboxCTA: "showInboxCTA"
        case .updateOrderOptimistically: "updateOrderOptimistically"
        case .shippingLabelsOnboardingM1: "shippingLabelsOnboardingM1"
        case .searchProductsBySKU: "searchProductsBySKU"
        case .tapToPayOnIPhone: "tapToPayOnIPhone"
        case .performanceMonitoring: "performanceMonitoring"
        case .performanceMonitoringCoreData: "performanceMonitoringCoreData"
        case .performanceMonitoringFileIO: "performanceMonitoringFileIO"
        case .performanceMonitoringNetworking: "performanceMonitoringNetworking"
        case .performanceMonitoringUserInteraction: "performanceMonitoringUserInteraction"
        case .performanceMonitoringViewController: "performanceMonitoringViewController"
        case .supportRequests: "supportRequests"
        case .jetpackSetupWithApplicationPassword: "jetpackSetupWithApplicationPassword"
        case .addProductToOrderViaSKUScanner: "addProductToOrderViaSKUScanner"
        case .manualErrorHandlingForSiteCredentialLogin: "manualErrorHandlingForSiteCredentialLogin"
        case .euShippingNotification: "euShippingNotification"
        case .betterCustomerSelectionInOrder: "betterCustomerSelectionInOrder"
        case .hazmatShipping: "hazmatShipping"
        case .giftCardInOrderForm: "giftCardInOrderForm"
        case .productBundlesInOrderForm: "productBundlesInOrderForm"
        case .customLoginUIForAccountCreation: "customLoginUIForAccountCreation"
        case .scanToUpdateInventory: "scanToUpdateInventory"
        case .splitViewInProductsTab: "splitViewInProductsTab"
        case .subscriptionsInOrderCreationUI: "subscriptionsInOrderCreationUI"
        case .subscriptionsInOrderCreationCustomers: "subscriptionsInOrderCreationCustomers"
        case .pointOfSale: "pointOfSale"
        case .googleAdsCampaignCreationOnWebView: "googleAdsCampaignCreationOnWebView"
        case .blazeEvergreenCampaigns: "blazeEvergreenCampaigns"
        case .revampedShippingLabelCreation: "revampedShippingLabelCreation"
        case .blazeCampaignObjective: "blazeCampaignObjective"
        case .hideSitesInStorePicker: "hideSitesInStorePicker"
        case .filterHistoryOnOrderAndProductLists: "filterHistoryOnOrderAndProductLists"
        case .backgroundProductImageUpload: "backgroundProductImageUpload"
        case .notificationSettings: "notificationSettings"
        case .allowMerchantAIAPIKey: "allowMerchantAIAPIKey"
        case .productImageOptimizedHandling: "productImageOptimizedHandling"
        case .inventoryProductLabelsInPOS: "inventoryProductLabelsInPOS"
        case .pointOfSaleOrdersi1: "pointOfSaleOrdersi1"
        case .pointOfSaleOrdersi2: "pointOfSaleOrdersi2"
        case .orderAddressMapSearch: "orderAddressMapSearch"
        case .pointOfSaleHistoricalOrdersi1: "pointOfSaleHistoricalOrdersi1"
        case .pointOfSaleLocalCatalogi1: "pointOfSaleLocalCatalogi1"
        case .ciabBookings: "ciabBookings"
        case .ciab: "ciab"
        case .pointOfSaleSurveys: "pointOfSaleSurveys"
        case .pointOfSaleCatalogAPI: "pointOfSaleCatalogAPI"
        case .pointOfSaleRefundsi1: "pointOfSaleRefundsi1"
        case .selfDrivenPushToken: "selfDrivenPushToken"
        case .pointOfSaleOnlyProducts: "pointOfSaleOnlyProducts"
        }
    }
}
