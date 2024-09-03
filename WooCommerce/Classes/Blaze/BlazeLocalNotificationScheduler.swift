import Yosemite
import protocol Storage.StorageManagerType
import Combine

protocol BlazeLocalNotificationScheduler {
    func scheduleNotifications()
}

/// Handles the scheduling of Blaze local notifications.
///
final class DefaultBlazeLocalNotificationScheduler: BlazeLocalNotificationScheduler {
    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let scheduler: LocalNotificationScheduler
    private let userDefaults: UserDefaults
    private let pushNotesManager: PushNotesManager
    private var subscriptions: Set<AnyCancellable> = []

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
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         userDefaults: UserDefaults = .standard,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.pushNotesManager = pushNotesManager
        self.scheduler = LocalNotificationScheduler(pushNotesManager: pushNotesManager)
        self.userDefaults = userDefaults
    }

    /// Starts observing campaigns from storage and schedules local notification
    ///
    func scheduleNotifications() {
        observeStorageAndScheduleNotifications()

        pushNotesManager.localNotificationUserResponses
            .sink { [weak self] response in
                guard let self,
                      response.notification.request.identifier == LocalNotification.Scenario.blazeNoCampaignReminder.identifier,
                      let siteID = response.notification.request.content.userInfo[Constants.siteIDKey] as? Int64 else {
                    return
                }

                userDefaults.setBlazeNoCampaignReminderOpened(true, for: siteID)
            }
            .store(in: &subscriptions)
    }
}

private extension DefaultBlazeLocalNotificationScheduler {
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
        guard !userDefaults.blazeNoCampaignReminderOpened(for: siteID) else {
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
              let notificationTime = Calendar.current.date(byAdding: .day, value: Constants.daysDurationNoCampaignReminderNotification, to: latestEndTime),
              notificationTime > Date.now else {
            return
        }

        Task { @MainActor in
            let notification = LocalNotification(scenario: LocalNotification.Scenario.blazeNoCampaignReminder,
                                                 userInfo: [Constants.siteIDKey: siteID])
            await scheduler.cancel(scenario: .blazeNoCampaignReminder)
            DDLogDebug("Blaze: Schedule local notification for date \(notificationTime).")
            await scheduler.schedule(notification: notification,
                                     trigger: UNTimeIntervalNotificationTrigger(timeInterval: notificationTime.timeIntervalSince(Date.now),
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
    /// Returns Notification opened bool value for the site ID
    ///
    func blazeNoCampaignReminderOpened(for siteID: Int64) -> Bool {
        let blazeNoCampaignReminderOpened = self[.blazeNoCampaignReminderOpened] as? [String: Bool]
        let idAsString = "\(siteID)"
        guard let value = blazeNoCampaignReminderOpened?[idAsString] else {
            return false
        }
        return value
    }

    /// Stores the notification opened Bool value for the given site ID
    ///
    func setBlazeNoCampaignReminderOpened(_ shown: Bool, for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var blazeNoCampaignReminderOpenedDictionary = self[.blazeNoCampaignReminderOpened] as? [String: Bool] {
            blazeNoCampaignReminderOpenedDictionary[idAsString] = shown
            self[.blazeNoCampaignReminderOpened] = blazeNoCampaignReminderOpenedDictionary
        } else {
            self[.blazeNoCampaignReminderOpened] = [idAsString: shown]
        }
    }
}
