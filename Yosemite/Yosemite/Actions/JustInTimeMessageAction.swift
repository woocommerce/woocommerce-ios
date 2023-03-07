import Foundation

// MARK: - JustInTimeMessageAction: Defines Just In Time Messages operations.
//
public enum JustInTimeMessageAction: Action {
    /// Retrieves the top `JustInTimeMessage` for a given screen and hook
    ///
    case loadMessage(siteID: Int64,
                     screen: String,
                     hook: JustInTimeMessageHook,
                     completion: (Result<[JustInTimeMessage], Error>) -> ())

    /// Dismisses a `JustInTimeMessage` and others for the same `featureClass`
    ///
    case dismissMessage(_ message: JustInTimeMessage,
                        siteID: Int64,
                        completion: (Result<Bool, Error>) -> ())
}
