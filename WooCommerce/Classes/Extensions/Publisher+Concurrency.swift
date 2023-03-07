import Combine

extension Publisher {
    /// Transforms the publisher with an async throwable operator.
    ///
    /// Original implementation:
    /// https://www.swiftbysundell.com/articles/calling-async-functions-within-a-combine-pipeline
    ///
    /// - Parameter transform: a function that transforms the upstream publisher asynchronously with the option to throw an error.
    /// - Returns: a new publisher that is transformed by the given operator asynchronously.
    func asyncMap<T>(_ transform: @escaping (Output) async throws -> T) ->
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
