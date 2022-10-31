import SwiftUI

struct WooNavigationSheetViewModel {
    let navigationTitle: String
    let done: () -> Void
    let doneButtonTitle = NSLocalizedString(
        "Done",
        comment: "Title for the Done button on a WebView modal sheet")
}

struct WooNavigationSheet<Content: View>: View {
    let content: Content

    let viewModel: WooNavigationSheetViewModel

    init(viewModel: WooNavigationSheetViewModel,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            content
                .navigationTitle(viewModel.navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: viewModel.done,
                               label: {
                            Text(viewModel.doneButtonTitle)
                        })
                    }
                }
                .wooNavigationBarStyle()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
