/// AnnouncementsAction: Defines all of the Actions supported by the AnnouncementsStore.
///
public enum AnnouncementsAction: Action {

    /// Synchronizes the latest Announcements and save it on disk
    ///
    case synchronizeAnnouncements(onCompletion: (Result<Announcement, Error>) -> Void)
    case loadSavedAnnouncement(onCompletion: (Result<Announcement, Error>) -> Void)
}
