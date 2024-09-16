import Yosemite
import protocol Storage.StorageManagerType
import Combine

protocol BlazeLocalNotificationScheduler {
    func observeNotificationUserResponse()
    func scheduleNoCampaignReminder() async
    func scheduleAbandonedCreationReminder() async
    func cancelAbandonedCreationReminder() async
}

/// Handles the scheduling of Blaze local notifications.
///
final class DefaultBlazeLocalNotificationScheduler: BlazeLocalNotificationScheduler {
    private let siteID: Int64
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let scheduler: LocalNotificationScheduler
    private let userDefaults: UserDefaults
    private let pushNotesManager: PushNotesManager
    private var subscriptions: Set<AnyCancellable> = []
    private let blazeEligibilityChecker: BlazeEligibilityCheckerProtocol

    /// Blaze campaign ResultsController.
    private lazy var blazeCampaignResultsController: ResultsController<StorageBlazeCampaignListItem> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptorByStartTime = NSSortDescriptor(keyPath: \StorageBlazeCampaignListItem.startTime,
                                                         ascending: false)
        let resultsController = ResultsController<StorageBlazeCampaignListItem>(storageManager: storageManager,
                                                                                matching: predicate,
                                                                                sortedBy: [sortDescriptorByStartTime])
        return resultsController
    }()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         userDefaults: UserDefaults = .standard,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager,
         blazeEligibilityChecker: BlazeEligibilityCheckerProtocol = BlazeEligibilityChecker()) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.pushNotesManager = pushNotesManager
        self.scheduler = LocalNotificationScheduler(pushNotesManager: pushNotesManager)
        self.userDefaults = userDefaults
        self.blazeEligibilityChecker = blazeEligibilityChecker
    }

    /// Observes user responses to local notification and updates user defaults
    ///
    func observeNotificationUserResponse() {
        pushNotesManager.localNotificationUserResponses
            .sink { [weak self] response in
                guard let self else {
                    return
                }

                switch response.notification.request.identifier {
                case LocalNotification.Scenario.blazeAbandonedCampaignCreationReminder.identifier:
                    userDefaults.setBlazeAbandonedCampaignCreationReminderOpened(true)
                case LocalNotification.Scenario.blazeNoCampaignReminder.identifier:
                    userDefaults.setBlazeNoCampaignReminderOpened(true)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    /// Starts observing campaigns from storage and schedules no campaign local notification
    ///
    func scheduleNoCampaignReminder() async {
        guard await isEligibleForBlaze() else {
            DDLogDebug("Blaze: Store not eligible for Blaze. Don't schedule local notification.")
            await scheduler.cancel(scenario: .blazeNoCampaignReminder)
            return
        }

        observeStorageAndScheduleNotifications()
    }

    /// Schedules abandoned Blaze campaign creation local notification if applicable
    ///
    @MainActor
    func scheduleAbandonedCreationReminder() async {
        guard await isEligibleForBlaze() else {
            DDLogDebug("Blaze: Store not eligible for Blaze. Don't schedule abandoned campaign creation local notification.")
            await scheduler.cancel(scenario: .blazeAbandonedCampaignCreationReminder)
            return
        }

        guard !userDefaults.blazeAbandonedCampaignCreationReminderOpened() else {
            DDLogDebug("Blaze: User interacted with a previously scheduled abandoned campaign creation local notification. Don't schedule again.")
            return
        }

        guard let notificationTime = Calendar.current.date(byAdding: .hour,
                                                           value: Constants.AbandonedCampaignCreationReminder.hoursDurationForNotification,
                                                           to: Date.now) else {
            return DDLogDebug("Blaze: Failed calculating notification time for abandoned campaign creation local notification.")
        }

        let notification = LocalNotification(scenario: LocalNotification.Scenario.blazeAbandonedCampaignCreationReminder,
                                             userInfo: [Constants.siteIDKey: siteID])
        await scheduler.cancel(scenario: .blazeAbandonedCampaignCreationReminder)
        DDLogDebug("Blaze: Schedule abandoned campaign creation local notification for date \(notificationTime).")
        await scheduler.schedule(notification: notification,
                                 trigger: UNCalendarNotificationTrigger(dateMatching: notificationTime.dateAndTimeComponents(),
                                                                        repeats: false),
                                 remoteFeatureFlag: nil)
    }

    /// Cancels abandoned Blaze campaign creation local notification
    ///
    @MainActor
    func cancelAbandonedCreationReminder() async {
        await scheduler.cancel(scenario: .blazeAbandonedCampaignCreationReminder)
    }
}

private extension DefaultBlazeLocalNotificationScheduler {
    func isEligibleForBlaze() async -> Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }
        return await blazeEligibilityChecker.isSiteEligible(site)
    }

    /// Performs initial fetch from storage and updates results.
    func observeStorageAndScheduleNotifications() {
        blazeCampaignResultsController.onDidChangeContent = { [weak self] in
            self?.scheduleLocalNotificationIfNeeded()
        }
        blazeCampaignResultsController.onDidResetContent = { [weak self] in
            self?.scheduleLocalNotificationIfNeeded()
        }

        do {
            try blazeCampaignResultsController.performFetch()
            scheduleLocalNotificationIfNeeded()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func scheduleLocalNotificationIfNeeded() {
        guard !userDefaults.blazeNoCampaignReminderOpened() else {
            DDLogDebug("Blaze: User interacted with a previously scheduled no campaign local notification. Don't schedule again.")
            return
        }

        let campaigns = blazeCampaignResultsController.fetchedObjects
        guard campaigns.contains(where: { $0.isEvergreen && $0.isActive}) == false else {
            Task { @MainActor in
                await scheduler.cancel(scenario: .blazeNoCampaignReminder)
            }
            return DDLogDebug("Blaze: An active evergreen campaign is present. No need to schedule a no campaign local notification.")
        }

        let latestEndTime = campaigns
            .filter({ $0.isEvergreen == false })
            .map({ campaign -> Date? in
                guard let startTime = campaign.startTime else {
                    return nil
                }
                let durationDays = Int(campaign.durationDays)
                return Calendar.current.date(byAdding: .day, value: durationDays, to: startTime)
            })
            .compactMap { $0 }
            .max()

        guard let latestEndTime else {
            return DDLogDebug("Blaze: Failed calculating latest campaign end time.")
        }

        guard let notificationTime = Calendar.current.date(byAdding: .day,
                                                           value: Constants.NoCampaignReminder.daysDurationForNotification,
                                                           to: latestEndTime) else {
            return DDLogDebug("Blaze: Failed calculating no campaign notification time from latest campaign end time.")
        }

        guard notificationTime > Date.now else {
            return DDLogDebug("Blaze: Calculated no campaign notification time already passed.")
        }

        Task { @MainActor in
            let notification = LocalNotification(scenario: LocalNotification.Scenario.blazeNoCampaignReminder,
                                                 userInfo: [Constants.siteIDKey: siteID])
            await scheduler.cancel(scenario: .blazeNoCampaignReminder)
            DDLogDebug("Blaze: Schedule no campaign local notification for date \(notificationTime).")
            await scheduler.schedule(notification: notification,
                                     trigger: UNCalendarNotificationTrigger(dateMatching: notificationTime.dateAndTimeComponents(),
                                                                            repeats: false),
                                     remoteFeatureFlag: nil)
        }
    }
}

private extension DefaultBlazeLocalNotificationScheduler {
    enum Constants {
        static let siteIDKey = "site_id"

        enum NoCampaignReminder {
            static let daysDurationForNotification = 30
        }

        enum AbandonedCampaignCreationReminder {
            static let hoursDurationForNotification = 24
        }
    }
}

// MARK: - User defaults helpers
//
extension UserDefaults {
    /// Returns Blaze no campaign reminder Notification opened bool value
    ///
    func blazeNoCampaignReminderOpened() -> Bool {
        guard let value = self[.blazeNoCampaignReminderOpened] as? Bool else {
            return false
        }
        return value
    }

    /// Stores the Blaze no campaign reminder Notification opened bool value
    ///
    func setBlazeNoCampaignReminderOpened(_ shown: Bool) {
        self[.blazeNoCampaignReminderOpened] = shown
    }

    /// Returns Blaze abandoned campaign creation Notification opened bool value
    ///
    func blazeAbandonedCampaignCreationReminderOpened() -> Bool {
        guard let value = self[.blazeAbandonedCampaignCreationReminderOpened] as? Bool else {
            return false
        }
        return value
    }

    /// Stores the Blaze abandoned campaign creation Notification opened bool value
    ///
    func setBlazeAbandonedCampaignCreationReminderOpened(_ shown: Bool) {
        self[.blazeAbandonedCampaignCreationReminderOpened] = shown
    }
}
