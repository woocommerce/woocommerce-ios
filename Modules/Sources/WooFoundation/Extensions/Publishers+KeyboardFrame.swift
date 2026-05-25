import Combine
import Foundation
import UIKit

public extension Publishers {
    /// This publisher provides the height of the keyboard
    ///
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        return keyboardFrame
            .map { $0.height }
            .eraseToAnyPublisher()
    }

    /// This publisher provides the frame of the keyboard
    ///
    static var keyboardFrame: AnyPublisher<CGRect, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { $0.keyboardFrame }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGRect.zero }

        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

private extension Notification {
    var keyboardFrame: CGRect {
        guard let userInfo,
              let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return .zero
        }

        return keyboardFrameValue.cgRectValue
    }
}
