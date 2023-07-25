import SwiftUI
import Yosemite

private enum SiteIDSourceType: String, Equatable, CaseIterable {
    case appUser
    case environmentVariable

    var title: String {
        switch self {
        case .appUser:
            return "App user's site"
        case .environmentVariable:
            return "Environment variable"
        }
    }

    var noSourceIDFoundHint: String {
        switch self {
        case .appUser:
            return "Please make sure that the user has a valid Site ID"
        case .environmentVariable:
            return "Please set your Int64 test site id to the Xcode environment variable with name \(Constants.siteIdEnvironmentVariableName)."
        }
    }

    func retrieveUpgradingSiteID() -> Int64? {
        switch self {
        case .appUser:
            return ServiceLocator.stores.sessionManager.defaultStoreID
        case .environmentVariable:
            guard let stringSiteID = ProcessInfo.processInfo.environment[Constants.siteIdEnvironmentVariableName] else {
                return nil
            }

            return Int64(stringSiteID)
        }
    }
}

@MainActor
struct InAppPurchasesDebugView: View {
    private let inAppPurchasesForWPComPlansManager = InAppPurchasesForWPComPlansManager()
    @State var wpcomPlans: [WPComPlanProduct] = []
    @State var entitledWpcomPlanIDs: Set<String> = []
    @State var inAppPurchasesAreSupported = true
    @State var isPurchasing = false
    @State private var selectedSiteIDSourceType: SiteIDSourceType = .appUser
    @State private var purchaseError: PurchaseError? {
        didSet {
            presentAlert = purchaseError != nil
        }
    }
    @State var presentAlert = false



    var body: some View {
        List {
             Section("Upgrading Site ID Source") {
                Picker(selection: $selectedSiteIDSourceType, label: EmptyView()) {
                    ForEach(SiteIDSourceType.allCases, id: \.self) { option in
                        Text(option.title)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section {
                Button("Reload plans") {
                    Task {
                        await loadPlans()
                    }
                }
            }
            Section("Plans") {
                if wpcomPlans.isEmpty {
                    Text("No plans")
                } else if isPurchasing {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else if let siteID = selectedSiteIDSourceType.retrieveUpgradingSiteID() {
                    ForEach(wpcomPlans, id: \.id) { plan in
                        Button(entitledWpcomPlanIDs.contains(plan.id) ? "Entitled: \(plan.displayName)" : plan.displayName) {
                            Task {
                                isPurchasing = true
                                do {
                                    let result = try await inAppPurchasesForWPComPlansManager.purchasePlan(with: plan.id, for: siteID)
                                    print("[IAP Debug] Purchase result: \(result)")
                                } catch {
                                    purchaseError = PurchaseError(error: error)
                                }
                                await loadUserEntitlements()
                                isPurchasing = false
                            }
                        }
                        .alert(isPresented: $presentAlert, error: purchaseError, actions: {})
                    }
                } else {
                    Text("No valid site id could be retrieved to purchase WPCom plan. " + selectedSiteIDSourceType.noSourceIDFoundHint)
                    .foregroundColor(.red)
                }
            }

            Section {
                Button("Retry WPCom Synchronization for entitled plans") {
                    retryWPComSynchronizationForPurchasedProducts()
                }.disabled(!inAppPurchasesAreSupported || entitledWpcomPlanIDs.isEmpty)
            }

            Section {
                Text("In-App Purchases are not supported for this user")
                    .foregroundColor(.red)
            }
            .renderedIf(!inAppPurchasesAreSupported)

            Section {
                Text("⚠️ Your WPCOM Sandbox URL is not setup")
                    .headlineStyle()
                Text("To test In-App Purchases in sandbox please make sure that the WPCOM requests are pointing " +
                     "to your sandbox environment and you have the billing system sandbox-mode enabled there.")
                .padding()
            }
            .renderedIf(ProcessInfo.processInfo.environment["wpcom-api-base-url"] == nil)
        }
        .navigationTitle("IAP Debug")
        .task {
            await loadPlans()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await loadUserEntitlements()
            }
        }
    }

    private func loadPlans() async {
        do {
            inAppPurchasesAreSupported = await inAppPurchasesForWPComPlansManager.inAppPurchasesAreSupported()

            guard inAppPurchasesAreSupported else {
                return
            }

            self.wpcomPlans = try await inAppPurchasesForWPComPlansManager.fetchPlans()
            await loadUserEntitlements()
        } catch {
            print("Error loading products: \(error)")
        }
    }

    private func loadUserEntitlements() async {
        do {
            for plan in self.wpcomPlans {
                if try await inAppPurchasesForWPComPlansManager.userIsEntitledToPlan(with: plan.id) {
                    self.entitledWpcomPlanIDs.insert(plan.id)
                } else {
                    self.entitledWpcomPlanIDs.remove(plan.id)
                }
            }
        }
        catch {
            print("Error loading user entitlements: \(error)")
        }
    }

    private func retryWPComSynchronizationForPurchasedProducts() {
        Task {
            for id in entitledWpcomPlanIDs {
                try await inAppPurchasesForWPComPlansManager.retryWPComSyncForPurchasedPlan(with: id)
            }
        }
    }
}

/// Just a silly little wrapper because SwiftUI's `alert(isPresented:error:actions:)` wants a `LocalizedError`
/// but we only have an `Error` coming from `purchaseProduct`.
private struct PurchaseError: LocalizedError {
    let error: Error

    var errorDescription: String? {
        if let error = error as? LocalizedError {
            return error.errorDescription
        } else {
            return error.localizedDescription
        }
    }
}

struct InAppPurchasesDebugView_Previews: PreviewProvider {
    static var previews: some View {
        InAppPurchasesDebugView()
    }
}

private enum Constants {
    static let siteIdEnvironmentVariableName = "iap-debug-site-id"
}
