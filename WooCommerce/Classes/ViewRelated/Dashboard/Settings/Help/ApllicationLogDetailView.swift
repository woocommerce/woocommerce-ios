import SwiftUI

/// Hosting controller that wraps an `ApplicationLogDetailView`
///
final class ApplicationLogDetailViewController: UIHostingController<ApplicationLogDetailView> {
    init(viewModel: ApplicationLogViewModel) {
        super.init(rootView: ApplicationLogDetailView(viewModel: viewModel))
        self.title = viewModel.title
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ApplicationLogDetailView: View {
    @ObservedObject var viewModel: ApplicationLogViewModel

    var body: some View {
        ScrollViewReader { scrollProxy in
            List(viewModel.lines) { line in
                VStack(alignment: .leading, spacing: 6) {
                    if let dateText = line.dateText {
                        Text(dateText)
                            .footnoteStyle()
                    }
                    Text(line.text)
                        .bodyStyle()
                }
                .storeVisibleStatus(on: $viewModel.lastCellIsVisible, if: viewModel.isLastLine(line))
            }
            .overlay(
                scrollToBottomButton {
                    withAnimation {
                        scrollProxy.scrollTo(viewModel.lastLineID)
                    }
                },
                alignment: .bottomTrailing)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(
                    action: {
                        viewModel.shareSheetVisible.toggle()
                    }, label: {
                        Image(systemName: "square.and.arrow.up")
                    })
                    .sharePopover(isPresented: $viewModel.shareSheetVisible) {
                        ShareSheet(
                            activityItems: viewModel.activityItems,
                            excludedActivityTypes: Array(viewModel.excludedActivityTypes)
                        )
                    }
            }
        }
        .navigationBarStyle()
    }

    func scrollToBottomButton(_ action: @escaping () -> Void) -> some View {
        Group {
            if viewModel.buttonVisible {
                Button(action: {
                    action()
                }, label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .accentColor(Color(.accent))
                })
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut(duration: 0.1))
    }
}

private extension View {
    /// Monitors the view's appearance by watching the `onAppear`/ `onDisappear` modifiers and stores the state in the given binding
    ///
    /// - Parameters:
    ///     - target: where to store the current visible status for the view
    ///     - if: a condition that must be true for the view to propagate its visible status to the given binding
    ///
    func storeVisibleStatus(on target: Binding<Bool>, if condition: @autoclosure () -> Bool) -> some View {
        Group {
            if condition() {
                onAppear {
                    target.wrappedValue = true
                }
                .onDisappear {
                    target.wrappedValue = false
                }
            } else {
                self
            }
        }
    }
}

#if DEBUG
struct ApplicationLogDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ApplicationLogDetailView(viewModel: .sampleLog)
    }
}
#endif
