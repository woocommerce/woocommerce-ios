import Foundation
import UIKit
import SwiftUI

struct HIDScannerField: UIViewRepresentable {
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

    func updateUIView(_ uiView: UITextField, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }
}
