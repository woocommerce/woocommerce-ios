import Foundation
import SwiftUI

struct SupportForm: View {

    @State private var favoriteColor = 0
    var body: some View {
        VStack(spacing: Layout.sectionSpacing) {

            HStack(spacing: -Layout.optionsSpacing) {
                Text(Localization.iNeedHelp)
                    .bold()
                Picker(Localization.iNeedHelp, selection: $favoriteColor) {
                    Text("Mobile App").tag(0)
                    Text("Card Reader/In-Person Payments").tag(1)
                    Text("WooCommerce Payments").tag(2)
                    Text("WooCommerce Plugin").tag(3)
                    Text("Other extension/plugin").tag(4)
                }
                .pickerStyle(.menu)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                Text(Localization.subject)
                    .bold()
                TextField("", text: .constant(""))
                    .titleStyle()
                    .border(Color(.separator))
                    .cornerRadius(Layout.cornerRadius)
            }

            VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                Text(Localization.whatToDo)
                    .bold()
                TextEditor(text: .constant(""))
                    .border(Color(.separator))
                    .cornerRadius(Layout.cornerRadius)
            }

            Button {
                // No Op
            } label: {
                Text(Localization.submitRequest)
            }
            .buttonStyle(PrimaryButtonStyle())

        }
        .padding()
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
    }
}

// MARK: Constants
private extension SupportForm {
    enum Localization {
        static let title = NSLocalizedString("Contact Support", comment: "Title of the view for contacting support.")
        static let iNeedHelp = NSLocalizedString("I need help with", comment: "Text on the support form to refer to what area the user has problem with.")
        static let subject = NSLocalizedString("Subject", comment: "Subject title on the support form")
        static let whatToDo = NSLocalizedString("What are you trying to do?", comment: "Text on the support form to ask the user what are they trying to do.")
        static let submitRequest = NSLocalizedString("Submit Support Request", comment: "Button title to submit a support request.")
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let optionsSpacing: CGFloat = 8
        static let subSectionsSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 2
    }
}

// MARK: Previews
struct SupportFormProvider: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupportForm()
        }
    }
}
