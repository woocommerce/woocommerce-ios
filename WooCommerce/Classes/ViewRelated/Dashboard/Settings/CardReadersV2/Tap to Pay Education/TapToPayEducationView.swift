import Foundation
import SwiftUI

struct TapToPayEducationView: View {
    @StateObject private var viewModel: TapToPayEducationViewModel

    init(viewModel: TapToPayEducationViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                TabView(selection: $viewModel.selectedStep) {
                    ForEach(0..<viewModel.steps.count, id: \.self) { index in
                        TapToPayEducationStepView(viewModel: viewModel.steps[index])
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                Spacer()
                Button(viewModel.primaryAction.title, action: {
                    withAnimation {
                        viewModel.primaryAction.action()
                    }
                })
                .buttonStyle(PrimaryButtonStyle())
                .padding([.leading, .trailing, .bottom])
            }
            .wooNavigationBarStyle()
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let backAction = viewModel.backAction {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            withAnimation {
                                backAction.action()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.backward")
                                Text(backAction.title)
                            }
                        }
                    }
                }

                if let secondaryAction = viewModel.secondaryAction {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(secondaryAction.title, action: {
                            withAnimation {
                                secondaryAction.action()
                            }
                        })
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isInteractiveDismissDisabled)
        .sheet(isPresented: $viewModel.showingSetUpFlow,
               onDismiss: viewModel.reloadHasPreviousTapToPayUsage,
               content: {
            TapToPaySettingsFlowPresentingView(
                configuration: viewModel.configuration,
                siteID: viewModel.siteID,
                onboardingUseCase: viewModel.cardPresentPaymentsOnboardingUseCase)
        })
    }
}

// MARK: - Hosting Controller

final class TapToPayEducationViewHostingController: UIHostingController<TapToPayEducationView> {
    init(onDismiss: @escaping () -> Void) {
        let viewModel = TapToPayEducationViewModel(flow: .onboarding, onDismiss: onDismiss)
        super.init(rootView: TapToPayEducationView(viewModel: viewModel))

        viewModel.onDismiss = { [weak self] in
            guard let self else { return }

            self.dismiss(animated: true) {
                onDismiss()
            }
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
