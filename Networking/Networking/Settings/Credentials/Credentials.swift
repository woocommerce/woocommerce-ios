import Foundation

public protocol SecretType: Equatable { }

/// Holds WordPress.com authentication token
///
public struct WPCOMSecret: SecretType {
    public let authToken: String
}

/// Holds .org site credentials password
///
public struct WPOrgSecret: SecretType {
    public let password: String
}

/// Credentials for WPCOM or WPOrg
///
public protocol Credentials: Equatable {
    associatedtype Element: SecretType

    /// WPCOM username or .org site credentials username
    ///
    var username: String { get }

    /// `WPCOMSecret` or `WPORGSecret`
    ///     
    var secret: Element { get }

    /// Site URL
    ///
    var siteAddress: String { get }
}
