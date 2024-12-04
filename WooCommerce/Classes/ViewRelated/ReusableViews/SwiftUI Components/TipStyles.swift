import SwiftUI
import TipKit

@available(iOS 17.0, *)
struct InvertedTipStyle: TipViewStyle {
    func makeBody(configuration: TipViewStyle.Configuration) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                configuration.image?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color(.invertedLink))


                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            configuration.title?
                                .font(.body)
                                .foregroundStyle(Color(.invertedLabel))
                            Spacer()
                            Button(action: {
                                configuration.tip.invalidate(reason: .tipClosed)
                            }) {
                                Image(systemName: "xmark")
                                    .scaledToFit()
                                    .foregroundStyle(Color(.invertedLink))
                            }
                        }
                        configuration.message?
                            .font(.body)
                            .foregroundStyle(Color(.invertedSecondaryLabel))
                    }

                    ForEach(configuration.actions) { action in
                        Button(action: action.handler) {
                            action.label()
                                .font(.subheadline)
                                .foregroundStyle(Color(.invertedLink))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.invertedTooltipBackgroundColor), ignoresSafeAreaEdges: .all)
    }
}
