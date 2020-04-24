
import Foundation

/// Emits values to observers as soon as the values arrive.
///
/// Acts like `PassthroughSubject` in Combine and `PublishSubject` in ReactiveX.
///
/// See:
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

    func send(_ element: Element) {
        self.observers.values.forEach { observer in
            observer.send(element)
        }
    }
}
