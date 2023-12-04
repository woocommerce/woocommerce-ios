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
                                TextField("", text: $viewModel.customerCash)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .headlineStyle()
                                    .onTapGesture {
                                        viewModel.customerCash = ""
                                    }
                            }

                            Text(Localization.cashPaymentFootnote)
                                .footnoteStyle()

                            Divider()

                            Text(Localization.dueChangeTitle)
                                .font(.title3)
                                .foregroundColor(Color(.textSubtle))
                            Text(viewModel.dueChange)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(.textSubtle))

                            Spacer()

                            Button(Localization.tenderButtonTitle) {
                                viewModel.onTenderButtonTapped()
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
                                                        value: "Enter the cash amount your customer paid and we'll calculate the change for you. " +
                                                           "Tapping on Tender will mark the order as complete. This data will be added as a note to the order.",
                                                        comment: "Explanatory footnote for the cash payment view.")
        static let dueChangeTitle = NSLocalizedString("cashPaymentTenderView.dueChange",
                                                        value: "Due Change",
                                                        comment: "Title for the due change text.")
        static let tenderButtonTitle = NSLocalizedString("cashPaymentTenderView.tenderButton",
                                                        value: "Tender",
                                                        comment: "Title for the tender button.")
        static let cancelButtonTitle = NSLocalizedString("cashPaymentTenderView.cancelButton",
                                                        value: "Cancel",
                                                        comment: "Title for the cancel button.")
    }
}
