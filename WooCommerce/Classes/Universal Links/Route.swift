import UIKit
import Foundation

protocol Route {
    var path: String { get }
    var action: NavigationAction { get }
}

protocol NavigationAction {
    func perform(_ parameters: [String: String], source: UIViewController?)
}
