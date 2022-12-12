import SwiftUI

/// Hosting controller that wraps the `StoreCreationCategoryQuestionView`.
final class StoreCreationCategoryQuestionHostingController: UIHostingController<StoreCreationCategoryQuestionView> {

    init(storeName: String,
         onContinue: @escaping (String) -> Void,
         onSkip: @escaping () -> Void) {
        super.init(rootView: StoreCreationCategoryQuestionView(storeName: storeName, onContinue: onContinue, onSkip: onSkip))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarAppearance()
    }

    /// Shows a transparent navigation bar without a bottom border and with a close button to dismiss.
    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }
}

/// Shows the store category question in the store creation flow.
struct StoreCreationCategoryQuestionView: View {
    @ObservedObject private var viewModel: StoreCreationCategoryQuestionViewModel

    init(storeName: String,
         onContinue: @escaping (String) -> Void,
         onSkip: @escaping () -> Void) {
        self.viewModel = StoreCreationCategoryQuestionViewModel(storeName: storeName, onContinue: onContinue, onSkip: onSkip)
    }

    var body: some View {
        OptionalStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(spacing: 16) {
                ForEach(viewModel.categories, id: \.name) { category in
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

struct StoreCreationCategoryQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationCategoryQuestionView(storeName: "Holiday store", onContinue: { _ in }, onSkip: {})
    }
}
