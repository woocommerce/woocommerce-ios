import SwiftUI

/// Hosting controller that wraps an `ApplicationLogDetailView`
///
final class ApplicationLogDetailViewController: UIHostingController<ApplicationLogDetailView> {
    init(with contents: String, for date: String) {
        let viewModel = ApplicationLogViewModel(logText: contents)
        super.init(rootView: ApplicationLogDetailView(viewModel: viewModel))
        self.title = date
        viewModel.present = { [weak self] vc in
            self?.present(vc, animated: true, completion: nil)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ApplicationLogDetailView: View {
    let viewModel: ApplicationLogViewModel

    private let lastLineID: UUID?

    @State private var lastCellVisible = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    init(viewModel: ApplicationLogViewModel) {
        self.viewModel = viewModel
        lastLineID = viewModel.lines.last?.id
    }

    private func isLastLine(_ line: ApplicationLogLine) -> Bool {
        line.id == lastLineID
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            List(viewModel.lines) { line in
                VStack(alignment: .leading, spacing: 6) {
                    line.date
                        .flatMap(dateFormatter.string(for:))
                        .map {
                            Text($0)
                                .footnoteStyle()

                        }
                    Text(line.text)
                        .bodyStyle()
                }
                .onAppear(perform: {
                    if isLastLine(line) {
                        withAnimation {
                            lastCellVisible = true
                        }
                    }
                })
                .onDisappear(perform: {
                    if isLastLine(line) {
                        withAnimation {
                            lastCellVisible = false
                        }
                    }
                })
            }
            .overlay(
                scrollToBottomButton {
                    withAnimation {
                        scrollProxy.scrollTo(viewModel.lines.last!.id)
                    }
                },
                alignment: .bottomTrailing)
        }
        .navigationBarItems(
            trailing: Button(
                action: {
                    viewModel.showShareActivity()
                }, label: {
                    Image(systemName: "square.and.arrow.up")
            }))
    }

    func scrollToBottomButton(_ action: @escaping () -> Void) -> some View {
        Group {
            if !lastCellVisible {
                Button(action: {
                    action()
                }, label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .resizable()
                        .accentColor(Color(.accent))
                })
                .frame(width: 32, height: 32)
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct ApplicationLogDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ApplicationLogDetailView(viewModel: .sampleLog)
    }
}
