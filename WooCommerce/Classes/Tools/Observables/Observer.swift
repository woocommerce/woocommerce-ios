
import Foundation

/// A subscription to an `Observable`.
///
/// Acts like `Subscriber` in Combine and `IObserver` in ReactiveX.
///
/// Observers are simply the callbacks when you subscribe to an `Observable`. Consider this:
///
/// ```
/// viewModel.onDataLoaded.subscribe { items in
///     /// do something
/// }
/// ```
///
/// The block passed to the `subscribe` method with the "do something" comment is the `Observer`.
///
/// Currently, this `struct` is simply a container to clarify these concepts. In other frameworks,
/// an `Observer` can have more callbacks like `onCompleted`.
///
/// See these for more info about Observers:
///
///  - https://developer.apple.com/documentation/combine/subscriber
///  - http://introtorx.com/Content/v1.0.10621.0/02_KeyTypes.html#IObserver
///
struct Observer<Element> {
    private let onNext: (Element) -> ()

    init(onNext: @escaping OnNext<Element>) {
        self.onNext = onNext
    }

    /// Send the given value to the observer.
    ///
    func send(_ element: Element) {
        onNext(element)
    }
}
