import UIKit
import Foundation

protocol Route {
    var path: String { get }
    var action: NavigationAction { get }
}

protocol NavigationAction {
    func perform(with parameters: [String: String])
}
