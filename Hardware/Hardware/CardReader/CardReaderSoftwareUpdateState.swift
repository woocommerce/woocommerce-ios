public enum CardReaderSoftwareUpdateState {
    // An optional update is available
    case available

    // A mandatory update has started
    case started(cancelable: Cancelable?)

    // The update is being installed
    case installing(progress: Float)

    // The update has finished installing
    case completed

    // No update available
    case none
}
