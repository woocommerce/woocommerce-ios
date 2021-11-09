import SwiftUI

/// View to summarize the Simple Payments order to be created
///
struct SimplePaymentsSummary: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: Layout.noSpacing) {

                    Group {

                        Divider()

                        HStack(spacing: Layout.horizontalStackSpacing) {
                            Image(uiImage: .priceImage)
                                .padding()
                                .foregroundColor(Color(.systemGray))
                                .background(Color(.listBackground))

                            Text("Custom Amount")

                            Spacer()

                            Text("$40.00")
                        }
                        .bodyStyle()
                        .padding()
                        .background(Color(.listForeground))

                        Divider()
                        Spacer(minLength: Layout.spacerHeight)
                    }

                    Group {
                        Divider()
                        TitleAndTextFieldRow(title: "Email", placeholder: "Enter Email", text: .constant(""))
                            .background(Color(.listForeground))
                        Divider()
                        Spacer(minLength: Layout.spacerHeight)
                    }

                    Group {
                        Divider()
                        VStack(alignment: .leading, spacing: Layout.verticalSummarySpacing) {

                            Text("Payment")
                                .headlineStyle()
                                .padding([.horizontal, .top])

                            TitleAndValueRow(title: "Subtotal", value: .content("$40.0"), selectable: false) {}

                            TitleAndToggleRow(title: "Charge Taxes", isOn: .constant(false))
                                .padding([.leading, .trailing])

                            // TODO: Update this to be able to inject proper style values
                            TitleAndValueRow(title: "Order Total", value: .content("$40.0"), selectable: false) {}
                        }
                        .background(Color(.listForeground))

                        Divider()
                        Spacer(minLength: Layout.spacerHeight)
                    }

                    Group {
                        Divider()

                        VStack(alignment: .leading, spacing: Layout.verticalNoteSpacing) {
                            Text("Order Note")
                                .headlineStyle()

                            Button(action: {
                                print("Tapped add note")
                            }, label: {
                                HStack() {
                                    Image(uiImage: .plusImage)

                                    Text("Add Note")

                                    Spacer()
                                }
                                .foregroundColor(Color(.accent))
                                .bodyStyle()
                            })
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color(.listForeground))

                        Divider()
                    }

                }
            }

            VStack {
                Divider()

                Button("Take Payment ($40.0)", action: {
                    print("Take payment pressed")
                })
                .buttonStyle(PrimaryButtonStyle())
                .padding()

            }
            .background(Color(.listForeground))
        }
        .background(Color(.listBackground))
    }
}

// MARK: Constants
private extension SimplePaymentsSummary {
    enum Layout {
        static let spacerHeight: CGFloat = 16.0
        static let horizontalStackSpacing: CGFloat = 16.0
        static let verticalSummarySpacing: CGFloat = 8.0
        static let verticalNoteSpacing: CGFloat = 22.0
        static let noSpacing: CGFloat = 0.0
    }
}

// MARK: Previews
struct SimplePaymentsSummary_Preview: PreviewProvider {
    static var previews: some View {
        SimplePaymentsSummary()
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        SimplePaymentsSummary()
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        SimplePaymentsSummary()
            .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
            .previewDisplayName("Accessibility")
    }
}
