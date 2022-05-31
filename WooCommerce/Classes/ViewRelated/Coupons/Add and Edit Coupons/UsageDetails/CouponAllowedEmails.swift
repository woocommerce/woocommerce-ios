import SwiftUI

/// View to input allowed email formats for coupons
///
struct CouponAllowedEmails: View {
    @ObservedObject private var viewModel: CouponAllowedEmailsViewModel

    init(viewModel: CouponAllowedEmailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                TextField("", text: $viewModel.emailPatterns)
                    .labelsHidden()
                    .padding(.horizontal, Constants.margin)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
                Divider()
                    .padding(.leading, Constants.margin)
                    .padding(.leading, insets: geometry.safeAreaInsets)
                Text(Localization.description)
                    .footnoteStyle()
                    .padding(.horizontal, Constants.margin)
                    .padding(.horizontal, insets: geometry.safeAreaInsets)
            }
            .padding(.top, Constants.topSpacing)
            .ignoresSafeArea(.container, edges: [.horizontal])
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.validateEmails()
                }, label: Localization.done)
            }
        }
    }
}

private extension CouponAllowedEmails {
    enum Constants {
        static let margin: CGFloat = 16
        static let topSpacing: CGFloat = 24
    }

    enum Localization {
        static let title = NSLocalizedString("Allowed Emails", comment: "Title for the Allowed Emails screen")
        static let description = NSLocalizedString(
            "List of allowed billing emails to check against when an order is placed. " +
            "Separate email addresses with commas. You can also use an asterisk (*) " +
            "to match parts of an email. For example \"*@gmail.com\" would match all gmail addresses.",
            comment: "Description of the allowed emails field for coupons")
        static let done = NSLocalizedString("Done", comment: "Done button on the Allowed Emails screen")
    }
}

struct CouponAllowedEmails_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CouponAllowedEmailsViewModel(allowedEmails: "*gmail.com, *@me.com") { _ in }
        CouponAllowedEmails(viewModel: viewModel)
    }
}
