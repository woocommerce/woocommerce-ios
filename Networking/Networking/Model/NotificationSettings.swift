import Foundation

/// Notification settings for a user
///
public struct NotificationSettings: Equatable, Encodable {

    /// Settings for different blogs connected to the user.
    public let blogs: [Blog]

    /// Helper method to create notification settings for a given device ID.
    ///
    public init(deviceID: Int64, enabledSites: [Int64], disabledSites: [Int64]) {
        let enabledSiteSettings = enabledSites.map { siteID in
            Blog(blogID: siteID, devices: [
                Device(deviceID: deviceID,
                       newComment: true,
                       storeOrder: true)
            ])
        }

        let disabledSiteSettings = disabledSites.map { siteID in
            Blog(blogID: siteID, devices: [
                Device(deviceID: deviceID,
                       newComment: false,
                       storeOrder: false)
            ])
        }

        self.init(blogs: (enabledSiteSettings + disabledSiteSettings))
    }

    public init(blogs: [Blog]) {
        self.blogs = blogs
    }
}

public extension NotificationSettings {
    /// Notification settings for a blog
    struct Blog: Equatable, Encodable {
        /// ID of the blog
        public let blogID: Int64

        /// List of settings for registered devices
        public let devices: [Device]

        enum CodingKeys: String, CodingKey {
            case blogID = "blog_id"
            case devices
        }
    }

    /// Notification settings for a device
    struct Device: Equatable, Encodable {
        /// Unique ID of the device
        public let deviceID: Int64

        /// Whether a notification should be sent when there is a new comment on the blog
        public let newComment: Bool

        /// Whether a notification should be sent when there is a new order on the store.
        public let storeOrder: Bool

        enum CodingKeys: String, CodingKey {
            case deviceID = "device_id"
            case newComment = "new_comment"
            case storeOrder = "store_order"
        }
    }
}
