import StripeTerminal

final class StripeCancelable: Cancelable {
    private let cancelable: StripeTerminal.Cancelable

    init(cancelable: StripeTerminal.Cancelable) {
        self.cancelable = cancelable
    }

    func cancel(completion: @escaping (Error?) -> Void) {
        cancelable.cancel(completion)
    }
}
