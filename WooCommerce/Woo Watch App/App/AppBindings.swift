import Foundation

/// Keeps track of all the bindings that are needed through the app lifecycle.
/// This type is meant to be passed as an environment variable
///
class AppBindings: NSObject, ObservableObject {
    
    /// Determines when an order notification arrives and should be presented.
    ///
    @Published var presentNote = false
}
