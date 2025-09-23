import SwiftUI
import WooFoundationCore
import WooFoundation
import enum Experiments.FeatureFlag
import struct Yosemite.Coupon
import enum Yosemite.POSItem

/// POSDepenencyProviding is part of the POS entry point that defines the external dependencies from the Woo app that POS depends on

/// Protocol that provides analytics tracking capabilities for POS
protocol POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent)
    func track(_ stat: WooAnalyticsStat)
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType])
    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType], error: Error)
}

extension POSAnalyticsProviding {
    func track(_ stat: WooAnalyticsStat) {
        track(stat, parameters: [:])
    }
}

/// Protocol that provides currency settings access for POS
protocol POSCurrencySettingsProviding {
    var currencySettings: CurrencySettings { get }
}

/// Protocol that provides feature flag checking capabilities for POS
protocol POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool
}

/// Protocol that provides connectivity monitoring for POS
protocol POSConnectivityProviding {
    var connectivityObserver: ConnectivityObserver { get }
}

/// Protocol that provides main app navigation capabilities for POS
protocol POSExternalNavigationProviding {
    func navigateToCreateOrder()
}

/// Protocol that provides access to complex Woo application views that depend on a lot of Woo app target dependencies
/// and cannot be easily moved and reused in a shared module
/// This is used as a workaround to enable POS modularization without requiring a larger refactoring effort
///
protocol POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>, sourceTag: String) -> AnyView
    func createFormattableAmountTextField(preset: Decimal?,
                                          onSubmit: @escaping () -> Void,
                                          onChange: @escaping (String) -> Void) -> AnyView
    func createCouponCreationView(discountType: Coupon.DiscountType,
                                  showTypeSelection: Binding<Bool>,
                                  onSuccess: @escaping (Coupon) -> Void,
                                  dismissHandler: @escaping () -> Void,
                                  onDisappear: @escaping () -> Void) -> AnyView
    func createDiscountTypeSelectionSheet(isPresented: Binding<Bool>,
                                          title: String,
                                          cancelButtonTitle: String,
                                          onSelection: @escaping (Coupon.DiscountType) -> Void) -> AnyView
}

/// Main protocol that combines all POS dependency providers
/// This enables dependency injection for POS code while maintaining clean separation from ServiceLocator
protocol POSDependencyProviding {
    var analytics: POSAnalyticsProviding { get }
    var currency: POSCurrencySettingsProviding { get }
    var featureFlags: POSFeatureFlagProviding { get }
    var connectivity: POSConnectivityProviding { get }
    var externalNavigation: POSExternalNavigationProviding { get }
    var externalViews: POSExternalViewProviding { get }
}
