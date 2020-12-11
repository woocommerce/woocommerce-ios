
import Foundation

/// Emits the current value to observers upon subscription and also when new values arrive.
///
/// Acts like `CurrentValueSubject` in Combine and `BehaviorSubject` in ReactiveX.
///
/// This observable is a bridge between the imperative and reactive programming paradigms. It
/// allows consumers to _manually_ emit values using the `send()` method.
///
/// Multiple observers are allowed which makes this a possible replacement for
/// `NSNotificationCenter` observations.
///
/// ## Example Usage
///
/// In a class that you would like to emit values (or events), add the `BehaviorSubject` defining
/// the value type:
///
/// ```
/// class ViewModel {
///     /// Calls observers/subscribers whenever a feature's availability changes.
///     private let isFeatureAvailable = BehaviorSubject<Bool>()
/// }
/// ```
///
/// Since `BehaviorSubject` exposes `send()` which makes this a **mutable** Observable, we recommend
/// exposing only the `Observable<Bool>` interface:
///
/// ```
/// class ViewModel {
///     private let isFeatureAvailableSubject = BehaviorSubject<Bool>()
///
///     /// The public Observable that the ViewController will subscribe to
///     var isFeatureAvailable: Observable<Bool> {
///         isFeatureAvailableSubject
///     }
/// }
/// ```
///
/// The `ViewController` can then subscribe to the `isFeatureAvailable` Observable:
///
/// ```
/// func viewDidLoad() {
///     viewModel.isFeatureAvailable.subscribe { isAvailable in
///         // Present an amazing new UI if the feature is available
///         self.featureSubview.isHidden = !isAvailable
///     }
/// }
/// ```
///
/// Whenever the conditions for the feature's availability changes, like after fetching a setting
/// from the API, the `ViewModel` can _notify_ the `ViewController` by updating
/// `isFeatureAvailableSubject`:
///
/// ```
/// fetchFromAPI { isFeatureAvailable
///     // Notify the observers (e.g. ViewController) that the feature availability has changed.
///     isFeatureAvailableSubject.send(isFeatureAvailable)
/// }
/// ```
///
/// ## References
///
/// See here for info about similar observables in other frameworks:
///
/// - https://developer.apple.com/documentation/combine/currentvaluesubject
/// - http://reactivex.io/documentation/subject.html
///
public final class BehaviorSubject<Element>: Observable<Element> {

    private typealias OnCancel = () -> ()

    /// The list of Observers that will be notified when a new value is sent.
    ///
    private var observers = [UUID: Observer<Element>]()

    /// The last value that was emitted or the initial value passed in `init()`.
    ///
    public private(set) var value: Element

    /// Create an instance of `self` and set the initial `value`.
    public init(_ initialValue: Element) {
        self.value = initialValue
        super.init()
    }

    public override func subscribe(_ onNext: @escaping OnNext<Element>) -> ObservationToken {
        let uuid = UUID()

        let observer = Observer(onNext: onNext)

        observers[uuid] = observer

        // Emit the last value
        observer.send(value)

        let onCancel: OnCancel = { [weak self] in
            self?.observers.removeValue(forKey: uuid)
        }

        return ObservationToken(onCancel: onCancel)
    }

    /// Emit a new value. All observers are immediately called with the given value.
    ///
    public func send(_ element: Element) {

        // Save as the last value so we can send this to new subscribers.
        value = element

        observers.values.forEach { observer in
            observer.send(element)
        }
    }
}
