#import "Constants.h"

/// Error domain of `NSError` instances that are converted from `WordPressComRestApiEndpointError`
/// and `WordPressAPIError<WordPressComRestApiEndpointError>` instances.
///
/// See `extension WordPressComRestApiEndpointError: CustomNSError` for context.
NSString *WordPressComRestApiErrorDomain = @"WordPressKit.WordPressComRestApiError";
