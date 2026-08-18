import Foundation
import UIKit
import Yosemite
import AutomatticTracks
import WordPressShared
import protocol WooFoundation.AnalyticsProvider
import WooFoundationCore

public enum POSAnalyticsEntryPoint: String {
    case posTab = "pos_tab"
    case autoReopen = "auto_reopen"
}

public class TracksProvider: NSObject, AnalyticsProvider {

    /// `TracksServiceExecutor` ensures that we access the Tracks service on a background queue, while always creating the service on the main thread.
    private enum TracksServiceExecutor {
        private static let contextManager = TracksContextManager()

        private static let service: TracksService = {
            let service = TracksService(contextManager: contextManager)!
            service.eventNamePrefix = Constants.eventNamePrefix
            return service
        }()

        private static let queue = DispatchQueue(label: "com.woocommerce.TracksProvider")

        /// Keep lazy `TracksService` construction off the serialization queue while still serializing service use.
        static func enqueue(_ operation: @escaping (TracksService) -> Void) {
            let enqueue: (TracksService) -> Void = { tracksService in
                queue.async {
                    operation(tracksService)
                }
            }

            if Thread.isMainThread {
                enqueue(service)
            } else {
                DispatchQueue.main.async {
                    enqueue(service)
                }
            }
        }
    }

    private static var isPOSModeActive: Bool = false

    private static var posEntryPoint: POSAnalyticsEntryPoint?

    static var activePOSEntryPoint: POSAnalyticsEntryPoint? {
        isPOSModeActive ? posEntryPoint : nil
    }

    let deviceTypeForAnalytics = UIDevice.current.userInterfaceIdiom.deviceTypeForAnalytics

    public static func setPOSMode(_ active: Bool) {
        isPOSModeActive = active
        if active == false {
            posEntryPoint = nil
        }
    }

    public static func setPOSEntryPoint(_ entryPoint: POSAnalyticsEntryPoint) {
        posEntryPoint = entryPoint
    }
}

extension TracksProvider {
    /// Read on the main thread only; UIKit trait reads are main-thread bound. Off the main thread
    /// (background BGTask/push events, where layout is irrelevant) it returns `.unspecified`, which
    /// `addHorizontalSizeClass(to:sizeClass:)` skips.
    func currentHorizontalSizeClass() -> UIUserInterfaceSizeClass {
        guard Thread.isMainThread else {
            return .unspecified
        }
        return UIApplication.wooKeyWindow?.traitCollection.horizontalSizeClass ?? .unspecified
    }

    /// Adds `horizontal_size_class` to the event's properties when a concrete layout is known,
    /// without overwriting a value the event already provides.
    ///
    func addHorizontalSizeClass(to properties: [AnyHashable: Any]?,
                                sizeClass: UIUserInterfaceSizeClass) -> [AnyHashable: Any]? {
        guard sizeClass != .unspecified else {
            return properties
        }

        var decoratedProperties = properties ?? [:]
        guard decoratedProperties[Constants.horizontalSizeClassKey] == nil else {
            return decoratedProperties
        }

        decoratedProperties[Constants.horizontalSizeClassKey] = sizeClass.nameForAnalytics
        return decoratedProperties
    }

    func addPointOfSaleProperties(to properties: [AnyHashable: Any]?,
                                  deviceType: String,
                                  entryPoint: POSAnalyticsEntryPoint?) -> [AnyHashable: Any] {
        var decoratedProperties = properties ?? [:]
        decoratedProperties[Constants.deviceTypeKey] = deviceType

        if let entryPoint {
            decoratedProperties[Constants.entryPointKey] = entryPoint.rawValue
        }

        return decoratedProperties
    }
}


// MARK: - AnalyticsProvider Conformance
//
public extension TracksProvider {
    func refreshUserData(completion: @escaping () -> Void) {
        switchTracksUsersIfNeeded(completion: completion)
        refreshTracksMetadata()
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        let carriesPOSProperties = carriesPointOfSaleProperties(eventName)
        let eventName = needsPointOfSaleNamePrefix(eventName) ? Constants.pointOfSaleEventNamePrefix + eventName : eventName
        var properties = addHorizontalSizeClass(to: properties, sizeClass: currentHorizontalSizeClass())
        if carriesPOSProperties {
            properties = addPointOfSaleProperties(to: properties,
                                                  deviceType: deviceTypeForAnalytics,
                                                  entryPoint: Self.activePOSEntryPoint)
        }
        Self.TracksServiceExecutor.enqueue { tracksService in
            if let properties {
                guard tracksService.trackEventName(eventName, withCustomProperties: properties) else {
                    return DDLogError("🔴 Error tracking \(eventName) with properties: \(properties)")
                }

                let keyValuePairs = properties
                    .map { key, value in
                        "\(key): \(value)"
                    }
                    .joined(separator: ", ")

                DDLogInfo("🔵 Tracked \(eventName), properties: [\(keyValuePairs)]")
            } else {
                tracksService.trackEventName(eventName)
                DDLogInfo("🔵 Tracked \(eventName)")
            }
        }
    }

