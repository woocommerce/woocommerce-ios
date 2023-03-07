extension Result where Failure == Error {
    /// Initializes asyncrhonously a `Result` with a `async throws` closure returning a object of the specified type
    ///
    public init(catching body: () async throws -> Success) async {
        do {
            let value = try await body()
            self = .success(value)
        } catch {
            self = .failure(error)
        }
    }
}
