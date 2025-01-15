import Combine

public extension Array where Element: Publisher {
    func combineLatest() -> AnyPublisher<[Element.Output], Element.Failure> {
        guard !isEmpty else {
            // If the array is empty, immediately return an empty array
            return Just([]).setFailureType(to: Element.Failure.self).eraseToAnyPublisher()
        }

        return reduce(Just([]).setFailureType(to: Element.Failure.self).eraseToAnyPublisher()) { combined, next in
            combined.combineLatest(next) { $0 + [$1] }.eraseToAnyPublisher()
        }
    }
}
