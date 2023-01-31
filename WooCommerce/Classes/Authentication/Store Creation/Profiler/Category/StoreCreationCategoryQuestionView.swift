import SwiftUI

/// Hosting controller that wraps the `StoreCreationCategoryQuestionView`.
final class StoreCreationCategoryQuestionHostingController: UIHostingController<StoreCreationCategoryQuestionView> {
    init(viewModel: StoreCreationCategoryQuestionViewModel) {
        super.init(rootView: StoreCreationCategoryQuestionView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Shows the store category question in the store creation flow.
struct StoreCreationCategoryQuestionView: View {
    @ObservedObject private var viewModel: StoreCreationCategoryQuestionViewModel

    init(viewModel: StoreCreationCategoryQuestionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        OptionalStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(spacing: 32) {
                ForEach(viewModel.categorySections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        // Category group name.
                        Text(section.group.name.uppercased())
                            .foregroundColor(Color(.textSubtle))
                            .captionStyle()
                        VStack(alignment: .leading, spacing: 16) {
                            // Category options.
                            ForEach(section.categories, id: \.name) { category in
                                Button(action: {
                                    viewModel.selectCategory(category)
                                }, label: {
                                    HStack {
                                        Text(category.name)
                                        Spacer()
                                    }
                                })
                                .buttonStyle(SelectableSecondaryButtonStyle(isSelected: viewModel.selectedCategory == category))
                            }
                        }
                    }
                }
            }
        }
    }
}

struct StoreCreationCategoryQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationCategoryQuestionView(viewModel: .init(storeName: "Holiday store",
                                                           onContinue: { _ in },
                                                           onSkip: {}))
    }
}
