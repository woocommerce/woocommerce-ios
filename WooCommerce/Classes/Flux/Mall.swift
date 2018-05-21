import Foundation
import FluxSumi


// MARK: - A Mall contains pointers to the active Stores. Ain't that a cool name?
//
class Mall {

    /// Shared Mall Instance!
    ///
    static let shared = Mall()

    /// Shared Dispatcher
    ///
    let dispatcher = Dispatcher.global

    /// Account Store
    ///
    let orderStore = OrderStore()



    /// Convenience method to dispatch an Action
    ///
    func dispatch(_ action: Action) {
        dispatcher.dispatch(action)
    }
}
