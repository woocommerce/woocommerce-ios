import Storage

/// AnnouncementsAction: Defines all of the Actions supported by the AnnouncementsStore.
///
public enum AnnouncementsAction: Action {

    public typealias IsCached = Bool

    /// Synchronizes the latest Announcements.
    /// If information was already fetched, the list of features will be retrieved along with the boolean indicating that the data was already fetched
    ///
    case synchronizeFeatures(onCompletion: ([Feature], IsCached) -> Void)
}
