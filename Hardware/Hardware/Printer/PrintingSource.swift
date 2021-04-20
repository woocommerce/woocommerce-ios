import UIKit
/// View Controllers will have to conform to this
public protocol PrintingSource {
    func print(with: UIViewController)
}
