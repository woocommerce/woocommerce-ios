
import Foundation

typealias OnNext<Element> = (Element) -> ()

/// Emits values over time.
///
/// Acts like `Publisher` in Combine and `Observable` in ReactiveX.
///
/// See:
///
/// - https://developer.apple.com/documentation/combine/publisher
/// - http://reactivex.io/documentation/observable.html
///
protocol Observable {
    associatedtype Element

    func subscribe(_ onNext: @escaping OnNext<Element>) -> ObservationToken
}
