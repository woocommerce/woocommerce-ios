/// Abstraction provided by Hardware so that clients of this library
/// can model a way to provide a connection token.
/// It is meant to abstract an implementation of the [adapter pattern](https://en.wikipedia.org/wiki/Adapter_pattern)
/// This name is terrible. I can't think of a better one though
public protocol CardReaderNetworkingAdapter {
    func fetchToken(completion: @escaping(String?, Error?) -> Void)
}
