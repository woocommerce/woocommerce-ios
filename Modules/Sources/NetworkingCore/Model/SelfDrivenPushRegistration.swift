import Foundation

public struct SelfDrivenPushRegistration: Equatable, Sendable {
    public let tokenID: Int64
    public let blogID: Int64?

    public init(tokenID: Int64, blogID: Int64?) {
        self.tokenID = tokenID
        self.blogID = blogID
    }
}
