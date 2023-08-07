import SwiftUI

/// Hosting controller that wraps the `StoreCreationChallengesQuestionView`.
final class StoreCreationChallengesQuestionHostingController: UIHostingController<StoreCreationChallengesQuestionView> {
    init(viewModel: StoreCreationChallengesQuestionViewModel) {
        super.init(rootView: StoreCreationChallengesQuestionView(viewModel: viewModel))
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

/// Shows the store challenges question in the store creation flow.
struct StoreCreationChallengesQuestionView: View {
    @ObservedObject private var viewModel: StoreCreationChallengesQuestionViewModel

    init(viewModel: StoreCreationChallengesQuestionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        OptionalStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.challenges, id: \.self) { challenge in
                    Button(action: {
                        viewModel.didTapChallenge(challenge)
                    }, label: {
                        HStack {
                            Text(challenge.name)
                            Spacer()
                        }
                    })
                    .buttonStyle(SelectableSecondaryButtonStyle(isSelected: viewModel.selectedChallenges.contains(where: { $0 == challenge })))
                }
            }
        }
    }
}

struct StoreCreationChallengesQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationChallengesQuestionView(viewModel: .init(onContinue: { _ in },
                                                             onSkip: {}))
    }
}
