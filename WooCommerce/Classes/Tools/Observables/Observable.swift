
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
class Observable<Element> {
    func subscribe(_ onNext: @escaping OnNext<Element>) -> ObservationToken {
        fatalError("Abstract method. This must be implemented by subclasses.")
    }
}
