import SwiftUI
import Foundation
import WooFoundation

struct CashPaymentTenderView: View {
    let formattedTotal: String
    @Environment(\.dismiss) var dismiss
    @State private var customerCash: String = ""
    @FocusState private var customerCashIsFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.backgroundOpacity).edgesIgnoringSafeArea(.all)

            VStack {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                            Text(formattedTotal + " Cash")
                                .largeTitleStyle()
                            TextField(formattedTotal, text: $customerCash)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .headlineStyle()
                                .onTapGesture {
                                    customerCash = ""
                                }
                                .focused($customerCashIsFocused)

                            Text("Enter your customer cash and we calculate the change for you. Tapping on Tender will mark your order as complete.")
                                .footnoteStyle()

                            Divider()

                            Group {
                                Text("Change")
                                    .font(.title3)
                                    .foregroundColor(Color(.textSubtle))
                                Text(formattedTotal)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(Color(.textSubtle))
                            }

                            Spacer()

                            Button("Tender") {}
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(customerCash.isEmpty)
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
                        .onAppear {
                            customerCash = formattedTotal
                        }

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
