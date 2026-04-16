import SwiftUI
import class NetworkingCore.AlamofireNetwork
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
import protocol PointOfSale.POSPermissionProviding

final class POSServiceLocatorAdaptor: POSDependencyProviding {
    private let posNetwork: AlamofireNetwork?

    init(posNetwork: AlamofireNetwork? = nil) {
        self.posNetwork = posNetwork
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

    private lazy var _permissions: POSPermissionProviding = {
        let sessionManager = ServiceLocator.stores.sessionManager
        let userID = sessionManager.defaultAccount?.userID ?? 0
        let displayName = sessionManager.defaultAccount?.displayName ?? ""
        let siteID = sessionManager.defaultSite?.siteID ?? 0
        return POSPermissionAdaptor.createProvider(
            siteID: siteID,
            userID: userID,
            displayName: displayName,
            posNetwork: posNetwork
        )
    }()

    var permissions: POSPermissionProviding {
        _permissions
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
                                  approvalToken: String?,
                                  onSuccess: @escaping (Coupon) -> Void,
                                  dismissHandler: @escaping () -> Void,
                                  onDisappear: @escaping () -> Void) -> AnyView {
        // TODO: Pass approvalToken to the coupon creation form so it includes _pos_approval in the API request.
        // Requires backend to add publish_shop_coupons to APPROVABLE_ACTIONS.
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

    func createAuthenticatedWebView(url: URL, title: String, completion: @escaping () -> Void) -> AnyView {
        AnyView(WCAuthenticatedWebView(url: url, title: title, completion: completion))
    }
}
