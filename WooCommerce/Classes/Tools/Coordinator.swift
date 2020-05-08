import Foundation
import UIKit

/// A basic coordinator design pattern to help decouple things.
/// See: http://khanlou.com/2015/01/the-coordinator/
///
protocol Coordinator {
    // TODO Not sure if it's a good idea to expose this.
    var navigationController: UINavigationController { get set }

    func start()
}
