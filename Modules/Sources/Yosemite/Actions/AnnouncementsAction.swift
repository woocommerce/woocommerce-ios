/// AnnouncementsAction: Defines all of the Actions supported by the AnnouncementsStore.
///
public enum AnnouncementsAction: Action {

    /// Synchronizes the latest Announcements and save it on disk
    ///
    case synchronizeAnnouncements(onCompletion: (Result<Announcement, Error>) -> Void)

    /// Load latest saved announcement along with a boolean indicating if it was already presented to the user on app launch
    ///
    case loadSavedAnnouncement(onCompletion: (Result<(Announcement, IsDisplayed), Error>) -> Void)

    /// Marks the saved announcement as displayed
    ///
    case markSavedAnnouncementAsDisplayed(onCompletion: (Result<Void, Error>) -> Void)

    /// Synchronizes announcements for debugging purposes, using a custom app version.
    /// This allows fetching test announcements targeting a specific version (e.g., "999.0")
    /// without affecting production users.
    ///
    case synchronizeAnnouncementsForDebug(appVersion: String, onCompletion: (Result<Announcement, Error>) -> Void)

    /// Deletes the saved announcement from disk.
    ///
    case deleteSavedAnnouncement(onCompletion: (Result<Void, Error>) -> Void)
}
