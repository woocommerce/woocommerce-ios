import Foundation

// MARK: - JetpackSettingsAction: Defines Jetpack Settings operations.
//
public enum JetpackSettingsAction: Action {
    /// Enables the provided Jetpack module
    ///
    case enableJetpackModule(_ module: JetpackModule, siteID: Int64, completion: (Result<Void, Error>) -> Void)
}
