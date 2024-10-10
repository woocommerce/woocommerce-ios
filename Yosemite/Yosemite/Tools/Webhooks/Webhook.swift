import Foundation

public struct Webhook: Equatable {
    public let name: String?
    public let status: String
    public let topic: String
    public let deliveryURL: URL

    public init(name: String?, status: String, topic: String, deliveryURL: URL) {
        self.name = name
        self.status = status
        self.topic = topic
        self.deliveryURL = deliveryURL
    }
}
