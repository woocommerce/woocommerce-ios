import Foundation

/// Error domain of `NSError` instances that are converted from `WordPressComRestApiEndpointError`
/// and `WordPressAPIError<WordPressComRestApiEndpointError>` instances.
///
/// See `extension WordPressComRestApiEndpointError: CustomNSError` for context.
let WordPressComRestApiErrorDomain = "WordPressKit.WordPressComRestApiError"

// WordPressComRestApiErrorDomain is accessible only in Swift and, since it's a global, cannot be made @objc.
// As a workaround, here is a builder to init NSError with that domain and a method to check the domain.
@objc
public extension NSError {

    @objc
    static func wordPressComRestApiError(
        code: Int,
        userInfo: [String: Any]?
    ) -> NSError {
        NSError(
            domain: WordPressComRestApiErrorDomain,
            code: code,
            userInfo: userInfo
        )
    }

    @objc
    func hasWordPressComRestApiErrorDomain() -> Bool {
        domain == WordPressComRestApiErrorDomain
    }
}
