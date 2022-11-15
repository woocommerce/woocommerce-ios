import Foundation

public struct WooRestAPICredentials: Equatable {

    public let consumer_key: String

    public let consumer_secret: String

    public let siteAddress: String

    public init(consumer_key: String, consumer_secret: String, siteAddress: String) {
        self.consumer_key = consumer_key
        self.consumer_secret = consumer_secret
        self.siteAddress = siteAddress
    }
}
