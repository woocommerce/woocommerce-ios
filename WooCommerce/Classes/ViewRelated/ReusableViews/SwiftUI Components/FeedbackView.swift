import SwiftUI

struct FeedbackView: View {
    struct Configuration {
        let title: String
        var backgroundColor: Color = .init(uiColor: .systemGray5)
        let onVote: (FeedbackView.Vote) -> Void
    }

    let configuration: Configuration

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var vote: Vote?

    enum Vote: String, Equatable {
        case up
        case down
    }

    var body: some View {
        HStack {
            Text(configuration.title)
                .subheadlineStyle()
            Spacer()
            HStack(spacing: Layout.buttonSpacing) {
                Button {
                    guard vote == nil else {
                        return
                    }
                    vote = .up
                } label: {
                    Image(systemName: vote == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .resizable()
                        .frame(width: Layout.iconSize * scale,
                               height: Layout.iconSize * scale)
                        .foregroundColor(vote == .up ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)

                Button {
                    guard vote == nil else {
                        return
                    }
                    vote = .down
                } label: {
                    Image(systemName: vote == .down ?  "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .resizable()
                        .frame(width: Layout.iconSize * scale,
                               height: Layout.iconSize * scale)
                        .foregroundColor(vote == .down ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.contentInsets)
        .background(
            configuration.backgroundColor
                .cornerRadius(Layout.cornerRadius)
        )
        .onChange(of: vote) { newValue in
            if let newValue {
                configuration.onVote(newValue)
            }
        }
    }
}

private extension FeedbackView {
    enum Layout {
        static let contentInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let cornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 20
        static let buttonSpacing: CGFloat = 24
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(configuration: .init(title: "Test", onVote: { _ in }))
    }
}
