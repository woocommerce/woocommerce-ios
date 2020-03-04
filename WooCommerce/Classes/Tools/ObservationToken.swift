/// An observation token that contains a closure when the observation is cancelled.
/// Example usage can be found in `ProductImageActionHandler`.
///
final class ObservationToken {
    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        onCancel()
    }
}
