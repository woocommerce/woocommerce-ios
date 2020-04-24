
import Foundation

/// Signature of a block called for every emitted Observable value.
///
typealias OnNext<Element> = (Element) -> ()

/// Emits values over time.
///
/// Acts like `Publisher` in Combine and `Observable` in ReactiveX.
///
/// This class is a pseudo-abstract class. It does not do anything on its own. Use the
/// subclasses like `PublishSubject` instead.
///
/// See here for more info about Observables:
///
/// - https://developer.apple.com/documentation/combine/publisher
/// - http://reactivex.io/documentation/observable.html
///
class Observable<Element> {
    /// Subscribe to values emitted by this `Observable`.
    ///
    /// The given `onNext` is called a "Observer" or "Subscriber".
    ///
    /// Example:
    ///
    /// ```
    /// class ViewModel {
    ///     let onDataLoaded: Observable<[Item]>
    /// }
    ///
    /// func viewDidLoad() {
    ///     viewModel.onDataLoaded.subscribe { items in
    ///         // do something with `items`
    ///         tableView.reloadData()
    ///     }
    /// }
    /// ```
    ///
    func subscribe(_ onNext: @escaping OnNext<Element>) -> ObservationToken {
        fatalError("Abstract method. This must be implemented by subclasses.")
    }
}
