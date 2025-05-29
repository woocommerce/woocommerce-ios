import Foundation
import UIKit
import SwiftUI

@available(iOS 17.0, *)
struct HIDScannerField: UIViewRepresentable {
    @Environment(AppInputFocusState.self) private var inputFocus

    class Coordinator: NSObject, UITextFieldDelegate {
        var onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Optional: accumulate characters or check for full scan in real-time
            return true
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            if let text = textField.text, text.count > 3 {
                onScan(text)
                textField.text = "" // Clear for next scan
            }
        }
    }

    var onScan: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField(frame: .zero)
        field.delegate = context.coordinator
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.keyboardType = .asciiCapable
        field.isHidden = true
        field.isAccessibilityElement = false

        // 🧙‍♂️ Magic line to suppress software keyboard
        field.inputView = UIView()

        DispatchQueue.main.async {
            field.becomeFirstResponder() // Start scanning
        }
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let shouldBeFocused = inputFocus.activeInput == .none

            switch (shouldBeFocused, field.isFirstResponder) {
            case (true, false):
                field.becomeFirstResponder()
            case (false, true):
                field.resignFirstResponder()
            case (false, false), (true, true):
                break
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
}
