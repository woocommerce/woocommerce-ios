import Foundation

/// Utility class to encode the stored application password.
/// By default it uses the stored application password.
///
public struct ApplicationPasswordEncoder {

    /// Password envelope.
    ///
    private let passwordEnvelope: ApplicationPassword?

    public init(passwordEnvelope: ApplicationPassword? = nil) {
        self.passwordEnvelope = passwordEnvelope ?? ApplicationPasswordStorage().applicationPassword
    }

    /// Returns the application password on a base64 encoded format.
    /// The output is ready to be used in the authentication header.
    /// Returns `nil` if the password can't be encoded.
    ///
    public func encodedPassword() -> String? {
        guard let passwordEnvelope else {
            return nil
        }

        let loginString = "\(passwordEnvelope.wpOrgUsername):\(passwordEnvelope.password.secretValue)"
        guard let loginData = loginString.data(using: .utf8) else {
            return nil
        }

        return loginData.base64EncodedString()
    }
}
