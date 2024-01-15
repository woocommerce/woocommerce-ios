import SwiftUI
import Foundation
import WooFoundation

struct CashPaymentTenderView: View {
    @StateObject private var viewModel: CashPaymentTenderViewModel
    @Environment(\.dismiss) var dismiss

    init(viewModel: CashPaymentTenderViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: Layout.sectionVerticalSpacing) {
                        Text(Localization.customerPaidTitle)
                            .foregroundColor(Color(.secondaryLabel))
                        FormattableAmountTextField(viewModel: viewModel.formattableAmountViewModel)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .font(.system(size: Layout.amountFontSize, weight: .bold))
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        viewModel.onCustomerPaidAmountTapped()
                                    }
                            )
                    }
                    .padding(Layout.sectionPadding)

                    Divider()
                        .padding(.leading, Layout.dividerHorizontalPadding)

                    VStack(alignment: .leading, spacing: Layout.sectionVerticalSpacing) {
                        Text(Localization.changeDueTitle)
                            .foregroundColor(Color(.secondaryLabel))
                        Text(viewModel.changeDue)
                            .font(.system(size: Layout.amountFontSize, weight: .bold))
                            .foregroundColor(Color(.label))
                            .opacity(viewModel.hasChangeDue ? 1: 0.18)
                    }
                    .padding(Layout.sectionPadding)

                    Toggle(Localization.addNoteToggleTitle, isOn: $viewModel.addNote)
                        .padding(Layout.togglePadding)
                }
            }

            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .foregroundColor(Color(.separator))

                Button(Localization.markOrderAsCompleteButtonTitle) {
                    viewModel.onMarkOrderAsCompleteButtonTapped()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!viewModel.tenderButtonIsEnabled)
                .padding(insets: Layout.buttonPadding)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(String(format: Localization.navigationBarTitle, viewModel.formattedTotal))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    withAnimation {
                        dismiss()
                    }
                }, label: {
                    Text(Localization.cancelButtonTitle)
                })
            }
        }
    }
}

extension CashPaymentTenderView {
    enum Layout {
        static let amountFontSize: CGFloat = 48
        static let verticalSpacing: CGFloat = 24
        static let dividerHorizontalPadding: CGFloat = 16
        static let sectionPadding: EdgeInsets = .init(top: 24, leading: 16, bottom: 8, trailing: 16)
        static let sectionVerticalSpacing: CGFloat = 4
        static let togglePadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        static let buttonPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    }

    enum Localization {
        static let customerPaidTitle = NSLocalizedString(
            "cashPaymentTenderView.customerPaid",
            value: "Cash received",
            comment: "Title for the amount the customer paid."
        )
        static let changeDueTitle = NSLocalizedString(
            "cashPaymentTenderView.changeDue",
            value: "Change due",
            comment: "Title for the change due text."
        )
        static let addNoteToggleTitle = NSLocalizedString(
            "cashPaymentTenderView.addNoteToggle.title",
            value: "Record transaction details in order note",
            comment: "Title for the toggle that specifies whether to add a note to the order with the change data."
        )
        static let markOrderAsCompleteButtonTitle = NSLocalizedString(
            "cashPaymentTenderView.markOrderAsCompleteButton.title",
            value: "Mark Order as Complete",
            comment: "Title for the Mark order as complete button."
        )
        static let cancelButtonTitle = NSLocalizedString(
            "cashPaymentTenderView.cancelButton",
            value: "Cancel",
            comment: "Title for the cancel button."
        )
        static let navigationBarTitle = NSLocalizedString(
            "cashPaymentTenderView.navigationBarTitle",
            value: "Take Payment (%1$@)",
            comment: "Navigation bar title for the cash tender view. Reads like 'Take Payment ($34.45)'"
        )
    }
}

// MARK: Previews

struct CashPaymentTenderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {}
            .sheet(isPresented: .constant(true), content: {
                NavigationView {
                    CashPaymentTenderView(viewModel: CashPaymentTenderViewModel(formattedTotal: "$10.6") { _ in })
                }
            })
    }
}
