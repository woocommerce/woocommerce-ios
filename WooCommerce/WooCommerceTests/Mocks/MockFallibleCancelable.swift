import Yosemite

final class MockFallibleCancelable: FallibleCancelable {
    let onCancel: () throws -> Void

    init(onCancel: @escaping () throws -> Void) {
        self.onCancel = onCancel
    }

    private(set) var cancelCalled: Bool = false
    private(set) var cancelCompleted: Bool = false

    func cancel(completion: @escaping (Result<Void, Error>) -> Void) {
        cancelCalled = true
        do {
            try onCancel()
            cancelCompleted = true
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
