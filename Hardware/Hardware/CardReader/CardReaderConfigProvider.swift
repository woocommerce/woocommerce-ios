/// Abstraction provided by Hardware so that clients of this library
/// can model a way to provide a connection token.
/// It is meant to abstract an implementation of the [adapter pattern](https://en.wikipedia.org/wiki/Adapter_pattern)

public protocol ReaderTokenProvider {
    func fetchToken(completion: @escaping(Result<String, CardReaderConfigError>) -> Void)
}

public protocol ReaderLocationProvider {
    func fetchDefaultLocationID(completion: @escaping(Result<String, CardReaderConfigError>) -> Void)
}

public protocol CardReaderConfigProvider: ReaderLocationProvider, ReaderTokenProvider {
    func fetchToken(completion: @escaping(Result<String, CardReaderConfigError>) -> Void)
    func fetchDefaultLocationID(completion: @escaping(Result<String, CardReaderConfigError>) -> Void)
}

/// An error that occurs while configuring a reader
///
/// - incompleteStoreAddress: The location could not be created because the Store address configured for the site failed validation.
///     May include URL for wp-admin page to update address.
/// - unknown: other error cases.
///
public enum CardReaderConfigError: Error, LocalizedError {
    case incompleteStoreAddress(adminUrl: URL?)
    case unknown(error: Error)
}
