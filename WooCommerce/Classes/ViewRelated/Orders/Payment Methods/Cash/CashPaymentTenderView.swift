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
                            Text(viewModel.formattedTotal + " Cash")
                                .largeTitleStyle()
                            TextField("", text: $viewModel.customerCash)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .headlineStyle()
                                .onTapGesture {
                                    viewModel.customerCash = ""
                                }

                            Text("Enter your customer paid cash and we'll calculate the change for you. Tapping on Tender will mark your order as complete.")
                                .footnoteStyle()

                            Divider()

                            Text("Due Change")
                                .font(.title3)
                                .foregroundColor(Color(.textSubtle))
                            Text(viewModel.dueChange)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(.textSubtle))

                            Spacer()

                            Button("Tender") {
                                viewModel.onTenderButtonTapped()
                                dismiss()
                            }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(!viewModel.tenderButtonIsEnabled)
                            Button("Cancel", role: .destructive) {
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
}
