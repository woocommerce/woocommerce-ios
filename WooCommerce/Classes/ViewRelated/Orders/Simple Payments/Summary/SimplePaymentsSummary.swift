import SwiftUI

/// View to summarize the Simple Payments order to be created
///
struct SimplePaymentsSummary: View {

    /// Defines if the order note screen should be shown or not.
    ///
    @State var showEditNote = false

    /// ViewModel to drive the view content
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: Layout.noSpacing) {

                    CustomAmountSection(viewModel: viewModel)

                    Spacer(minLength: Layout.spacerHeight)

                    EmailSection(viewModel: viewModel)

                    Spacer(minLength: Layout.spacerHeight)

                    PaymentsSection(viewModel: viewModel)

                    Spacer(minLength: Layout.spacerHeight)

                    NoteSection(viewModel: viewModel, showEditNote: $showEditNote)
                }
            }

            TakePaymentSection(viewModel: viewModel)
        }
        .background(Color(.listBackground).ignoresSafeArea())
        .navigationTitle(Localization.title)
        .sheet(isPresented: $showEditNote) {
            EditCustomerNote(dismiss: {
                showEditNote.toggle()
                viewModel.reloadContent()
                }, viewModel: viewModel.noteViewModel)
        }
    }
}

/// Represents the Custom amount section
///
private struct CustomAmountSection: View {

    /// ViewModel to drive the view content.
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

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

                Text(viewModel.providedAmount)
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

    /// ViewModel to drive the view content
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

    var body: some View {
        Group {
            Divider()

            TitleAndTextFieldRow(title: SimplePaymentsSummary.Localization.email,
                                 placeholder: SimplePaymentsSummary.Localization.emailPlaceHolder,
                                 text: $viewModel.email,
                                 keyboardType: .emailAddress)
                .background(Color(.listForeground))

            Divider()
        }
    }
}

/// Represents the Payments Section
///
private struct PaymentsSection: View {

    /// ViewModel to drive the view content.
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: SimplePaymentsSummary.Layout.verticalSummarySpacing) {

                Text(SimplePaymentsSummary.Localization.payment)
                    .headlineStyle()
                    .padding([.horizontal, .top])

                TitleAndValueRow(title: SimplePaymentsSummary.Localization.subtotal, value: .content(viewModel.providedAmount), selectable: false) {}

                TitleAndToggleRow(title: SimplePaymentsSummary.Localization.chargeTaxes, isOn: $viewModel.enableTaxes)
                    .padding([.leading, .trailing])

                TitleAndValueRow(title: SimplePaymentsSummary.Localization.total, value: .content(viewModel.total), bold: true, selectable: false) {}
            }
            .background(Color(.listForeground))

            Divider()
        }
    }
}

/// Represents the Order note section
///
private struct NoteSection: View {

    /// ViewModel to drive the view content.
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

    /// Defines if the order note screen should be shown or not.
    ///
    @Binding var showEditNote: Bool

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: SimplePaymentsSummary.Layout.verticalNoteSpacing) {

                HStack {
                    Text(SimplePaymentsSummary.Localization.orderNote)
                        .headlineStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(SimplePaymentsSummary.Localization.editNote) {
                        showEditNote.toggle()
                    }
                    .foregroundColor(Color(.accent))
                    .bodyStyle()
                    .renderedIf(viewModel.noteContent.isNotEmpty)
                }

                noteContent()

            }
            .padding()
            .background(Color(.listForeground))

            Divider()
        }
    }

    /// Builds a button to add a note if no note is present. If there is a note present only displays it
    ///
    @ViewBuilder private func noteContent() -> some View {
        if viewModel.noteContent.isNotEmpty {

            Text(viewModel.noteContent)
                .bodyStyle()

        } else {

            Button(action: {
                showEditNote.toggle()
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
    }
}

/// Represents the bottom take payment button
///
private struct TakePaymentSection: View {

    /// ViewModel to drive the view content.
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

    var body: some View {
        VStack {
            Divider()

            Button(SimplePaymentsSummary.Localization.takePayment(total: viewModel.total), action: {
                print("Take payment pressed")
            })
            .buttonStyle(PrimaryButtonStyle())
            .padding()

        }
        .background(Color(.listForeground).ignoresSafeArea())
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
        static let title = NSLocalizedString("Take Payment", comment: "Title for the simple payments screen")
        static let customAmount = NSLocalizedString("Custom Amount",
                                                    comment: "Title text of the row that shows the provided amount when creating a simple payment")
        static let email = NSLocalizedString("Email",
                                             comment: "Title text of the row that holds the provided email when creating a simple payment")
        static let emailPlaceHolder = NSLocalizedString("Enter Email",
                                                        comment: "Placeholder of the row that holds the provided email when creating a simple payment")
        static let payment = NSLocalizedString("Payment",
                                               comment: "Title text of the row that shows the payment headline when creating a simple payment")
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
        static let editNote = NSLocalizedString("Edit",
                                               comment: "Title text of the button that edits a note when creating a simple payment")

        static func takePayment(total: String) -> String {
            NSLocalizedString("Take Payment (\(total))",
                              comment: "Text of the button that creates a simple payment order. Contains the total amount to collect")
        }
    }
}

// MARK: Previews
struct SimplePaymentsSummary_Preview: PreviewProvider {
    static var previews: some View {
        SimplePaymentsSummary(viewModel: SimplePaymentsSummaryViewModel(providedAmount: "40.0", totalWithTaxes: "$42.3"))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        SimplePaymentsSummary(viewModel: SimplePaymentsSummaryViewModel(
            providedAmount: "$40.0",
            totalWithTaxes: "$42.3",
            noteContent: "Dispatch by tomorrow morning at Fake Street 123, via the boulevard."
        ))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light Content")

        SimplePaymentsSummary(viewModel: SimplePaymentsSummaryViewModel(providedAmount: "$40.0", totalWithTaxes: "$42.3"))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        SimplePaymentsSummary(viewModel: SimplePaymentsSummaryViewModel(providedAmount: "$40.0", totalWithTaxes: "$42.3"))
            .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
            .previewDisplayName("Accessibility")
    }
}
