import Foundation
import enum Networking.SiteCreationFlow

/// SiteAction: Defines all of the Actions supported by the SiteStore.
///
public enum SiteAction: Action {
    /// Creates a site in the store creation flow.
    /// - Parameters:
    ///   - name: The name of the site.
    ///   - flow: The creation flow to follow.
    ///   - completion: The result of site creation.
    case createSite(name: String,
                    flow: SiteCreationFlow,
                    completion: (Result<SiteCreationResult, SiteCreationError>) -> Void)

    /// Launches a site publicly through WPCOM.
    /// - Parameter:
    ///   - siteID: ID of the site to launch.
    ///   - completion: Called when the result of site launch is available.
    case launchSite(siteID: Int64, completion: (Result<Void, SiteLaunchError>) -> Void)

    /// Enables a free trial plan for a site.
    ///
    case enableFreeTrial(siteID: Int64, completion: (Result<Void, Error>) -> Void)

    /// Syncs a site from WPCOM to storage.
    /// - Parameter:
    ///   - siteID: ID of the site to load.
    ///   - completion: Called when the result of the synced site is available.
    case syncSite(siteID: Int64, completion: (Result<Site, Error>) -> Void)

    /// Updates title for the given site.
    /// - Parameters:
    ///   - siteID: ID of the site to update.
    ///   - title: The title to update
    ///   - completion: Called when the result of the update is available.
    ///
    case updateSiteTitle(siteID: Int64, title: String, completion: (Result<Void, Error>) -> Void)

    /// Upload store profiler answers
    ///
    case uploadStoreProfilerAnswers(siteID: Int64, answers: StoreProfilerAnswers, completion: (Result<Void, Error>) -> Void)
}

/// The result of site creation including necessary site information.
public struct SiteCreationResult: Equatable {
    public let siteID: Int64
    public let name: String
    public let url: String
    public let siteSlug: String
}
