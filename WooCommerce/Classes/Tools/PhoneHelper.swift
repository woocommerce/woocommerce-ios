import UIKit

final class PhoneHelper {

    /// Call a specific phone number, and return success or failure
    ///
    static func callPhoneNumber(phone: String?) -> Bool {
        guard let phone = phone, let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) else {
            return false
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        return true
    }
}
