import SwiftUI
import Combine
import WooFoundation
import Experiments
import protocol Yosemite.Action
import struct Yosemite.Site
import enum Yosemite.POSItem
import struct Yosemite.Coupon

struct SiteTimezoneKey: EnvironmentKey {
    static let defaultValue: TimeZone = .current
}

extension EnvironmentValues {
    var siteTimezone: TimeZone {
        get { self[SiteTimezoneKey.self] }
        set { self[SiteTimezoneKey.self] = newValue }
    }
}

/// Environment key for POS analytics service in SwiftUI
struct POSAnalyticsKey: EnvironmentKey {
    static let defaultValue: POSAnalyticsProviding = EmptyPOSAnalytics()
}

/// Environment key for POS currency settings
struct POSCurrencySettingsKey: EnvironmentKey {
    static let defaultValue: POSCurrencySettingsProviding = EmptyPOSCurrencySettings()
}

/// Environment key for POS feature flags service
struct POSFeatureFlagsKey: EnvironmentKey {
    static let defaultValue: POSFeatureFlagProviding = EmptyPOSFeatureFlags()
}

/// Environment key for POS bookings eligibility (true if the site supports bookings)
struct POSBookingsEligibilityKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

/// Environment key for POS connectivity
struct POSConnectivityKey: EnvironmentKey {
    static let defaultValue: POSConnectivityProviding = EmptyPOSConnectivityProvider()
}

/// Environment key for POS navigation service
struct POSExternalNavigationKey: EnvironmentKey {
    static let defaultValue: POSExternalNavigationProviding = EmptyPOSExternalNavigation()
}

/// Environment key for POS external view service
struct POSExternalViewKey: EnvironmentKey {
    static let defaultValue: POSExternalViewProviding = EmptyPOSExternalView()
}

/// Environment key for POS payment navigation router
struct POSNavigationRouterKey: EnvironmentKey {
    static let defaultValue: POSNavigationRouter = POSNavigationRouter(navigationPath: .constant([]))
}

/// Environment key for POS search text field unfocused border color
struct POSSearchTextFieldUnfocusedBorderColorKey: EnvironmentKey {
    static let defaultValue: Color = .posSurfaceBright
}

extension EnvironmentValues {
    var posAnalytics: POSAnalyticsProviding {
        get { self[POSAnalyticsKey.self] }
        set { self[POSAnalyticsKey.self] = newValue }
    }

    var posCurrencyProvider: POSCurrencySettingsProviding {
        get { self[POSCurrencySettingsKey.self] }
        set { self[POSCurrencySettingsKey.self] = newValue }
    }

    var posFeatureFlags: POSFeatureFlagProviding {
        get { self[POSFeatureFlagsKey.self] }
        set { self[POSFeatureFlagsKey.self] = newValue }
    }

    var posBookingsEligible: Bool {
        get { self[POSBookingsEligibilityKey.self] }
        set { self[POSBookingsEligibilityKey.self] = newValue }
    }

    var posConnectivityProvider: POSConnectivityProviding {
        get { self[POSConnectivityKey.self] }
        set { self[POSConnectivityKey.self] = newValue }
    }

    var posExternalNavigation: POSExternalNavigationProviding {
        get { self[POSExternalNavigationKey.self] }
        set { self[POSExternalNavigationKey.self] = newValue }
    }

    var posExternalViews: POSExternalViewProviding {
        get { self[POSExternalViewKey.self] }
        set { self[POSExternalViewKey.self] = newValue }
    }

    var posNavigationRouter: POSNavigationRouter {
        get { self[POSNavigationRouterKey.self] }
        set { self[POSNavigationRouterKey.self] = newValue }
    }

    var posSearchTextFieldUnfocusedBorderColor: Color {
        get { self[POSSearchTextFieldUnfocusedBorderColorKey.self] }
        set { self[POSSearchTextFieldUnfocusedBorderColorKey.self] = newValue }
    }
}

// MARK: - View Modifiers

extension View {
    func posSearchTextFieldUnfocusedBorderColor(_ color: Color) -> some View {
        environment(\.posSearchTextFieldUnfocusedBorderColor, color)
    }
}

// MARK: - Empty Default Values

struct EmptyPOSExternalNavigation: POSExternalNavigationProviding {
    func navigateToCreateOrder() {}
    init() {}
}

struct EmptyPOSFeatureFlags: POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool { false }
    init() {}
}

struct EmptyPOSCurrencySettings: POSCurrencySettingsProviding {
    var currencySettings = CurrencySettings()
    init() {}
}

class EmptyPOSConnectivityProvider: POSConnectivityProviding {
    var connectivityObserver: WooFoundation.ConnectivityObserver = EmptyPOSConnectivity()
    init() {}
}

class EmptyPOSConnectivity: ConnectivityObserver {
    @Published private(set) var currentStatus: ConnectivityStatus = .reachable(type: .ethernetOrWiFi)
    var statusPublisher: AnyPublisher<ConnectivityStatus, Never> { $currentStatus.eraseToAnyPublisher() }
    init() {}
}

struct EmptyPOSAnalytics: POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent) {}
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {}
    func track(_ stat: WooAnalyticsStat) {}
    func track(_ stat: WooFoundationCore.WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: any Error) {}
    init() {}
}

struct EmptyPOSExternalView: POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>, sourceTag: String) -> AnyView { AnyView(EmptyView()) }
    func createCouponCreationView(discountType: Coupon.DiscountType,
                                  showTypeSelection: Binding<Bool>,
                                  onSuccess: @escaping (Coupon) -> Void,
                                  dismissHandler: @escaping () -> Void,
                                  onDisappear: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }
    func createDiscountTypeSelectionSheet(isPresented: Binding<Bool>,
                                          title: String,
                                          cancelButtonTitle: String,
                                          onSelection: @escaping (Coupon.DiscountType) -> Void) -> AnyView {
        AnyView(EmptyView())
    }
    func createAuthenticatedWebView(url: URL, title: String, completion: @escaping () -> Void) -> AnyView {
        AnyView(EmptyView())
    }
    init() {}
}