    func clearEvents() {
        Self.TracksServiceExecutor.enqueue { tracksService in
            tracksService.clearQueuedEvents()
        }
    }

    /// When a user opts-out, wipe data
    ///
    func clearUsers() {
        guard ServiceLocator.analytics.userHasOptedIn else {
            // To be safe, nil out the anonymousUserID guid so a fresh one is regenerated
            UserDefaults.standard[.defaultAnonymousID] = nil
            UserDefaults.standard[.analyticsUsername] = nil
            let anonymousUserID = ServiceLocator.stores.sessionManager.anonymousUserID
            Self.TracksServiceExecutor.enqueue { tracksService in
                tracksService.switchToAnonymousUser(withAnonymousID: anonymousUserID)
            }
            return
        }

        switchTracksUsersIfNeeded()
    }
}


// MARK: - Private Helpers
//
private extension TracksProvider {
    func switchTracksUsersIfNeeded(completion: @escaping () -> Void = {}) {
        let currentAnalyticsUsername = UserDefaults.standard[.analyticsUsername] as? String ?? ""
        let anonymousID = ServiceLocator.stores.sessionManager.anonymousUserID
        if ServiceLocator.stores.isAuthenticated,
           let account = ServiceLocator.stores.sessionManager.defaultAccount,
           case let .wpcom(_, authToken, _) = ServiceLocator.stores.sessionManager.defaultCredentials {
            if currentAnalyticsUsername.isEmpty {
                // No previous username logged
                UserDefaults.standard[.analyticsUsername] = account.username
                Self.TracksServiceExecutor.enqueue { tracksService in
                    tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                           userID: String(account.userID),
                                                           wpComToken: authToken,
                                                           skipAliasEventCreation: false)
                    completion()
                }
            } else if currentAnalyticsUsername == account.username {
                // Username did not change - just make sure Tracks client has it
                Self.TracksServiceExecutor.enqueue { tracksService in
                    tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                           userID: String(account.userID),
                                                           wpComToken: authToken,
                                                           skipAliasEventCreation: true)
                    completion()
                }
            } else {
                // Username changed for some reason - switch back to anonymous first
                Self.TracksServiceExecutor.enqueue { tracksService in
                    tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
                    tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                           userID: String(account.userID),
                                                           wpComToken: authToken,
                                                           skipAliasEventCreation: false)
                    completion()
                }
            }
        } else {
            UserDefaults.standard[.analyticsUsername] = nil
            Self.TracksServiceExecutor.enqueue { tracksService in
                tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
                completion()
            }
        }
    }

    private func carriesPointOfSaleProperties(_ eventName: String) -> Bool {
        guard WooAnalyticsStat(rawValue: eventName) != nil else {
            return false
        }

        return needsPointOfSaleNamePrefix(eventName) || eventName.hasPrefix(Constants.pointOfSaleEventNamePrefix)
    }

    private func needsPointOfSaleNamePrefix(_ eventName: String) -> Bool {
        guard let event = WooAnalyticsStat(rawValue: eventName) else {
            DDLogWarn("⚠️ Event not found in WooAnalyticsStat list")
            return false
        }

        let pointOfSaleEventList: Set<WooAnalyticsStat> = [
            // POS-specific events
            WooAnalyticsStat.pointOfSaleLoaded,
            WooAnalyticsStat.pointOfSaleItemsFetched,
            WooAnalyticsStat.pointOfSaleItemsPullToRefresh,
            WooAnalyticsStat.pointOfSaleAddItemToCart,
            WooAnalyticsStat.pointOfSaleItemRemovedFromCart,
            WooAnalyticsStat.pointOfSaleCheckoutTapped,
            WooAnalyticsStat.pointOfSaleBackToCartTapped,
            WooAnalyticsStat.pointOfSaleBackToCheckoutFromCashTapped,
            WooAnalyticsStat.pointOfSaleClearCartTapped,
            WooAnalyticsStat.pointOfSaleExitMenuItemTapped,
            WooAnalyticsStat.pointOfSaleExitConfirmed,
            WooAnalyticsStat.pointOfSaleGetSupportTapped,
            WooAnalyticsStat.pointOfSaleSimpleProductsExplanationDialogShown,
            WooAnalyticsStat.pointOfSaleCreateNewOrderTapped,
            WooAnalyticsStat.pointOfSaleReceiptEmailSendTapped,
            WooAnalyticsStat.pointOfSalePaymentsOnboardingShown,
            WooAnalyticsStat.pointOfSalePaymentsOnboardingDismissed,
            WooAnalyticsStat.pointOfSaleCardReaderConnectionTapped,
            WooAnalyticsStat.pointOfSaleCheckoutTapToPayTapped,
            WooAnalyticsStat.pointOfSaleTapToPayNotAvailable,
            WooAnalyticsStat.pointOfSaleInteractionWithCustomerStarted,
            WooAnalyticsStat.pointOfSaleViewDocsTapped,
            WooAnalyticsStat.pointOfSaleEditReceiptTapped,
            WooAnalyticsStat.receiptPrintTapped,
            WooAnalyticsStat.receiptPrintSuccess,
            WooAnalyticsStat.receiptPrintFailed,
            WooAnalyticsStat.pointOfSaleReaderReadyForCardPayment,
            WooAnalyticsStat.pointOfSaleCashCollectPaymentSuccess,
            WooAnalyticsStat.pointOfSaleCheckoutCashPaymentTapped,
            WooAnalyticsStat.pointOfSaleCashPaymentTapped,
            WooAnalyticsStat.pointOfSaleCashPaymentFailed,
            WooAnalyticsStat.pointOfSaleOtherPaymentMethodsTapped,
            WooAnalyticsStat.pointOfSaleCheckoutScanToPayPaymentTapped,
            WooAnalyticsStat.pointOfSaleScanToPayPaymentTapped,
            WooAnalyticsStat.pointOfSaleScanToPayPaymentFailed,
            WooAnalyticsStat.pointOfSaleScanToPayCollectPaymentSuccess,
            WooAnalyticsStat.pointOfSaleScanToPayPaymentDetectedViaPolling,
            WooAnalyticsStat.pointOfSaleBackToCheckoutFromScanToPayTapped,
            WooAnalyticsStat.pointOfSaleCheckoutMarkAsPaidTapped,
            WooAnalyticsStat.pointOfSaleMarkAsPaidConfirmed,
            WooAnalyticsStat.pointOfSaleMarkAsPaidFailed,
            WooAnalyticsStat.pointOfSaleMarkAsPaidSuccess,
            WooAnalyticsStat.pointOfSaleBackToCheckoutFromMarkAsPaidTapped,
            WooAnalyticsStat.pointOfSaleItemsHeaderTapped,
            WooAnalyticsStat.pointOfSaleCouponsCreateTapped,
            WooAnalyticsStat.pointOfSaleSearchButtonTapped,
            WooAnalyticsStat.pointOfSalePreSearchRecentTermTapped,
            WooAnalyticsStat.pointOfSaleKeyboardDismissedInSearch,
            WooAnalyticsStat.pointOfSaleItemsNextPageLoaded,
            WooAnalyticsStat.pointOfSaleSearchRemoteResultsFetched,
            WooAnalyticsStat.pointOfSaleSearchResultsFetched,
            WooAnalyticsStat.pointOfSaleBarcodeScanningMenuItemTapped,
            WooAnalyticsStat.pointOfSaleBarcodeScanningExplanationDialogShown,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupFlowShown,
            WooAnalyticsStat.pointOfSaleBarcodeScanningSuccess,
            WooAnalyticsStat.pointOfSaleBarcodeScanningFailed,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupScannerSelected,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupNextTapped,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupBackTapped,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupOpenSystemSettingsTapped,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupTestScanSuccess,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupTestScanFailed,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupTestScanTimedOut,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupDismissed,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupRetryTapped,
            WooAnalyticsStat.pointOfSaleBarcodeScannerSetupScannerConnected,
            WooAnalyticsStat.pointOfSaleOrdersMenuItemTapped,
            WooAnalyticsStat.pointOfSaleOrdersListPullToRefresh,
            WooAnalyticsStat.pointOfSaleOrdersListFetched,
            WooAnalyticsStat.pointOfSaleOrdersListNextPageLoaded,
            WooAnalyticsStat.pointOfSaleOrdersListRowTapped,
            WooAnalyticsStat.pointOfSaleOrdersListSearchButtonTapped,
            WooAnalyticsStat.pointOfSaleOrdersListSearchResultsFetched,
            WooAnalyticsStat.pointOfSaleOrderDetailsLoaded,
            WooAnalyticsStat.pointOfSaleOrderDetailsEmailReceiptTapped,
            WooAnalyticsStat.pointOfSaleRefundFlowStarted,
            WooAnalyticsStat.pointOfSaleRefundConfirmTapped,
            WooAnalyticsStat.pointOfSaleRefundProcessingStarted,
            WooAnalyticsStat.pointOfSaleRefundProcessingSuccess,
            WooAnalyticsStat.pointOfSaleRefundProcessingFailed,
            WooAnalyticsStat.pointOfSaleRefundFlowAborted,
            WooAnalyticsStat.pointOfSaleRefundSelectAllTapped,
            // POS-only: emitted from the POS refund preview probe, so it carries the `pos_`
            // prefix like the rest of the POS refund funnel and matches Android's event.
            WooAnalyticsStat.refundServerFlowUnavailable,
            WooAnalyticsStat.pointOfSaleCheckoutOutdatedItemDetectedScreenShown,
            WooAnalyticsStat.pointOfSaleCheckoutOutdatedItemDetectedEditOrderTapped,
            WooAnalyticsStat.pointOfSaleCheckoutOutdatedItemDetectedRemoveTapped,

            // Order
            WooAnalyticsStat.ordersListLoaded,
            WooAnalyticsStat.orderCreationSuccess,
            WooAnalyticsStat.orderCreationFailed,

            // Card Reader Connection
            WooAnalyticsStat.cardReaderDiscoveryFailed,
            WooAnalyticsStat.cardReaderConnectionFailed,
            WooAnalyticsStat.cardReaderConnectionSuccess,
            WooAnalyticsStat.cardReaderDisconnectTapped,
            WooAnalyticsStat.cardReaderLocationPermissionPreAlertShown,
            WooAnalyticsStat.cardReaderLocationPermissionRequiredShown,
            WooAnalyticsStat.cardReaderLocationSuccess,
            WooAnalyticsStat.cardReaderLocationFailure,
            WooAnalyticsStat.cardReaderLocationMissingTapped,

            // Card Reader Software Update
            WooAnalyticsStat.cardReaderSoftwareUpdateTapped,
            WooAnalyticsStat.cardReaderSoftwareUpdateStarted,
            WooAnalyticsStat.cardReaderSoftwareUpdateSuccess,
            WooAnalyticsStat.cardReaderSoftwareUpdateFailed,
            WooAnalyticsStat.cardReaderSoftwareUpdateCancelTapped,
            WooAnalyticsStat.cardReaderSoftwareUpdateCanceled,

            // Card-Present Payments Onboarding
            WooAnalyticsStat.cardPresentOnboardingLearnMoreTapped,
            WooAnalyticsStat.cardPresentOnboardingCompleted,
            WooAnalyticsStat.cardPresentOnboardingNotCompleted,
            WooAnalyticsStat.cardPresentOnboardingStepSkipped,
            WooAnalyticsStat.cardPresentOnboardingCtaTapped,
            WooAnalyticsStat.cardPresentOnboardingCtaFailed,

            // Receipts
            WooAnalyticsStat.receiptEmailTapped,
            WooAnalyticsStat.receiptEmailSuccess,
            WooAnalyticsStat.receiptEmailFailed,

            // Payments
            WooAnalyticsStat.collectPaymentCanceled,
            WooAnalyticsStat.collectPaymentFailed,
            WooAnalyticsStat.collectPaymentSuccess,
            WooAnalyticsStat.collectInteracPaymentSuccess,

            // Coupons
            WooAnalyticsStat.couponSettingEnabled,
            WooAnalyticsStat.couponCreationSuccess,

            // Settings
            WooAnalyticsStat.pointOfSaleSettingsMenuItemTapped,
            WooAnalyticsStat.pointOfSaleSettingsCloseButtonTapped,
            WooAnalyticsStat.pointOfSaleSettingsStoreDetailsTapped,
            WooAnalyticsStat.pointOfSaleSettingsHardwareTapped,
            WooAnalyticsStat.pointOfSaleSettingsHelpTapped,
            WooAnalyticsStat.pointOfSaleEmptyCartSetupScannerTapped,

            // Catalog
            WooAnalyticsStat.pointOfSaleLocalCatalogDownloadingScreenShown,
            WooAnalyticsStat.pointOfSaleLocalCatalogDownloadingScreenExitPosTapped,
            WooAnalyticsStat.pointOfSaleSplashScreenErrorShown,
            WooAnalyticsStat.pointOfSaleSplashScreenRetryTapped,
            WooAnalyticsStat.pointOfSaleLocalCatalogStaleWarningShown,
            WooAnalyticsStat.pointOfSaleLocalCatalogStaleWarningDismissed,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncStarted,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncCompleted,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncFailed,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncSkipped,
            WooAnalyticsStat.pointOfSaleLocalCatalogSunsetWarningShown,
            WooAnalyticsStat.pointOfSaleLocalCatalogSunsetWarningDismissed,
            WooAnalyticsStat.pointOfSaleLocalCatalogBlockedFellBackToRemote
        ]

        // Local catalog events always get pos_ prefix since they're POS-specific features
        // that can run in background regardless of whether POS tab is active
        let localCatalogEventList: Set<WooAnalyticsStat> = [
            WooAnalyticsStat.pointOfSaleLocalCatalogDownloadingScreenShown,
            WooAnalyticsStat.pointOfSaleLocalCatalogDownloadingScreenExitPosTapped,
            WooAnalyticsStat.pointOfSaleSplashScreenErrorShown,
            WooAnalyticsStat.pointOfSaleSplashScreenRetryTapped,
            WooAnalyticsStat.pointOfSaleLocalCatalogStaleWarningShown,
            WooAnalyticsStat.pointOfSaleLocalCatalogStaleWarningDismissed,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncStarted,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncCompleted,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncFailed,
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncSkipped,
            WooAnalyticsStat.pointOfSaleLocalCatalogSunsetWarningShown,
            WooAnalyticsStat.pointOfSaleLocalCatalogSunsetWarningDismissed,
            WooAnalyticsStat.pointOfSaleLocalCatalogBlockedFellBackToRemote
        ]

        // Apply prefix if: (POS mode is active AND event is in the list) OR event is a local catalog event
        return (Self.isPOSModeActive && pointOfSaleEventList.contains(event)) || localCatalogEventList.contains(event)
    }

    func refreshTracksMetadata() {
        DDLogInfo("♻️ Refreshing tracks metadata...")
        let readUIKitAndApply = {
            let voiceOver = UIAccessibility.isVoiceOverRunning
            let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            Self.TracksServiceExecutor.enqueue { tracksService in
                tracksService.userProperties.removeAllObjects()
                tracksService.userProperties.addEntries(from: [
                    UserProperties.platformKey: "iOS",
                    UserProperties.voiceOverKey: voiceOver,
                    UserProperties.rtlKey: isRTL
                ])
            }
        }
        if Thread.isMainThread {
            readUIKitAndApply()
        } else {
            DispatchQueue.main.async { readUIKitAndApply() }
        }
    }
}


// MARK: - Constants!
//
private extension TracksProvider {

    enum Constants {
        static let eventNamePrefix = "woocommerceios"
        static let pointOfSaleEventNamePrefix = "pos_"
        static let horizontalSizeClassKey = "horizontal_size_class"
        static let deviceTypeKey = "device_type"
        static let entryPointKey = "entry_point"
    }

    enum UserProperties {
        static let platformKey          = "platform"
        static let voiceOverKey         = "accessibility_voice_over_enabled"
        static let rtlKey               = "is_rtl_language"
    }
}

extension TracksProvider: WPAnalyticsTracker {
    public func trackString(_ event: String?) {
        trackString(event, withProperties: nil)
    }

    public func trackString(_ event: String?, withProperties properties: [AnyHashable: Any]?) {
        guard let eventName = event else {
            DDLogInfo("🔴 Attempted to track an event without name.")
            return
        }

        track(eventName, withProperties: properties)
    }

    public func track(_ stat: WPAnalyticsStat) {
        // no op.
        track(stat, withProperties: nil)
    }

    public func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        // no op
    }
}
