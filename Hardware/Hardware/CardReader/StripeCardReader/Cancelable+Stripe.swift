#if !targetEnvironment(macCatalyst)
import StripeTerminal

final class StripeCancelable: FallibleCancelable {
    private let cancelable: StripeTerminal.Cancelable

    init(cancelable: StripeTerminal.Cancelable) {
        self.cancelable = cancelable
    }

    func cancel(completion: @escaping (Result<Void, Error>) -> Void) {
        cancelable.cancel { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
#endif
