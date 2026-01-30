import SwiftUI

struct WPComConnectionSetupView: View {
    @ObservedObject var viewModel: WPComConnectionSetupViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
            ConnectWPComHeaderView()
            VStack(alignment: .leading, spacing: Constants.headerVerticalSpacing) {
                Text(Localization.title)
                    .largeTitleStyle()
                    .bold()
                Text(viewModel.subtitleAttributedString)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: Constants.stepsVerticalSpacing) {
                    ForEach(viewModel.steps) { step in
                        WPComConnectionSetupStepView(step: step)
                    }
                }
            }

            Spacer()

            footer
        }
        .padding(Constants.contentPadding)
        .onAppear() {
            viewModel.onAppear()
        }
    }


    @ViewBuilder var footer: some View {
        VStack {
            Button(viewModel.primaryButtonTitle) {
                viewModel.primaryButtonTapped()
            }
            .buttonStyle(PrimaryButtonStyle())
            .fixedSize(horizontal: false, vertical: true)
            .disabled(!viewModel.isPrimaryButtonEnabled)

            Button(viewModel.secondaryButtonTitle) {
                viewModel.secondaryButtonTapped()
            }
            .buttonStyle(SecondaryButtonStyle())
            .fixedSize(horizontal: false, vertical: true)
            .renderedIf(viewModel.isShowingSecondaryButton)
        }
    }
}

private extension WPComConnectionSetupView {
    enum Constants {
        static let contentVerticalSpacing: CGFloat = 32
        static let stepsVerticalSpacing: CGFloat = 32
        static let headerVerticalSpacing: CGFloat = 24
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let title: String = "Connect to WordPress.com"
    }
}

#Preview {
    let viewModel = WPComConnectionSetupViewModel(storeName: "coffeebeans.com")
    WPComConnectionSetupView(viewModel: viewModel)
}
