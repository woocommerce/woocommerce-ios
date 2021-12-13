
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
/// ## Example Usage
///
/// In a class that you would like to emit values (or events), add the `PublishSubject` defining
/// the value type:
///
/// ```
/// class PostListViewModel {
///     /// Calls observers/subscribers whenever the list of Post changes.
///     private let postsSubject = PublishSubject<[Post]>()
/// }
/// ```
///
/// Since `PublishSubject` exposes `send()` which makes this a **mutable** Observable, we recommend
/// exposing only the `Observable<[Post]>` interface:
///
/// ```
/// class PostListViewModel {
///     private let postsSubject = PublishSubject<[Post]>()
///
///     /// The public Observable that the ViewController will subscribe to
///     var posts: Observable<[Post]> {
///         postsSubject
///     }
/// }
/// ```
///
/// The `ViewController` can then subscribe to the `posts` Observable:
///
/// ```
/// func viewDidLoad() {
///     viewModel.posts.subscribe { posts in
///         // do something with posts
///         tableView.reloadData()
///     }
/// }
/// ```
///
/// Whenever the list of post changes, like after fetching from the API, the `ViewModel` can
/// _notify_ the `ViewController` by updating `postsSubject`:
///
/// ```
/// fetchFromAPI { fetchedPosts
///     // Notify the observers (e.g. ViewController) that the list of posts have changed
///     postsSubject.send(fetchedPosts)
/// }
/// ```
///
/// ## References
///
/// See here for info about similar observables in other frameworks:
///
/// - https://developer.apple.com/documentation/combine/passthroughsubject
/// - http://reactivex.io/documentation/subject.html
///
public final class PublishSubject<Element>: Observable<Element> {

    private typealias OnCancel = () -> ()

    /// The list of Observers that will be notified when a new value is sent.
    ///
    private var observers = [UUID: Observer<Element>]()

    /// Initialize a new PublishSubject
    ///
    public override init() {
        /// Empty initializer required because observables are in their own package
    }

    public override func subscribe(_ onNext: @escaping OnNext<Element>) -> ObservationToken {
        let uuid = UUID()

        observers[uuid] = Observer(onNext: onNext)

        let onCancel: OnCancel = { [weak self] in
            self?.observers.removeValue(forKey: uuid)
        }

        return ObservationToken(onCancel: onCancel)
    }

    /// Emit a new value. All observers are immediately called with the given value.
    ///
    public func send(_ element: Element) {
        observers.values.forEach { observer in
            observer.send(element)
        }
    }
}
