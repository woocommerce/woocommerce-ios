import Foundation

public struct Webhook {
    public let name: String?
    public let topic: String
    public let deliveryURL: URL

    public init(name: String?, topic: String, deliveryURL: URL) {
        self.name = name
        self.topic = topic
        self.deliveryURL = deliveryURL
    }
}
