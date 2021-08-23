import WordPressKit

/// AnnouncementsAction: Defines all of the Actions supported by the AnnouncementsStore.
///
public enum AnnouncementsAction: Action {

    /// Synchronizes the latest Announcements
    ///
    case synchronizeFeatures(onCompletion: ([Feature]) -> Void)
}
