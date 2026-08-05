/// Defines all of the Analytics Operations we'll be performing. This allows us to swap the actual Wrapper in our
/// Unit Testing target.
///
public protocol AnalyticsProvider {

    /// Refresh the tracking metadata for the current user
    ///
    func refreshUserData()

    /// Refresh the tracking metadata for the current user and notify the caller when the refresh has completed.
    ///
    /// Providers that perform the refresh asynchronously should override this method so dependent work does not
    /// race with a user switch.
    func refreshUserData(completion: @escaping () -> Void)

    /// Track a spcific event without any associated properties
    ///
    /// - Parameter eventName: the event name
    ///
    func track(_ eventName: String)


    /// Track a specific event with associated properties
    ///
    /// - Parameters:
    ///   - eventName: the event name
    ///   - properties: a collection of properties
    ///
    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?)

    /// Clear queued events
    ///
    func clearEvents()

    /// Switch between an authed user and anon user
    ///
    func clearUsers()
}

public extension AnalyticsProvider {
    func refreshUserData(completion: @escaping () -> Void) {
        refreshUserData()
        completion()
    }
}
