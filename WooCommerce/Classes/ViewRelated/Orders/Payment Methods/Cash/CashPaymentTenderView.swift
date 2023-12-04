import SwiftUI
import Foundation

struct CashPaymentTenderView: View {
    let formattedTotal: String
    @State private var customerCash: String

    init(formattedTotal: String) {
        self.formattedTotal = formattedTotal
        customerCash = formattedTotal
    }

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.backgroundOpacity).edgesIgnoringSafeArea(.all)

            VStack {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(alignment: .center, spacing: Layout.verticalSpacing) {
                            Text(formattedTotal + " Cash")
                                .titleStyle()
                            Divider()
                            TextField(formattedTotal, text: $customerCash)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .headlineStyle()
                                .onTapGesture {
                                    customerCash = ""
                                }
                            Text("Enter your customer cash and we calculate the change for you. This will mark your order as complete.")
                                .footnoteStyle()

                            Spacer()

                            Button("Tender") {}
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(customerCash.isEmpty)
                            Button("Cancel", role: .destructive) {
                                // Handle the cancel action
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
