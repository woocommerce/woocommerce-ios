import Foundation
import Yosemite
import AutomatticTracks
import WordPressShared
import protocol WooFoundation.AnalyticsProvider
import WooFoundationCore

public class TracksProvider: NSObject, AnalyticsProvider {
    private static let contextManager: TracksContextManager = TracksContextManager()

    private static let tracksService: TracksService = {
        let tracksService = TracksService(contextManager: contextManager)!
        tracksService.eventNamePrefix = Constants.eventNamePrefix
        return tracksService
    }()

    private static var isPOSModeActive: Bool = false

    public static func setPOSMode(_ active: Bool) {
        isPOSModeActive = active
    }
}


// MARK: - AnalyticsProvider Conformance
//
public extension TracksProvider {
    func refreshUserData() {
        switchTracksUsersIfNeeded()
        refreshTracksMetadata()
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        let eventName = decorateEventNameForPOSIfNeeded(eventName)
        if let properties {
            guard Self.tracksService.trackEventName(eventName, withCustomProperties: properties) else {
                return DDLogError("🔴 Error tracking \(eventName) with properties: \(properties)")
            }

            let keyValuePairs = properties
                .map { key, value in
                    "\(key): \(value)"
                }
                .joined(separator: ", ")

            DDLogInfo("🔵 Tracked \(eventName), properties: [\(keyValuePairs)]")
        } else {
            Self.tracksService.trackEventName(eventName)
            DDLogInfo("🔵 Tracked \(eventName)")
        }
    }

    func clearEvents() {
        Self.tracksService.clearQueuedEvents()
    }

    /// When a user opts-out, wipe data
    ///
    func clearUsers() {
        guard ServiceLocator.analytics.userHasOptedIn else {
            // To be safe, nil out the anonymousUserID guid so a fresh one is regenerated
            UserDefaults.standard[.defaultAnonymousID] = nil
            UserDefaults.standard[.analyticsUsername] = nil
            Self.tracksService.switchToAnonymousUser(withAnonymousID: ServiceLocator.stores.sessionManager.anonymousUserID)
            return
        }

        switchTracksUsersIfNeeded()
    }
}


// MARK: - Private Helpers
//
private extension TracksProvider {
    func switchTracksUsersIfNeeded() {
        let currentAnalyticsUsername = UserDefaults.standard[.analyticsUsername] as? String ?? ""
        let anonymousID = ServiceLocator.stores.sessionManager.anonymousUserID
        if ServiceLocator.stores.isAuthenticated,
           let account = ServiceLocator.stores.sessionManager.defaultAccount,
           case let .wpcom(_, authToken, _) = ServiceLocator.stores.sessionManager.defaultCredentials {
            if currentAnalyticsUsername.isEmpty {
                // No previous username logged
                UserDefaults.standard[.analyticsUsername] = account.username
                Self.tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                             userID: String(account.userID),
                                                             wpComToken: authToken,
                                                             skipAliasEventCreation: false)
            } else if currentAnalyticsUsername == account.username {
                // Username did not change - just make sure Tracks client has it
                Self.tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                             userID: String(account.userID),
                                                             wpComToken: authToken,
                                                             skipAliasEventCreation: true)
            } else {
                // Username changed for some reason - switch back to anonymous first
                Self.tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
                Self.tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                             userID: String(account.userID),
                                                             wpComToken: authToken,
                                                             skipAliasEventCreation: false)
            }
        } else {
            UserDefaults.standard[.analyticsUsername] = nil
            Self.tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
        }
    }

    private func decorateEventNameForPOSIfNeeded(_ eventName: String) -> String {
        guard let event = WooAnalyticsStat(rawValue: eventName) else {
            DDLogWarn("⚠️ Event not found in WooAnalyticsStat list")
            return eventName
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
            WooAnalyticsStat.pointOfSaleInteractionWithCustomerStarted,
            WooAnalyticsStat.pointOfSaleViewDocsTapped,
            WooAnalyticsStat.pointOfSaleReaderReadyForCardPayment,
            WooAnalyticsStat.pointOfSaleCashCollectPaymentSuccess,
            WooAnalyticsStat.pointOfSaleCheckoutCashPaymentTapped,
            WooAnalyticsStat.pointOfSaleCashPaymentTapped,
            WooAnalyticsStat.pointOfSaleCashPaymentFailed,
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
            WooAnalyticsStat.pointOfSaleCheckoutOutdatedItemDetectedScreenShown,
            WooAnalyticsStat.pointOfSaleCheckoutOutdatedItemDetectedEditOrderTapped,
            WooAnalyticsStat.pointOfSaleCheckoutOutdatedItemDetectedRemoveTapped,

            // Bookings
            WooAnalyticsStat.pointOfSaleBookingsMenuItemTapped,
            WooAnalyticsStat.pointOfSaleBookingsListSearchButtonTapped,
            WooAnalyticsStat.pointOfSaleBookingsListBookingTapped,
            WooAnalyticsStat.pointOfSaleBookingCancelled,
            WooAnalyticsStat.pointOfSaleBookingAddNoteTapped,
            WooAnalyticsStat.pointOfSaleBookingIssueRefundTapped,
            WooAnalyticsStat.pointOfSaleBookingViewOrderTapped,
            WooAnalyticsStat.pointOfSaleBookingAttendanceChanged,

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
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncSkipped
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
            WooAnalyticsStat.pointOfSaleLocalCatalogSyncSkipped
        ]

        // Apply prefix if: (POS mode is active AND event is in the list) OR event is a local catalog event
        guard (Self.isPOSModeActive && pointOfSaleEventList.contains(event)) || localCatalogEventList.contains(event) else {
            return eventName
        }
        let prefix = "pos_"
        return "\(prefix)\(eventName)"
    }

    func refreshTracksMetadata() {
        DDLogInfo("♻️ Refreshing tracks metadata...")
        var userProperties = [String: Any]()
        userProperties[UserProperties.platformKey] = "iOS"
        userProperties[UserProperties.voiceOverKey] = UIAccessibility.isVoiceOverRunning
        userProperties[UserProperties.rtlKey] = (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
        Self.tracksService.userProperties.removeAllObjects()
        Self.tracksService.userProperties.addEntries(from: userProperties)
    }
}


// MARK: - Constants!
//
private extension TracksProvider {

    enum Constants {
        static let eventNamePrefix = "woocommerceios"
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
