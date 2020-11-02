import Foundation
import Yosemite



// MARK: - DeauthenticatedState
//
class DeauthenticatedState: StoresManagerState {

    /// NO-OP: Executed when current state is activated.
    ///
    func didEnter() { }

    /// NO-OP: Executed before the current state is deactivated.
    ///
    func willLeave() { }

    /// NO-OP: During deauth method, we're not running any actions.
    ///
    func onAction(_ action: Action) { }
}
