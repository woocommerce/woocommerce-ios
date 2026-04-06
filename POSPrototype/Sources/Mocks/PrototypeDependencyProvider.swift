import SwiftUI
import Combine
import PointOfSale
import Yosemite
import WooFoundation
import WooFoundationCore
import enum Experiments.FeatureFlag

final class PrototypeDependencyProvider: POSDependencyProviding {
    var analytics: POSAnalyticsProviding = PrototypePOSAnalytics()
    var currency: POSCurrencySettingsProviding = PrototypePOSCurrencySettings()
    var featureFlags: POSFeatureFlagProviding = PrototypeFeatureFlags()
    var connectivity: POSConnectivityProviding = PrototypePOSConnectivityProvider()
    var externalNavigation: POSExternalNavigationProviding = PrototypePOSExternalNavigation()
    var externalViews: POSExternalViewProviding = PrototypePOSExternalView()
}

// MARK: - Analytics

private struct PrototypePOSAnalytics: POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent) {}
    func track(_ stat: WooAnalyticsStat) {}
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType]) {}
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: Error) {}
}

// MARK: - Currency

private struct PrototypePOSCurrencySettings: POSCurrencySettingsProviding {
    var currencySettings = CurrencySettings()
}

// MARK: - Feature Flags

private struct PrototypeFeatureFlags: POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool { true }
}

// MARK: - Connectivity

private final class PrototypePOSConnectivityProvider: POSConnectivityProviding {
    var connectivityObserver: ConnectivityObserver = PrototypePOSConnectivity()
}

private final class PrototypePOSConnectivity: ConnectivityObserver {
    @Published private(set) var currentStatus: ConnectivityStatus = .reachable(type: .ethernetOrWiFi)
    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> { $currentStatus.eraseToAnyPublisher() }
}

// MARK: - External Navigation

private struct PrototypePOSExternalNavigation: POSExternalNavigationProviding {
    func navigateToCreateOrder() {}
}

// MARK: - External Views

private struct PrototypePOSExternalView: POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>, sourceTag: String) -> AnyView {
        AnyView(EmptyView())
    }

    func createCouponCreationView(discountType: CouponDiscountType,
                                  showTypeSelection: Binding<Bool>,
                                  onSuccess: @escaping (Coupon) -> Void,
                                  dismissHandler: @escaping () -> Void,
                                  onDisappear: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }

    func createDiscountTypeSelectionSheet(isPresented: Binding<Bool>,
                                          title: String,
                                          cancelButtonTitle: String,
                                          onSelection: @escaping (CouponDiscountType) -> Void) -> AnyView {
        AnyView(EmptyView())
    }

    func createAuthenticatedWebView(url: URL, title: String, completion: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }
}
