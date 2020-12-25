/// An observation token that contains a closure when the observation is cancelled.
///
/// This acts like `AnyCancellable` in Combine and `IDisposable` in ReactiveX.
///
/// Example usage can be found in `ProductImageActionHandler`.
///
/// See:
///
///   - https://developer.apple.com/documentation/combine/anycancellable
///
public final class ObservationToken {
    private let onCancel: () -> Void

    public init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    public func cancel() {
        onCancel()
    }
}
