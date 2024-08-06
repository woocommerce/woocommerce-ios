import SwiftUI

// MARK: Hosting Controller

/// Hosting controller that wraps a `ProductCustomFields` view.
///

final class ProductCustomFieldsViewController: UIHostingController<ProductCustomFields> {
    init() {
        super.init(rootView: ProductCustomFields())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ProductCustomFields: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ProductCustomFields()
}
