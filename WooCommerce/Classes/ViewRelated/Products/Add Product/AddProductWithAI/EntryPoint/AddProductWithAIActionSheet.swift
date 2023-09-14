import SwiftUI

/// View to show options for adding a new product including one with AI assistance.
///
struct AddProductWithAIActionSheet: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

private extension AddProductWithAIActionSheet {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let margin: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString(
            "Add a product",
            comment: "Title on the action sheet to select an option for adding new product"
        )
        static let aiTitle = NSLocalizedString(
            "Create a product with AI",
            comment: "Title of the option to add new product with AI assistance"
        )
        static let aiDescription = NSLocalizedString(
            "Quickly generate details for you",
            comment: "Description of the option to add new product with AI assistance"
        )
        static let manualTitle = NSLocalizedString(
            "Add manually",
            comment: "Title of the option to add new product manually"
        )
        static let manualDescription = NSLocalizedString(
            "Add a product and the details manually",
            comment: "Description of the option to add new product manually"
        )
    }
}

struct AddProductWithAIActionSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddProductWithAIActionSheet()
    }
}
