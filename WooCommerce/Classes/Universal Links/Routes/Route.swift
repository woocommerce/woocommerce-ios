import UIKit
import Foundation

/// A universal link route, used to encapsulate a URL path and action
/// 
protocol Route {
    /// The universal link subpath (without the /mobile segment) to be matched so this route can perform its navigation
    ///
    var subPath: String { get }

    /// Performs the action related to this route, usually a navigation.
    /// - Parameter parameters: The parameters dictionary that was contained in the URL
    /// - Returns: Whether the `Route` could perform the action or not.
    ///
    func perform(with parameters: [String: String]) -> Bool
}
