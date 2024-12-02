import Foundation
import SwiftUI

struct TapToPayEducationView: View {
    @StateObject private var viewModel: TapToPayEducationViewModel

    init(viewModel: TapToPayEducationViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
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
