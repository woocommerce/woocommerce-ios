/// Adapts a legacy completion for main-actor invocation without changing public action callback types.
///
/// The unchecked conformance allows transferring a non-Sendable closure; only invocation is actor-checked.
/// Callers must ensure its captures are safe to access on the main actor and cannot race with access elsewhere.
/// This wrapper does not establish thread safety or ownership of captured objects.
/// Remove this bridge once dispatch and callback APIs express the required isolation and transfer contracts.
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
