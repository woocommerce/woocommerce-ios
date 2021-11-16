/// Abstraction provided by Hardware so that clients of this library
/// can model a way to provide a connection token.
/// It is meant to abstract an implementation of the [adapter pattern](https://en.wikipedia.org/wiki/Adapter_pattern)

public protocol ReaderTokenProvider {
    func fetchToken(completion: @escaping(Result<String, Error>) -> Void)
}

public protocol ReaderLocationProvider {
    func fetchDefaultLocationID(completion: @escaping(Result<String, Error>) -> Void)
}

public protocol CardReaderConfigProvider: ReaderLocationProvider {
    func fetchToken(completion: @escaping(Result<String, Error>) -> Void)
    func fetchDefaultLocationID(completion: @escaping(Result<String, Error>) -> Void)
}
