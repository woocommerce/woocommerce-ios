/// A type that represents the possible states for software update
public enum CardReaderSoftwareUpdateState {
    /// An optional update is available
    case available

    /// A mandatory update has started
    case started(cancelable: FallibleCancelable?)

    /// The update is being installed
    case installing(progress: Float)

    /// The update failed to install
    case failed(error: Error)

    /// The update has finished installing
    case completed

    /// No update available
    case none
}
