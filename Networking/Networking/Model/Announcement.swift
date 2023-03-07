import Foundation
import Codegen

/// Feature announcement for the Woo mobile app
///
public struct Announcement: Decodable, GeneratedCopiable, GeneratedFakeable {
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

    /// Public initializer
    public init(appVersionName: String, minimumAppVersion: String, maximumAppVersion: String, appVersionTargets: [String], detailsUrl: String, announcementVersion: String, isLocalized: Bool, responseLocale: String, features: [Feature]) {
        self.appVersionName = appVersionName
        self.minimumAppVersion = minimumAppVersion
        self.maximumAppVersion = maximumAppVersion
        self.appVersionTargets = appVersionTargets
        self.detailsUrl = detailsUrl
        self.announcementVersion = announcementVersion
        self.isLocalized = isLocalized
        self.responseLocale = responseLocale
        self.features = features
    }
}

/// A feature in an app announcement
///
public struct Feature: Decodable, GeneratedCopiable, GeneratedFakeable {
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

    /// Public initializer
    public init(title: String, subtitle: String, icons: [FeatureIcon]? = nil, iconUrl: String, iconBase64: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icons = icons
        self.iconUrl = iconUrl
        self.iconBase64 = iconBase64
    }
}

/// An icon for a feature announcement
///
public struct FeatureIcon: Decodable, GeneratedCopiable, GeneratedFakeable {
    /// URL of the icon
    public let iconUrl: String

    // Base 64 data of the icon
    public let iconBase64: String

    // Type of the icon
    public let iconType: String

    /// Public initializr
    public init(iconUrl: String, iconBase64: String, iconType: String) {
        self.iconUrl = iconUrl
        self.iconBase64 = iconBase64
        self.iconType = iconType
    }
}
