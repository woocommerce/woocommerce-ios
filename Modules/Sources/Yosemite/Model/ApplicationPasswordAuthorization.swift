import Foundation

/// An application password approval page checked to belong to the store being logged into.
public struct ApplicationPasswordAuthorization: Sendable, Equatable {
    public let url: URL

    /// The WordPress address that serves the approval page when it's not within the store's address,
    /// after that WordPress reported the store as its home. Nil when the page is within the store.
    public let approvalSiteURL: String?

    public init(url: URL, approvalSiteURL: String?) {
        self.url = url
        self.approvalSiteURL = approvalSiteURL
    }
}

public enum ApplicationPasswordAuthorizationError: Error, Equatable {
    /// The approval page belongs to a different site than the store.
    case siteMismatch
}
