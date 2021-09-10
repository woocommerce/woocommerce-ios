public protocol Cancelable {
    func cancel(completion: @escaping (Error?) -> Void)
}
