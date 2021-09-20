/// A protocol indicating that an activity or action supports cancellation, where that cancelation might fail.
/// Not to be confused with Combine.Cancellable
public protocol FallibleCancelable {
    /// Cancel the activity.
    func cancel(completion: @escaping (Result<Void, Error>) -> Void)
}
