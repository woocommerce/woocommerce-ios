import Foundation



// MARK: - WooCommerce UserDefaults Keys
//
extension UserDefaults {
    enum Key: String {
        case applicationPasswordUnsupportedList
        case defaultCredentialsType
        case defaultAccountID
        case defaultUsername
        case defaultSiteAddress
        case defaultStoreID
        case defaultStoreName
        case defaultStoreCurrencySettings
        case defaultAnonymousID
        case defaultRoles
        case errorLoginSiteAddress
        case hasFinishedOnboarding
        case installationDate
        case userOptedInAnalytics
        case userOptedInCrashLogging = "userOptedInCrashlytics"
        case versionOfLastRun
        case analyticsUsername
        case notificationsLastSeenTime
        case notificationsMarkAsReadCount
        case completedAllStoreOnboardingTasks
        case storePhoneNumber
        case siteIDsWithSnapshotTracked
        case hasSavedPrivacyBannerSettings
        case usedProductDescriptionAI
        case lastWidgetSnapshot

        // Tooltip
        case hasDismissedWriteWithAITooltip
        case numberOfTimesWriteWithAITooltipIsShown
        case hasDismissedWooAIAssistantEarlyAccessTooltip

        // Store profiler answers
        case storeProfilerAnswers

        // AI prompt tone
        case aiPromptTone

        // Theme installation
        case themesPendingInstall

        // Watch
        case watchDependencies

        // Background Task Refresh
        case latestBackgroundOrderSyncDate
        case lastBackgroundRefreshCompletionTime

        // Blaze Local notification
        case blazeNoCampaignReminderOpened
        case blazeAbandonedCampaignCreationReminderOpened

        // Selected campaign objective saved for future campaigns
        case blazeSelectedCampaignObjective

        // Whether the site is suspended on WordPress.com and can't be connected using Jetpack
        //
        case wpcomSiteSuspended

        // Tap to Pay awareness moment
        case tapToPayAwarenessMomentPresented
        case tapToPayAwarenessMomentFirstLaunchCompleted

        // Hide stores from store picker
        case hiddenStoreIDs

        // Application passwords experiment remote FF cached value
        case applicationPasswordsExperimentRemoteFFValue

        // CIAB Bookings tab availability
        case ciabBookingsTabAvailable

        /// Whether WPCom connection suggestion for Woo-driven push notifications is hidden
        case hideWPComConnectionOnDashboard

        /// Pending flow for magic link: notification setup or Jetpack setup
        case pendingMagicLinkFlow

        /// Debug override for the minimum WooCommerce plugin version required for WPCom connection setup
        case debugMinWooVersionForSelfDrivenPushNotifications

        /// Whether configurable store stats widgets are enabled
        case configurableStoreStatsWidgetsEnabled

        /// Sites available for selection in the configurable store stats widget picker
        case widgetSelectableSites

        /// Per-site currency settings fetched lazily by the Store Stats widget extension
        case widgetSiteCurrencySettingsCache
    }
}

extension UserDefaults {
    /// User defaults instance ready to be shared between extensions of the same group.
    ///
    static let group = UserDefaults(suiteName: WooConstants.sharedUserDefaultsSuiteName)
}

extension UserDefaults {
    /// Whether configurable store stats widgets are enabled.
    ///
    var configurableStoreStatsWidgetsEnabled: Bool {
        get {
            object(forKey: .configurableStoreStatsWidgetsEnabled) ?? false
        }
        set {
            set(newValue, forKey: .configurableStoreStatsWidgetsEnabled)
        }
    }
}


// MARK: - Convenience Methods
//
extension UserDefaults {

    /// Returns the Object (if any) associated with the specified Key.
    ///
    func object<T>(forKey key: Key) -> T? {
        return value(forKey: key.rawValue) as? T
    }

    /// Stores the Key/Value Pair.
    ///
    func set<T>(_ value: T?, forKey key: Key) {
        set(value, forKey: key.rawValue)
    }

    /// Nukes any object associated with the specified Key.
    ///
    func removeObject(forKey key: Key) {
        removeObject(forKey: key.rawValue)
    }

    /// Indicates if there's an entry for the specified Key.
    ///
    func containsObject(forKey key: Key) -> Bool {
        return value(forKey: key.rawValue) != nil
    }

    /// Subscript Accessible via our new Key type!
    ///
    subscript<T>(key: Key) -> T? {
        get {
            return value(forKey: key.rawValue) as? T
        }
        set {
            set(newValue, forKey: key.rawValue)
        }
    }

    /// Subscript: "Type Inference Fallback". To be used whenever the type cannot be automatically inferred!
    ///
    subscript(key: Key) -> Any? {
        get {
            return value(forKey: key.rawValue)
        }
        set {
            set(newValue, forKey: key.rawValue)
        }
    }
}
