import Foundation
import SwiftUI

struct TapToPayEducationView: View {
    @ObservedObject private var viewModel: TapToPayEducationViewModel

    init(viewModel: TapToPayEducationViewModel) {
        self.viewModel = viewModel
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
    }
}

// MARK: - Hosting Controller

final class TapToPayEducationViewViewHostingController: UIHostingController<TapToPayEducationView> {
    init(onDismiss: @escaping () -> Void) {
        let viewModel = TapToPayEducationViewModel()
        super.init(rootView: TapToPayEducationView(viewModel: viewModel))

        viewModel.onDismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            onDismiss()
        }

        isModalInPresentation = true
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
