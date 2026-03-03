import SwiftUI
import UIKit

/// Provides access to the underlying `UITextField` of a SwiftUI `TextField`.
///
/// Places an invisible `UIView` as a background, then traverses the view
/// hierarchy upward to find the nearest `UITextField` sibling.
extension View {
    func configureUnderlyingTextField(_ configure: @escaping (UITextField) -> Void) -> some View {
        background(
            TextFieldFinderRepresentable(configure: configure)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibility(hidden: true)
        )
    }
}

private struct TextFieldFinderRepresentable: UIViewRepresentable {
    let configure: (UITextField) -> Void

    func makeUIView(context: Context) -> TextFieldFinderView {
        TextFieldFinderView(configure: configure)
    }

    func updateUIView(_ uiView: TextFieldFinderView, context: Context) {}
}

private final class TextFieldFinderView: UIView {
    private let configure: (UITextField) -> Void

    init(configure: @escaping (UITextField) -> Void) {
        self.configure = configure
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }

        // Defer to next layout pass so the full hierarchy is in place.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let textField = self.findTextField() {
                self.configure(textField)
            }
        }
    }

    private func findTextField() -> UITextField? {
        // Walk up to find the nearest common container, then search its
        // descendants for the UITextField (which is a sibling subtree
        // when this view is placed as a .background on a TextField).
        var ancestor: UIView? = superview
        while let current = ancestor {
            if let match = Self.firstDescendant(ofType: UITextField.self, in: current) {
                return match
            }
            ancestor = current.superview
        }
        return nil
    }

    private static func firstDescendant<T: UIView>(ofType type: T.Type, in view: UIView) -> T? {
        if let match = view as? T {
            return match
        }
        for subview in view.subviews {
            if let match = firstDescendant(ofType: type, in: subview) {
                return match
            }
        }
        return nil
    }
}

// MARK: - Number Pad Popover

extension View {
    /// Disables the numpad popover on iPadOS 26+.
    ///
    /// By default the popover numpad alternates with a full-screen keyboard on
    /// consecutive taps, intercepts gestures preventing buttons from responding
    /// on first tap, and is a poor fit for a large iPad input view. Forcing the
    /// docked keyboard avoids all three issues.
    func disableNumberPadPopover() -> some View {
        configureUnderlyingTextField { textField in
            if #available(iOS 26, *) {
                textField.allowsNumberPadPopover = false
            }
        }
    }
}
