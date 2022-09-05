import UIKit
import Foundation

/// A universal link route, used to encapsulate a URL path and action
/// 
protocol Route {
    /// The url path to match so this route can perform its navigation
    ///
    var path: String { get }

    /// Performs the action related to this route, usually a navigation.
    /// - Parameter parameters: The parameters dictionary that was contained in the URL
    /// - Returns: Whether the `Route` could perform the action or not.
    ///
    func perform(with parameters: [String: String]) -> Bool
}
