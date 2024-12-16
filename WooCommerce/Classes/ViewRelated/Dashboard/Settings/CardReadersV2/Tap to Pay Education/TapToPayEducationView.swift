import Foundation
import SwiftUI

struct TapToPayEducationView: View {
    @StateObject private var viewModel: TapToPayEducationViewModel
    @Environment(\.dismiss) private var dismiss
    private var completion: () -> Void

    init(viewModel: TapToPayEducationViewModel, completion: @escaping () -> Void = {}) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.completion = completion
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
        .onChange(of: viewModel.dismiss) { _ in
            dismiss()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            completion()
        }
    }
}
