import Yosemite
import protocol Storage.StorageManagerType
import Combine

protocol BlazeLocalNotificationScheduler {
    func scheduleNotifications() async
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

    /// Starts observing campaigns from storage and schedules local notification
    ///
    func scheduleNotifications() async {
        guard await isEligibleForBlaze() else {
            DDLogDebug("Blaze: Store not eligible for Blaze. Don't schedule local notification.")
            return
        }

        observeStorageAndScheduleNotifications()

        pushNotesManager.localNotificationUserResponses
            .sink { [weak self] response in
                guard let self,
                      response.notification.request.identifier == LocalNotification.Scenario.blazeNoCampaignReminder.identifier,
                      let siteID = response.notification.request.content.userInfo[Constants.siteIDKey] as? Int64 else {
                    return
                }

                userDefaults.setBlazeNoCampaignReminderOpened(true)
            }
            .store(in: &subscriptions)
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
            return DDLogDebug("Blaze: An active evergreen campaign is present. No need to schedule a local notification.")
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

        guard let latestEndTime,
              let notificationTime = Calendar.current.date(byAdding: .day, value: Constants.daysDurationNoCampaignReminderNotification, to: latestEndTime) else {
            return DDLogDebug("Blaze: Failed calculating notification time from latest campaign end time.")
        }

        guard notificationTime > Date.now else {
            return DDLogDebug("Blaze: Calculated notification time already passed.")
        }

        Task { @MainActor in
            let notification = LocalNotification(scenario: LocalNotification.Scenario.blazeNoCampaignReminder,
                                                 userInfo: [Constants.siteIDKey: siteID])
            await scheduler.cancel(scenario: .blazeNoCampaignReminder)
            DDLogDebug("Blaze: Schedule local notification for date \(notificationTime).")
            await scheduler.schedule(notification: notification,
                                     trigger: UNCalendarNotificationTrigger(dateMatching: notificationTime.dateAndTimeComponents(),
                                                                                repeats: false),
                                     remoteFeatureFlag: nil)
        }
    }
}

private extension DefaultBlazeLocalNotificationScheduler {
    enum Constants {
        static let daysDurationNoCampaignReminderNotification = 30
        static let siteIDKey = "site_id"
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
}
