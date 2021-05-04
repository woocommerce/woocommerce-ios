import Foundation

/// Defines all actions supported by the `AddOnGroupStore`
///
public enum AddOnGroupAction: Action {

    /// Synchronizes all add-on groups for a given `siteID`
    ///
    case synchronizeAddOnGroups(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
}
