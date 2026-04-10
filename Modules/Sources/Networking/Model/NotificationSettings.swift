import Foundation
import Codegen

/// Notification settings for a user
///
public struct NotificationSettings: Equatable, Codable, GeneratedCopiable {

    /// Settings for different blogs connected to the user.
    public let blogs: [Blog]

    /// Convenience init to create notification settings for a given device ID.
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
    struct Blog: Equatable, Codable, GeneratedCopiable {
        /// ID of the blog
        public let blogID: Int64

        /// List of settings for registered devices
        public let devices: [Device]

        enum CodingKeys: String, CodingKey {
            case blogID = "blog_id"
            case devices
            case device
        }

        public init(blogID: Int64, devices: [Device]) {
            self.blogID = blogID
            self.devices = devices
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(blogID, forKey: .blogID)
            try container.encode(devices, forKey: .devices)
        }

        public init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<NotificationSettings.Blog.CodingKeys> = try decoder.container(keyedBy: NotificationSettings.Blog.CodingKeys.self)
            self.blogID = try container.decode(Int64.self, forKey: NotificationSettings.Blog.CodingKeys.blogID)
            self.devices = try {
                if let array = try container.decodeIfPresent([NotificationSettings.Device].self, forKey: NotificationSettings.Blog.CodingKeys.devices) {
                    return array
                } else if let device = try container.decodeIfPresent(NotificationSettings.Device.self, forKey: NotificationSettings.Blog.CodingKeys.device) {
                    return [device]
                }
                return []
            }()
        }
    }

    /// Notification settings for a device
    struct Device: Equatable, Codable, GeneratedCopiable {

        /// Unique ID of the device
        public let deviceID: Int64

        /// Whether a notification should be sent when there is a new comment on the blog
        public let newComment: Bool

        /// Whether a notification should be sent when there is a new order on the store.
        public let storeOrder: Bool

        public init(deviceID: Int64, newComment: Bool, storeOrder: Bool) {
            self.deviceID = deviceID
            self.newComment = newComment
            self.storeOrder = storeOrder
        }

        enum CodingKeys: String, CodingKey {
            case deviceID = "device_id"
            case newComment = "new_comment"
            case storeOrder = "store_order"
        }
    }
}
