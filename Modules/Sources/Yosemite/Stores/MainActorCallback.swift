/// Adapts an existing callback to the main actor without requiring every action caller to be `Sendable`.
///
/// The unchecked conformance is safe because the wrapped callback is private and can only be invoked
/// through the main-actor-isolated `callAsFunction` method.
struct MainActorCallback<Input: Sendable>: @unchecked Sendable {
    private let callback: (Input) -> Void

    init(_ callback: @escaping (Input) -> Void) {
        self.callback = callback
    }

    @MainActor
    func callAsFunction(_ input: Input) {
        callback(input)
    }
}

func mainActorCallback<Input: Sendable>(_ callback: @escaping (Input) -> Void) -> @MainActor @Sendable (Input) -> Void {
    let callback = MainActorCallback(callback)
    return { @MainActor @Sendable input in
        callback(input)
    }
}
