import SwiftUI

/// View to summarize the Simple Payments order to be created
///
struct SimplePaymentsSummary: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: Layout.noSpacing) {

                    CustomAmountSection()

                    Spacer(minLength: Layout.spacerHeight)

                    EmailSection()

                    Spacer(minLength: Layout.spacerHeight)

                    PaymentsSection()

                    Spacer(minLength: Layout.spacerHeight)

                    NoteSection()
                }
            }

            TakePaymentSection()
        }
        .background(Color(.listBackground))
    }
}

/// Represents the Custom amount section
///
private struct CustomAmountSection: View {
    var body: some View {
        Group {
            Divider()

            AdaptiveStack(horizontalAlignment: .leading, spacing: SimplePaymentsSummary.Layout.horizontalStackSpacing) {
                Image(uiImage: .priceImage)
                    .padding()
                    .foregroundColor(Color(.systemGray))
                    .background(Color(.listBackground))

                Text(SimplePaymentsSummary.Localization.customAmount)
                    .headlineStyle()

                // Temporary data
                Text("$40.00")
                    .headlineStyle()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .bodyStyle()
            .padding()
            .background(Color(.listForeground))

            Divider()
        }
    }
}

/// Represents the email section
///
private struct EmailSection: View {
    var body: some View {
        Group {
            Divider()

            TitleAndTextFieldRow(title: SimplePaymentsSummary.Localization.email,
                                 placeholder: SimplePaymentsSummary.Localization.emailPlaceHolder,
                                 text: .constant(""))
                .background(Color(.listForeground))

            Divider()
        }
    }
}

/// Represents the Payments Section
///
private struct PaymentsSection: View {
    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: SimplePaymentsSummary.Layout.verticalSummarySpacing) {

                Text(SimplePaymentsSummary.Localization.payment)
                    .headlineStyle()
                    .padding([.horizontal, .top])

                // Temporary data
                TitleAndValueRow(title: SimplePaymentsSummary.Localization.subtotal, value: .content("$40.0"), selectable: false) {}

                // Temporary data
                TitleAndToggleRow(title: SimplePaymentsSummary.Localization.chargeTaxes, isOn: .constant(false))
                    .padding([.leading, .trailing])

                // Temporary data
                TitleAndValueRow(title: SimplePaymentsSummary.Localization.total, value: .content("$40.0"), bold: true, selectable: false) {}
            }
            .background(Color(.listForeground))

            Divider()
        }
    }
}

/// Represents the Order note section
///
private struct NoteSection: View {
    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: SimplePaymentsSummary.Layout.verticalNoteSpacing) {
                Text(SimplePaymentsSummary.Localization.orderNote)
                    .headlineStyle()

                Button(action: {
                    print("Tapped add note")
                }, label: {
                    HStack() {
                        Image(uiImage: .plusImage)

                        Text(SimplePaymentsSummary.Localization.addNote)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

/// Represents the bottom take payment button
///
private struct TakePaymentSection: View {
    var body: some View {
        VStack {
            Divider()

            // Temporary data
            Button(SimplePaymentsSummary.Localization.takePayment(total: "$40.0"), action: {
                print("Take payment pressed")
            })
            .buttonStyle(PrimaryButtonStyle())
            .padding()

        }
        .background(Color(.listForeground))
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

    enum Localization {
        static let customAmount = NSLocalizedString("Custom Amount",
                                                    comment: "Title text of the row that shows the provided amount when creating a simple payment")
        static let email = NSLocalizedString("Email",
                                             comment: "Title text of the row that holds the provided email when creating a simple payment")
        static let emailPlaceHolder = NSLocalizedString("Enter Email",
                                                        comment: "Placeholder of the row that holds the provided email when creating a simple payment")
        static let payment = NSLocalizedString("Payment",
                                               comment: "Title text of the row that shows that list the payment when creating a simple payment")
        static let subtotal = NSLocalizedString("Subtotal",
                                               comment: "Title text of the row that shows the subtotal when creating a simple payment")
        static let chargeTaxes = NSLocalizedString("Charge Taxes",
                                               comment: "Title text of the row that has a switch when creating a simple payment")
        static let total = NSLocalizedString("Order Total",
                                               comment: "Title text of the row that shows the total to charge when creating a simple payment")
        static let orderNote = NSLocalizedString("Order Note",
                                               comment: "Title text of the row that holds the order note when creating a simple payment")
        static let addNote = NSLocalizedString("Add Note",
                                               comment: "Title text of the button that adds a note when creating a simple payment")

        static func takePayment(total: String) -> String {
            NSLocalizedString("Take Payment (\(total))",
                              comment: "Text of the button that creates a simple payment order. Contains the total amount to collect")
        }
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
