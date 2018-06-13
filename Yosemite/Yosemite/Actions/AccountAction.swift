import Foundation


// MARK: - AccountAction: Defines all of the Actions supported by the AccountStore.
//
public enum AccountAction: Action {
    case synchronizeAccountDetails(onCompletion: (Error?) -> Void)
}
