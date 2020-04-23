
import Foundation

/// A subscription to an `Observable`.
///
/// Acts like `Subscriber` in Combine and `IObserver` in ReactiveX.
///
/// See:
///  - https://developer.apple.com/documentation/combine/subscriber
///  - http://introtorx.com/Content/v1.0.10621.0/02_KeyTypes.html#IObserver
///
struct Observer<Element> {
    private let onNext: (Element) -> ()

    init(onNext: @escaping OnNext<Element>) {
        self.onNext = onNext
    }

    func send(_ element: Element) {
        onNext(element)
    }
}
