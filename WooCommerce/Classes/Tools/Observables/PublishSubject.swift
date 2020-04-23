
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
final class PublishSubject<Element>: Observable {

    private typealias OnCancel = () -> ()

    private var observers = [UUID: Observer<Element>]()

    private let queue = DispatchQueue.main

    func subscribe(_ onNext: @escaping OnNext<Element>) -> ObservationToken {
        let uuid = UUID()

        let onCancel: OnCancel = { [weak self] in
            self?.observers.removeValue(forKey: uuid)
        }

        let token = ObservationToken(onCancel: onCancel)
        let observer = Observer(onNext: onNext)

        queue.async { [weak self] in
            self?.observers[uuid] = observer
        }

        return token
    }

    func send(_ element: Element) {
        queue.async { [weak self] in
            guard let self = self else {
                return
            }

            self.observers.values.forEach { observer in
                observer.send(element)
            }
        }
    }
}
