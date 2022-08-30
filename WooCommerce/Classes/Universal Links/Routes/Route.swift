import UIKit
import Foundation

/// A universal link route, used to encapsulate a URL path and action
/// 
protocol Route {
    var path: String { get }

    func perform(with parameters: [String: String])
}
