import SwiftUI
import UIKit
import WooFoundation

/// This numeric Text Field updates the user input to show the formatted amount
///
struct FormattableAmountTextField: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var focusRequestID = 0

    @ObservedObject private var viewModel: FormattableAmountTextFieldViewModel
    private let isFocused: Binding<Bool>
    private let style: Style

    init(viewModel: FormattableAmountTextFieldViewModel, style: Style = .default, isFocused: Binding<Bool>? = nil) {
        self.viewModel = viewModel
        self.style = style
        self.isFocused = isFocused ?? Binding(
            get: { viewModel.isFocused },
            set: { viewModel.isFocused = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .center) {
            FocusableHiddenInputTextField(text: $viewModel.textFieldAmountText,
                                          isFocused: isFocused,
                                          focusRequestID: focusRequestID,
                                          keyboardType: viewModel.allowNegativeNumber ? .numbersAndPunctuation : .decimalPad)
                .onChange(of: viewModel.textFieldAmountText) { _, newValue in
                    viewModel.updateAmount(newValue)
                }
                .frame(maxWidth: .infinity, minHeight: Layout.inputHeight(size: viewModel.amountTextSize.fontSize, scale: scale))

            Text(BidirectionalText.isolateLeftToRightNumericRuns(in: viewModel.formattedAmount,
                                                                 separators: viewModel.numericTextSeparators))
                .font(style.font ?? .system(size: Layout.amountFontSize(size: viewModel.amountTextSize.fontSize, scale: scale), weight: .bold))
                .foregroundColor(Color(viewModel.amountTextColor))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: style.textAlignment)
                .padding(5)
                .allowsHitTesting(false)
                .if(isFocused.wrappedValue && style.showsBorder, transform: { field in
                    field.roundedBorder(cornerRadius: 8, lineColor: Color(.wooCommercePurple(.shade60)), lineWidth: 1)
                })
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: requestFocus)
        .fixedSize(horizontal: false, vertical: true)
        .restoresInputFocus(when: isFocused.wrappedValue, restoreFocus: restoreFocusIfNeeded)
    }
}

extension FormattableAmountTextField {
    struct Style: Equatable {
        let showsBorder: Bool
        let textAlignment: Alignment
        /// Optional font to use for the amount text. If nil, a default system font will be used.
        let font: Font?

        static let `default` = Style(
            showsBorder: true,
            textAlignment: .leading,
            font: nil
        )
    }
}

private extension FormattableAmountTextField {
    enum Layout {
        static func amountFontSize(size: CGFloat, scale: CGFloat) -> CGFloat {
            size * scale
        }

        static func inputHeight(size: CGFloat, scale: CGFloat) -> CGFloat {
            amountFontSize(size: size, scale: scale) + 10
        }
    }

    func requestFocus() {
        isFocused.wrappedValue = true
        focusRequestID += 1
    }

    func restoreFocusIfNeeded() {
        guard isFocused.wrappedValue else { return }

        requestFocus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard isFocused.wrappedValue else { return }
            focusRequestID += 1
        }
    }
}

extension View {
    func restoresInputFocus(when isFocused: Bool, restoreFocus: @escaping () -> Void) -> some View {
        modifier(InputFocusRestorationModifier(isFocused: isFocused, restoreFocus: restoreFocus))
    }
}

private struct InputFocusRestorationModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let isFocused: Bool
    let restoreFocus: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear(perform: restoreFocusIfNeeded)
            .onChange(of: isFocused) { _, shouldFocus in
                guard shouldFocus else { return }
                restoreFocus()
            }
            .onChange(of: horizontalSizeClass) { _, _ in
                restoreFocusIfNeeded()
            }
            .onChange(of: verticalSizeClass) { _, _ in
                restoreFocusIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                restoreFocusIfNeeded()
            }
    }

    private func restoreFocusIfNeeded() {
        guard isFocused else { return }
        restoreFocus()
    }
}

struct FocusableHiddenInputTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let focusRequestID: Int
    let keyboardType: UIKeyboardType

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textColor = .clear
        textField.tintColor = .clear
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self

        if textField.text != text {
            textField.text = text
        }

        if textField.keyboardType != keyboardType {
            textField.keyboardType = keyboardType
            textField.reloadInputViews()
        }

        if isFocused {
            context.coordinator.focus(textField, requestID: focusRequestID)
        } else {
            context.coordinator.blur(textField)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FocusableHiddenInputTextField
        private var handledFocusRequestID: Int?

        init(parent: FocusableHiddenInputTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            let updatedText = textField.text ?? ""
            guard parent.text != updatedText else { return }
            parent.text = updatedText
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            guard parent.isFocused == false else { return }
            parent.isFocused = true
        }

        func focus(_ textField: UITextField, requestID: Int) {
            guard handledFocusRequestID != requestID else { return }

            handledFocusRequestID = requestID
            DispatchQueue.main.async { [weak self, weak textField] in
                guard self?.parent.isFocused == true,
                      self?.handledFocusRequestID == requestID else {
                    return
                }

                textField?.becomeFirstResponder()
            }
        }

        func blur(_ textField: UITextField) {
            handledFocusRequestID = nil

            guard textField.isFirstResponder else { return }

            DispatchQueue.main.async { [weak textField] in
                textField?.resignFirstResponder()
            }
        }
    }
}

#Preview {
    let viewModel = FormattableAmountTextFieldViewModel(size: .extraLarge,
                                                        locale: .current,
                                                        storeCurrencySettings: .init(),
                                                        allowNegativeNumber: false)
    VStack {
        Text("Default style")
        FormattableAmountTextField(viewModel: viewModel, style: .default)
    }
    VStack {
        Text("Other style")
        FormattableAmountTextField(viewModel: viewModel, style: .init(showsBorder: false, textAlignment: .center, font: .title2))
    }
}
