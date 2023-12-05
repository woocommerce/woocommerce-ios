import SwiftUI
import Foundation
import WooFoundation

struct OtherPaymentMethodsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private(set) var viewModel: OtherPaymentMethodsViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.backgroundOpacity).edgesIgnoringSafeArea(.all)

            VStack {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                            Text(String.localizedStringWithFormat(Localization.otherPaymentMethodsTitle, viewModel.formattedTotal))
                                .font(.title3)

                            TextEditor(text: $viewModel.noteText)
                                .cornerRadius(4)
                                .border(Color(.separator), width: 0.5)
                                            .foregroundStyle(.secondary)
                                            .onTapGesture {
                                                viewModel.noteText = ""
                                            }

                            Text(Localization.otherPaymentMethodsFootnote)
                                .footnoteStyle()

                            Spacer()

                            Button(Localization.markOrderAsCompleteTitle) {
                                viewModel.onMarkOrderAsCompleteTapped()
                                dismiss()
                            }
                                .buttonStyle(PrimaryButtonStyle())
                            Button(Localization.cancelButtonTitle) {
                                dismiss()
                            }
                            .buttonStyle(SecondaryButtonStyle())

                        }
                        .padding(Layout.outterPadding)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color(.systemBackground))
                        .cornerRadius(Layout.cornerRadius)
                        .frame(width: geometry.size.width)      // Make the scroll view full-width
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
            .padding(Layout.outterPadding)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

extension OtherPaymentMethodsView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let backgroundOpacity: CGFloat = 0.5
        static let cornerRadius: CGFloat = 8
        static let outterPadding: CGFloat = 24
    }

    enum Localization {
        static let otherPaymentMethodsTitle = NSLocalizedString("otherPaymentMethodsView.title",
                                                        value: "Other Payment Methods: %1$@",
                                                        comment: "Title for the other payment methods view. Reads like Other Payment Methods: $34.45")
        static let otherPaymentMethodsFootnote = NSLocalizedString("otherPaymentMethodsView.footnote",
                                                        value: "Enter an optional note with your custom payment method. The note will be added to the order.",
                                                        comment: "Explanatory footnote for the other payment methods view.")
        static let markOrderAsCompleteTitle = NSLocalizedString("otherPaymentMethodsView.markOrderAsCompleteButton.title",
                                                        value: "Mark order as complete",
                                                        comment: "Title for the mark order as complete button in the other payment methods view.")
        static let cancelButtonTitle = NSLocalizedString("otherPaymentMethods.cancelButton",
                                                        value: "Cancel",
                                                        comment: "Title for the cancel button in the other payment methods screen.")
    }
}
