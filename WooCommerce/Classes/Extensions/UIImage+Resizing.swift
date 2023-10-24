import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        self.draw(in: CGRect(origin: .zero, size: size))
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
