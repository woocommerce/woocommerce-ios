
import Foundation

/// Emits values to observers as soon as the values arrive. Only the values emitted after the
/// subscription will be emitted.
///
/// Acts like `PassthroughSubject` in Combine and `PublishSubject` in ReactiveX.
///
/// This observable is a bridge between the imperative and reactive programming paradigms. It
/// allows consumers to _manually_ emit values using the `send()` method.
///
/// Multiple observers are allowed which makes this a possible replacement for
/// `NSNotificationCenter` observations.
///
/// See here for info about similar observables in other frameworks:
///
/// - https://developer.apple.com/documentation/combine/passthroughsubject
/// - http://reactivex.io/documentation/subject.html
///
final class PublishSubject<Element>: Observable<Element> {

    private typealias OnCancel = () -> ()

    private var observers = [UUID: Observer<Element>]()

    override func subscribe(_ onNext: @escaping OnNext<Element>) -> ObservationToken {
        let uuid = UUID()

        observers[uuid] = Observer(onNext: onNext)

        let onCancel: OnCancel = { [weak self] in
            self?.observers.removeValue(forKey: uuid)
        }

        return ObservationToken(onCancel: onCancel)
    }

    /// Emit a new value. All observers are immediately called with the given value.
    ///
    func send(_ element: Element) {
        self.observers.values.forEach { observer in
            observer.send(element)
        }
    }
}
