import SwiftUI
import WooFoundationCore
import WooFoundation
import Yosemite
import protocol Experiments.FeatureFlagService
import enum Experiments.FeatureFlag
import protocol Storage.StorageManagerType
import protocol PointOfSale.POSDependencyProviding
import protocol PointOfSale.POSAnalyticsProviding
import protocol PointOfSale.POSCurrencySettingsProviding
import protocol PointOfSale.POSFeatureFlagProviding
import protocol PointOfSale.POSConnectivityProviding
import protocol PointOfSale.POSExternalNavigationProviding
import protocol PointOfSale.POSExternalViewProviding

final class POSServiceLocatorAdaptor: POSDependencyProviding {
    init() {
    }

    var analytics: POSAnalyticsProviding {
        POSAnalyticsAdaptor()
    }

    var currency: POSCurrencySettingsProviding {
        POSCurrencySettingsAdaptor()
    }

    var featureFlags: POSFeatureFlagProviding {
        POSFeatureFlagAdaptor()
    }

    var connectivity: POSConnectivityProviding {
        POSConnectivityAdaptor()
    }

    var externalNavigation: POSExternalNavigationProviding {
        POSExternalNavigationAdaptor()
    }

    var externalViews: POSExternalViewProviding {
        POSExternalViewAdaptor()
    }
}

// MARK: - Individual Service Adaptors

private struct POSAnalyticsAdaptor: POSAnalyticsProviding {
    func track(event: WooAnalyticsEvent) {
        ServiceLocator.analytics.track(event: event)
    }

    func track(_ stat: WooAnalyticsStat) {
        track(stat, parameters: [:])
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:]) {
        ServiceLocator.analytics.track(stat, withProperties: parameters)
    }

    func track(_ stat: WooAnalyticsStat, parameters: [String: WooAnalyticsEventPropertyType] = [:], error: Error) {
        ServiceLocator.analytics.track(stat, properties: parameters, error: error)
    }
}

private struct POSCurrencySettingsAdaptor: POSCurrencySettingsProviding {
    var currencySettings: CurrencySettings {
        ServiceLocator.currencySettings
    }
}

private struct POSFeatureFlagAdaptor: POSFeatureFlagProviding {
    func isFeatureFlagEnabled(_ flag: FeatureFlag) -> Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(flag)
    }
}

private struct POSConnectivityAdaptor: POSConnectivityProviding {
    var connectivityObserver: ConnectivityObserver {
        ServiceLocator.connectivityObserver
    }
}

private struct POSExternalNavigationAdaptor: POSExternalNavigationProviding {
    func navigateToCreateOrder() {
        AppDelegate.shared.tabBarController?.navigate(to: OrdersDestination.createOrder)
    }
}

private struct POSExternalViewAdaptor: POSExternalViewProviding {
    func createSupportFormView(isPresented: Binding<Bool>, sourceTag: String) -> AnyView {
        AnyView(
            SupportForm(isPresented: isPresented,
                        viewModel: SupportFormViewModel(sourceTag: sourceTag,
                                                        defaultSite: ServiceLocator.stores.sessionManager.defaultSite))
        )
    }

    func createCouponCreationView(discountType: Coupon.DiscountType,
                                  showTypeSelection: Binding<Bool>,
                                  onSuccess: @escaping (Coupon) -> Void,
                                  dismissHandler: @escaping () -> Void,
                                  onDisappear: @escaping () -> Void) -> AnyView {
        AnyView(POSCouponCreationViewAdaptor(
            discountType: discountType,
            showTypeSelection: showTypeSelection,
            onSuccess: onSuccess,
            dismissHandler: dismissHandler,
            onDisappear: onDisappear
        ))
    }

    func createDiscountTypeSelectionSheet(isPresented: Binding<Bool>,
                                          title: String,
                                          cancelButtonTitle: String,
                                          onSelection: @escaping (Coupon.DiscountType) -> Void) -> AnyView {
        AnyView(POSDiscountTypeSelectionSheetAdaptor(
            isPresented: isPresented,
            title: title,
            cancelButtonTitle: cancelButtonTitle,
            onSelection: onSelection
        ))
    }

    func createWCWebView(adminUrl: URL, completion: @escaping () -> Void) -> AnyView {
        AnyView(WCSettingsWebView(adminUrl: adminUrl, completion: completion))
    }
}
