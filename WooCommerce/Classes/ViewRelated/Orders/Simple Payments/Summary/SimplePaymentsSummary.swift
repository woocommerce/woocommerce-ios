import SwiftUI

/// View to summarize the Simple Payments order to be created
///
struct SimplePaymentsSummary: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// Needed because IPP capture payments using a UIViewController for providing user feedback.
    ///
    weak var rootViewController: UIViewController?

    /// Defines if the order note screen should be shown or not.
    ///
    @State var showEditNote = false

    /// ViewModel to drive the view content
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

    var body: some View {
        VStack(spacing: 0) {
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
            .ignoresSafeArea(edges: .horizontal)

            TakePaymentSection(viewModel: viewModel)

            // Navigation To Payment Methods
            LazyNavigationLink(destination: SimplePaymentsMethod(dismiss: dismiss,
                                                                 rootViewController: rootViewController,
                                                                 viewModel: viewModel.createMethodsViewModel()),
                               isActive: $viewModel.navigateToPaymentMethods) {
                EmptyView()
            }
        }
        .background(Color(.listBackground).ignoresSafeArea())
        .navigationTitle(Localization.title)
        .sheet(
            isPresented: $showEditNote,
            onDismiss: { // Interactive drag dismiss
                viewModel.noteViewModel.userDidCancelFlow()
                viewModel.reloadContent()
            },
            content: {
                EditCustomerNote(
                    dismiss: { // Cancel button dismiss
                        showEditNote.toggle()
                        viewModel.reloadContent()
                    },
                    viewModel: viewModel.noteViewModel
                )
            })
        .disabled(viewModel.disableViewActions)
    }
}

/// Represents the Custom amount section
///
private struct CustomAmountSection: View {

    /// ViewModel to drive the view content.
    ///
    @ObservedObject private(set) var viewModel: SimplePaymentsSummaryViewModel

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets


    var body: some View {
        Group {
            Divider()

            AdaptiveStack(horizontalAlignment: .leading, spacing: SimplePaymentsSummary.Layout.horizontalStackSpacing) {
                Image(uiImage: .priceImage)
                    .padding()
                    .foregroundColor(Color(.systemGray))
                    .background(Color(.listBackground))
                    .accessibilityHidden(true)

                Text(SimplePaymentsSummary.Localization.customAmount)
                    .headlineStyle()

                Text(viewModel.providedAmount)
                    .headlineStyle()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .bodyStyle()
            .padding()
            .padding(.horizontal, insets: safeAreaInsets)
            .background(Color(.listForeground))
            .accessibilityElement(children: .combine)

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

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        Group {
            Divider()

            TitleAndTextFieldRow(title: SimplePaymentsSummary.Localization.email,
                                 placeholder: SimplePaymentsSummary.Localization.emailPlaceHolder,
                                 text: $viewModel.email,
                                 keyboardType: .emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal, insets: safeAreaInsets)
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

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    var body: some View {
        Group {
            Divider()

            VStack(alignment: .leading, spacing: SimplePaymentsSummary.Layout.verticalSummarySpacing) {

                Text(SimplePaymentsSummary.Localization.payment)
                    .headlineStyle()
                    .padding([.horizontal, .top])

                TitleAndValueRow(title: SimplePaymentsSummary.Localization.subtotal, value: .content(viewModel.providedAmount), selectable: false) {}

                TitleAndToggleRow(title: SimplePaymentsSummary.Localization.chargeTaxes, isOn: $viewModel.enableTaxes)
                    .padding(.horizontal)

                Group {
                    Text(SimplePaymentsSummary.Localization.taxesDisclaimer)
                        .footnoteStyle()
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.showTaxBreakup {
                        ForEach(viewModel.taxLines) { taxLine in
                            TitleAndValueRow(title: taxLine.title,
                                             value: .content(taxLine.value),
                                             selectable: false) {}
                        }
                    } else {
                        TitleAndValueRow(title: SimplePaymentsSummary.Localization.taxRate(viewModel.taxRate),
                                         value: .content(viewModel.taxAmount),
                                         selectable: false) {}
                    }
                }
                .renderedIf(viewModel.enableTaxes)

                TitleAndValueRow(title: SimplePaymentsSummary.Localization.total, value: .content(viewModel.total), bold: true, selectable: false) {}
            }
            .padding(.horizontal, insets: safeAreaInsets)
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

    ///   Environment safe areas
    ///
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

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
            .padding(.horizontal, insets: safeAreaInsets)
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
                .ignoresSafeArea()

            Button(SimplePaymentsSummary.Localization.takePayment(total: viewModel.total), action: {
                viewModel.updateOrder()
            })
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.showLoadingIndicator))
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
        static let orderNote = NSLocalizedString("Customer Provided Note",
                                               comment: "Title text of the row that holds the order note when creating a simple payment")
        static let addNote = NSLocalizedString("Add Note",
                                               comment: "Title text of the button that adds a note when creating a simple payment")
        static let editNote = NSLocalizedString("Edit",
                                               comment: "Title text of the button that edits a note when creating a simple payment")
        static let taxesDisclaimer = NSLocalizedString("Taxes are automatically calculated based on your store address.",
                                                       comment: "Disclaimer in the simple payments summary screen about taxes.")

        static func taxRate(_ rate: String) -> String {
            NSLocalizedString("Tax (\(rate)%)", comment: "Tax percentage to be applied to the simple payments order")
        }

        static func takePayment(total: String) -> String {
            NSLocalizedString("Take Payment (\(total))",
                              comment: "Text of the button that creates a simple payment order. Contains the total amount to collect")
        }
    }
}

// MARK: Previews
struct SimplePaymentsSummary_Preview: PreviewProvider {
    static var previews: some View {
        SimplePaymentsSummary(viewModel: createSampleViewModel())
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light")

        SimplePaymentsSummary(viewModel: createSampleViewModel(noteContent: "Dispatch by tomorrow morning at Fake Street 123, via the boulevard."))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light Content")

        SimplePaymentsSummary(viewModel: createSampleViewModel())
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark")

        SimplePaymentsSummary(viewModel: createSampleViewModel())
            .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
            .previewDisplayName("Accessibility")
    }

    static private func createSampleViewModel(noteContent: String? = nil) -> SimplePaymentsSummaryViewModel {
        let taxAmount = "$2.3"
        let taxLine: SimplePaymentsSummaryViewModel.TaxLine = .init(id: Int64.random(in: 0 ..< Int64.max),
                                                                    title: "State Tax (5.55%)",
                                                                    value: taxAmount)
        return .init(providedAmount: "40.0",
                     totalWithTaxes: "$42.3",
                     taxAmount: taxAmount,
                     taxLines: [taxLine],
                     noteContent: noteContent)
    }
}
