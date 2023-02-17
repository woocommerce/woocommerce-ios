import Foundation
import SwiftUI

/// Hosting Controller for the Support Form.
///
final class SupportFormHostingController: UIHostingController<SupportForm> {

    init(viewModel: SupportFormViewModel) {
        super.init(rootView: SupportForm(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Support Form Main View.
/// TODO: Add Landscape & Big Fonts support
///
struct SupportForm: View {

    /// Main ViewModel to drive the view.
    ///
    @StateObject var viewModel: SupportFormViewModel

    var body: some View {
        VStack(spacing: Layout.sectionSpacing) {

            HStack(spacing: -Layout.optionsSpacing) {
                Text(Localization.iNeedHelp)
                    .bold()
                Picker(Localization.iNeedHelp, selection: $viewModel.area) {
                    ForEach(viewModel.areas, id: \.self) { area in
                        Text(area.title).tag(area)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                Text(Localization.subject)
                    .bold()
                TextField("", text: $viewModel.subject)
                    .bodyStyle()
                    .padding(Layout.subjectPadding)
                    .border(Color(.separator))
                    .cornerRadius(Layout.cornerRadius)
            }

            VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                Text(Localization.whatToDo)
                    .bold()
                TextEditor(text: $viewModel.description)
                    .bodyStyle()
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
        static let iNeedHelp = NSLocalizedString("I need help with:", comment: "Text on the support form to refer to what area the user has problem with.")
        static let subject = NSLocalizedString("Subject", comment: "Subject title on the support form")
        static let whatToDo = NSLocalizedString("What are you trying to do?", comment: "Text on the support form to ask the user what are they trying to do.")
        static let submitRequest = NSLocalizedString("Submit Support Request", comment: "Button title to submit a support request.")
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let optionsSpacing: CGFloat = 8
        static let subSectionsSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 2
        static let subjectPadding: CGFloat = 5
    }
}

// MARK: Previews
struct SupportFormProvider: PreviewProvider {

    struct MockDataSource: SupportFormMetaDataSource {
        let formID: Int64 = 0
        let tags: [String] = []
        let customFields: [Int64: String] = [:]
    }

    static var previews: some View {
        NavigationView {
            SupportForm(viewModel: .init(areas: [
                .init(title: "Mobile Aps", datasource: MockDataSource()),
                .init(title: "WooCommerce Payments", datasource: MockDataSource()),
                .init(title: "Other Plugins", datasource: MockDataSource()),
            ]))
        }
    }
}
