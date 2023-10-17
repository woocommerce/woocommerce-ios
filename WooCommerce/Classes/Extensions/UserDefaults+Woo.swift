import Foundation



// MARK: - WooCommerce UserDefaults Keys
//
extension UserDefaults {
    enum Key: String {
        case defaultCredentialsType
        case defaultAccountID
        case defaultUsername
        case defaultSiteAddress
        case defaultStoreID
        case defaultStoreName
        case defaultStoreCurrencySettings
        case defaultAnonymousID
        case defaultRoles
        case deviceID
        case deviceToken
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
        case shouldHideStoreOnboardingTaskList
        case storePhoneNumber
        case siteIDsWithSnapshotTracked
        case hasSavedPrivacyBannerSettings
        case usedProductDescriptionAI

        // Tooltip
        case hasDismissedWriteWithAITooltip
        case numberOfTimesWriteWithAITooltipIsShown

        // Blaze highlight banner
        case hasDismissedBlazeBanner

        // Store profiler answers
        case storeProfilerAnswers

        // AI prompt tone
        case aiPromptTone

        // Celebration view after Blaze campaign creation
        case hasDisplayedTipAfterBlazeCampaignCreation
    }
}

extension UserDefaults {
    /// User defaults instance ready to be shared between extensions of the same group.
    ///
    static let group = UserDefaults(suiteName: WooConstants.sharedUserDefaultsSuiteName)
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

// MARK: - Check for Blaze banner visibility
extension UserDefaults {
    /// Checks of the Blaze banner has been dismissed for a site.
    /// - Parameters:
    ///     - siteID: ID of the site to be checked for the Blaze banner visibility.
    ///
    func hasDismissedBlazeBanner(for siteID: Int64) -> Bool {
        let hasDismissed = self[.hasDismissedBlazeBanner] as? [String: Bool]
        let idAsString = "\(siteID)"
        return hasDismissed?[idAsString] == true
    }

    /// Set the Blaze banner to be dismissed for a site.
    /// - Parameters:
    ///     - siteID: ID of the site whose Blaze banner to be dismissed.
    ///
    func setBlazeBannerDismissed(for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var hasDismissed = self[.hasDismissedBlazeBanner] as? [String: Bool] {
            hasDismissed[idAsString] = true
            self[.hasDismissedBlazeBanner] = hasDismissed
        } else {
            self[.hasDismissedBlazeBanner] = [idAsString: true]
        }
    }
}
