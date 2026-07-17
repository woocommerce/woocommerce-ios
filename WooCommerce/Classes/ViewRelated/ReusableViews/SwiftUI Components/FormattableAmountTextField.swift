import SwiftUI
import UIKit
import WooFoundation

/// This numeric Text Field updates the user input to show the formatted amount
///
struct FormattableAmountTextField: View {
    @ScaledMetric private var scale: CGFloat = 1.0
    @FocusState private var defaultFieldIsFocused: Bool

    @ObservedObject private var viewModel: FormattableAmountTextFieldViewModel
    private let isFocused: Binding<Bool>
    private let fieldFocus: FocusState<Bool>.Binding?
    private let style: Style

    init(viewModel: FormattableAmountTextFieldViewModel,
         style: Style = .default,
         isFocused: Binding<Bool>? = nil,
         fieldFocus: FocusState<Bool>.Binding? = nil) {
        self.viewModel = viewModel
        self.style = style
        self.isFocused = isFocused ?? Binding(
            get: { viewModel.isFocused },
            set: { viewModel.isFocused = $0 }
        )
        self.fieldFocus = fieldFocus
    }

    var body: some View {
        let fieldFocus = fieldFocus ?? $defaultFieldIsFocused

        TextField("", text: amountText, prompt: amountPlaceholder)
            .keyboardType(viewModel.allowNegativeNumber ? .numbersAndPunctuation : .decimalPad)
            .textFieldStyle(.plain)
            .focused(fieldFocus)
            .font(style.font ?? .system(size: Layout.amountFontSize(size: viewModel.amountTextSize.fontSize, scale: scale), weight: .bold))
            .foregroundColor(Color(viewModel.amountTextColor))
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .multilineTextAlignment(style.multilineTextAlignment)
            .frame(maxWidth: .infinity, minHeight: Layout.inputHeight(size: viewModel.amountTextSize.fontSize, scale: scale), alignment: style.textAlignment)
            .padding(5)
            .if(isFocused.wrappedValue && style.showsBorder, transform: { field in
                field.roundedBorder(cornerRadius: 8, lineColor: Color(.wooCommercePurple(.shade60)), lineWidth: 1)
            })
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                syncFocusFromBinding(fieldFocus)
            }
            .onChange(of: fieldFocus.wrappedValue) { _, fieldIsFocused in
                guard isFocused.wrappedValue != fieldIsFocused else { return }
                isFocused.wrappedValue = fieldIsFocused
            }
            .onChange(of: isFocused.wrappedValue) { _, shouldFocus in
                guard fieldFocus.wrappedValue != shouldFocus else { return }
                fieldFocus.wrappedValue = shouldFocus
            }
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
    var amountText: Binding<String> {
        Binding(
            get: {
                viewModel.editableFormattedAmount
            },
            set: { newValue in
                viewModel.updateEditableFormattedAmount(newValue)
            }
        )
    }

    var amountPlaceholder: Text {
        Text(BidirectionalText.isolateLeftToRightNumericRuns(in: viewModel.formattedAmount,
                                                             separators: viewModel.numericTextSeparators))
    }

    enum Layout {
        static func amountFontSize(size: CGFloat, scale: CGFloat) -> CGFloat {
            size * scale
        }

        static func inputHeight(size: CGFloat, scale: CGFloat) -> CGFloat {
            // Match the field's tappable height to the visible amount text's 5-point vertical padding.
            amountFontSize(size: size, scale: scale) + 10
        }
    }

    func syncFocusFromBinding(_ fieldFocus: FocusState<Bool>.Binding) {
        fieldFocus.wrappedValue = isFocused.wrappedValue
    }
}

private extension FormattableAmountTextField.Style {
    var multilineTextAlignment: TextAlignment {
        switch textAlignment {
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            return .leading
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
