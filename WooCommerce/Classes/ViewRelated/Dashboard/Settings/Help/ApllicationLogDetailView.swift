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
    @State var viewModel: ApplicationLogViewModel

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
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
        }
        .navigationBarItems(
            trailing: Button(
                action: {
                    viewModel.showShareActivity()
                }, label: {
                    Image(systemName: "square.and.arrow.up")
                }))
    }
}

struct ApplicationLogDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ApplicationLogDetailView(viewModel: .sampleLog)
        }
    }
}
