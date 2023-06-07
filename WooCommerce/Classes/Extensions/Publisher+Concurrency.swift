import Combine

extension Publisher {
    /// Transforms the publisher with an async operator that does not throw an error.
    ///
    /// Original implementation:
    /// https://www.swiftbysundell.com/articles/calling-async-functions-within-a-combine-pipeline
    ///
    /// - Parameter transform: a function that transforms the upstream publisher asynchronously that does not throw an error.
    /// - Returns: a new publisher that is transformed by the given operator asynchronously.
    func asyncMap<T>(_ transform: @escaping (Output) async -> T) ->
    Publishers.FlatMap<Future<T, Never>, Self> {
                           flatMap { value in
                               Future { promise in
                                   Task {
                                       promise(.success(await transform(value)))
                                   }
                               }
                           }
                       }

    /// Transforms the publisher with an async throwable operator.
    ///
    /// Original implementation:
    /// https://www.swiftbysundell.com/articles/calling-async-functions-within-a-combine-pipeline
    ///
    /// - Parameter transform: a function that transforms the upstream publisher asynchronously with the option to throw an error.
    /// - Returns: a new publisher that is transformed by the given operator asynchronously.
    func tryAsyncMap<T>(_ transform: @escaping (Output) async throws -> T) ->
    Publishers.FlatMap<Future<T, Error>,
                       Publishers.SetFailureType<Self, Error>> {
                           flatMap { value in
                               Future { promise in
                                   Task {
                                       do {
                                           let output = try await transform(value)
                                           promise(.success(output))
                                       } catch {
                                           promise(.failure(error))
                                       }
                                   }
                               }
                           }
                       }
}
