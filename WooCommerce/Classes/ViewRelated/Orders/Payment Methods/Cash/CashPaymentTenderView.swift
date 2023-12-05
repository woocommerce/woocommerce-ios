import SwiftUI
import Foundation
import WooFoundation

struct CashPaymentTenderView: View {
    @ObservedObject private(set) var viewModel: CashPaymentTenderViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.backgroundOpacity).edgesIgnoringSafeArea(.all)

            VStack {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                            Text(String.localizedStringWithFormat(Localization.cashPaymentTitle, viewModel.formattedTotal))
                                .largeTitleStyle()

                            HStack {
                                Text(Localization.customerPaidTitle)
                                Spacer()
                                TextField("", text: $viewModel.customerPaidAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .headlineStyle()
                                    .onTapGesture {
                                        viewModel.customerPaidAmount = ""
                                        viewModel.didTapOnCustomerPaidTextField = true
                                    }
                            }

                            Text(Localization.cashPaymentFootnote)
                                .footnoteStyle()

                            Divider()

                            Text(Localization.changeDueTitle)
                                .font(.title3)
                                .foregroundColor(Color(.textSubtle))
                            Text(viewModel.changeDue)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(.textSubtle))

                            Toggle(Localization.addNoteToggleTitle, isOn: $viewModel.addNote)

                            Spacer()

                            Button(Localization.markOrderAsCompleteButtonTitle) {
                                viewModel.onMarkOrderAsCompleteButtonTapped()
                                dismiss()
                            }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!viewModel.tenderButtonIsEnabled)
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

extension CashPaymentTenderView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
        static let backgroundOpacity: CGFloat = 0.5
        static let cornerRadius: CGFloat = 8
        static let outterPadding: CGFloat = 24
    }

    enum Localization {
        static let cashPaymentTitle = NSLocalizedString("cashPaymentTenderView.title",
                                                        value: "Cash %1$@",
                                                        comment: "Title for the cash tender view. Reads like Cash $34.45")
        static let customerPaidTitle = NSLocalizedString("cashPaymentTenderView.customerPaid",
                                                        value: "Customer paid",
                                                        comment: "Title for the amount the customer paid.")
        static let cashPaymentFootnote = NSLocalizedString("cashPaymentTenderView.footnote",
                                                        value: "Enter the cash amount your customer paid and we'll calculate the change due for you.",
                                                        comment: "Explanatory footnote for the cash payment view.")
        static let changeDueTitle = NSLocalizedString("cashPaymentTenderView.changeDue",
                                                        value: "Change due",
                                                        comment: "Title for the change due text.")
        static let addNoteToggleTitle = NSLocalizedString("cashPaymentTenderView.addNoteToggle.title",
                                                        value: "Add note with change due to order",
                                                        comment: "Title for the toggle that specifies whether to add a note to the order with the change data.")
        static let markOrderAsCompleteButtonTitle = NSLocalizedString("cashPaymentTenderView.markOrderAsCompleteButton.title",
                                                        value: "Mark order as complete",
                                                        comment: "Title for the Mark order as complete button.")
        static let cancelButtonTitle = NSLocalizedString("cashPaymentTenderView.cancelButton",
                                                        value: "Cancel",
                                                        comment: "Title for the cancel button.")
    }
}
