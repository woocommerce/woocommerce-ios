import SwiftUI

// MARK: - AnalyticsStatsView
//
struct AnalyticsStatsView: View {
    var leftGraphTitle: String
    var leftGraphValue: String
    var rightGraphTitle: String
    var rightGraphValue: String

    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 0, content: {
                StatsItem(valueTitle: leftGraphTitle, value: leftGraphValue)
                StatsItem(valueTitle: rightGraphTitle, value: rightGraphValue)
            })
            .padding(EdgeInsets(top: Constants.contentInsetTop,
                                leading: Constants.contentInsetLeading,
                                bottom: Constants.contentInsetBottom,
                                trailing: Constants.contentInsetTrailing))
            .background(Color(.listForeground))
        }
    }
}

struct AnalyticsStatsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsStatsView(leftGraphTitle: "Total Sales",
                           leftGraphValue: "$3,678",
                           rightGraphTitle: "Net Sales",
                           rightGraphValue: "$3,234")
            .preferredColorScheme(.light)
            .previewLayout(.fixed(width: 375, height: 130))
        AnalyticsStatsView(leftGraphTitle: "Total Sales",
                           leftGraphValue: "$3,678",
                           rightGraphTitle: "Net Sales",
                           rightGraphValue: "$3,234")
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 130))
    }
}

extension AnalyticsStatsView {
    private enum Constants {
        static let contentInsetTop: CGFloat = 16
        static let contentInsetLeading: CGFloat = 16
        static let contentInsetBottom: CGFloat = 16
        static let contentInsetTrailing: CGFloat = 16
    }
}

private struct StatsItem: View {
    let valueTitle: String
    let value: String

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: Constants.contentSpacing, content: {
                Text(valueTitle)
                    .foregroundColor(Color(.statsValueTitle))
                Text(value)
                    .font(Font.system(size: 28))
                    .foregroundColor(Color(.text))
                HStack {
                    AnalyticsPercetageView(
                        bgColor: .percentageNeutral,
                        percentageTextColor: UIColor.white,
                        percentageValue: "+23%")
                    Spacer()
                }
            })
        }
    }
}

extension StatsItem {
    private enum Constants {
        static let contentSpacing: CGFloat = 10
        static let contentInsetLeading: CGFloat = 16
        static let contentInsetBottom: CGFloat = 16
        static let contentInsetTrailing: CGFloat = 16
    }
}

private struct AnalyticsPercetageView: View {
    var bgColor: UIColor
    var percentageTextColor: UIColor
    var percentageValue: String
    var body: some View {
        ZStack(alignment: .center, content: {
            Text(percentageValue)
                .font(Font.system(size: 12))
                .foregroundColor(Color(percentageTextColor))
                .padding(EdgeInsets(top: 3, leading: 7, bottom: 3, trailing: 7))
                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(bgColor)))
        })
    }
}
