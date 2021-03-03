/// Abstraction provided by Hardware so that clients of this library
/// can model a way to provide a connection token.
/// It is meant to abstract an implementation of the [adapter pattern](https://en.wikipedia.org/wiki/Adapter_pattern)
public protocol CardReaderConfigProvider {
    func fetchToken(completion: @escaping(String?, Error?) -> Void)
}
