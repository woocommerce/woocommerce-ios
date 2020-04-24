
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
/// This abstract class is meant to be a "readonly" `Observable` to hide the mutable methods
/// of observables like `PublishSubject`. For example, if we use `PublishSubject` and expose it
/// in the `ViewModel` like this:
///
/// ```
/// class ViewModel {
///     let onDataLoaded = PublishSubject<[Items]>()
/// }
/// ```
///
/// The `ViewController` will be able to access the **mutating** methods of `PublishSubject` like:
///
/// ```
/// // Submit new items. This will ultimately call the `subscribe` callbacks.
/// viewModel.onDataLoaded.send([Item]())
/// ```
///
/// Ideally, the `ViewController` should only have the `Observable` _interface_ so it only has
/// access to `subscribe()`. We can do that this way:
///
/// ```
/// class ViewModel {
///     private let onDataLoadedSubject = PublishSubject<[Items]>()
///
///     // Expose a readonly observable
///     var onDataLoaded: Observable<[Items]> {
///         onDataLoadedSubject
///     }
/// }
/// ```
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
