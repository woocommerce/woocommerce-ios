import UIKit
import Foundation

/// A universal link route, used to encapsulate a URL path and action
/// 
protocol Route {
    /// Whether the route can handle a universal link subpath (without the /mobile segment) to be matched so this route can perform its navigation
    ///
    func canHandle(subPath: String) -> Bool

    /// Performs the action related to this route, usually a navigation.
    /// - Parameter subPath: The subpath which was matched from the URL
    /// - Parameter parameters: The parameters dictionary that was contained in the URL
    /// - Returns: Whether the `Route` could perform the action or not.
    ///
    func perform(for subPath: String, with parameters: [String: String]) -> Bool
}
