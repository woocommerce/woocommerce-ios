import Foundation
import Codegen

/// Feature announcement for the Woo mobile app
///
public struct Announcement: Codable, GeneratedCopiable, GeneratedFakeable {
    /// Version name for the app
    public let appVersionName: String

    /// Minimum supported app version
    public let minimumAppVersion: String

    /// Maximum supported app version
    public let maximumAppVersion: String

    /// Targets for the app version
    public let appVersionTargets: [String]

    /// URL for the announcement details
    public let detailsUrl: String

    /// Version of the announcement
    public let announcementVersion: String

    /// Whether the announcement is localized
    public let isLocalized: Bool

    /// Locale of the response
    public let responseLocale: String

    /// Feature list in the announcement
    public let features: [Feature]
}

/// A feature in an app announcement
///
public struct Feature: Codable, GeneratedCopiable, GeneratedFakeable {
    /// Title of the feature
    public let title: String

    /// Subtitle of the feature
    public let subtitle: String

    /// Icon list for the feature
    public let icons: [FeatureIcon]?

    /// URL for the icon of the feature
    public let iconUrl: String

    /// Base 64 data for the icon of the feature
    public let iconBase64: String?
}

/// An icon for a feature announcement
///
public struct FeatureIcon: Codable, GeneratedCopiable, GeneratedFakeable {
    /// URL of the icon
    public let iconUrl: String

    // Base 64 data of the icon
    public let iconBase64: String

    // Type of the icon
    public let iconType: String
}
