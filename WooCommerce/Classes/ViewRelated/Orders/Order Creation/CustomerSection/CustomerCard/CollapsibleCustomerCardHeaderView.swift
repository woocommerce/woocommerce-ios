import SwiftUI
import Yosemite

/// Header view in the order form customer card that shows the customer email and address if available.
struct CollapsibleCustomerCardHeaderView: View {
    /// Whether the customer card is currently collapsed.
    let isCollapsed: Bool
    /// Optional customer email.
    let email: String?
    /// Placeholder of the email text field.
    let emailPlaceholder: String
    /// Optional customer shipping address that is ready to be shown in the header.
    let shippingAddress: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            CustomerEmailView(email: email, placeholder: emailPlaceholder)

            if let shippingAddress, shippingAddress.isNotEmpty, isCollapsed {
                Group {
                    Divider()
                    Text(shippingAddress)
                }
            }
        }
    }
}

private extension CollapsibleCustomerCardHeaderView {
    enum Layout {
        static let verticalSpacing: CGFloat = 16
    }
}

private struct CustomerEmailView: View {
    let email: String?
    let placeholder: String

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            if let email, email.isNotEmpty {
                Text(email)
            } else {
                Text(placeholder)
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
        }
    }

    enum Layout {
        static let imageSize: CGFloat = 26
    }
}

struct CollapsibleCustomerCardHeaderView_Previews: PreviewProvider {
    static let address: Address = .init(firstName: "Customer",
                                        lastName: "Woo",
                                        company: nil,
                                        address1: "60 30th St",
                                        address2: nil,
                                        city: "San Francisco",
                                        state: "CA",
                                        postcode: "94123",
                                        country: "USA",
                                        phone: nil,
                                        email: nil)
    static var previews: some View {
        CollapsibleCustomerCardHeaderView(isCollapsed: true,
                                          email: nil,
                                          emailPlaceholder: "Email address required",
                                          shippingAddress: nil)
        CollapsibleCustomerCardHeaderView(isCollapsed: true,
                                          email: "customer@woo.com",
                                          emailPlaceholder: "Email address required",
                                          shippingAddress: "Test Woo\n111 28th St")
    }
}
