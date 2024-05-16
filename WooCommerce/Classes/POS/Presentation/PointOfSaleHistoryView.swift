import SwiftUI

struct PointOfSaleHistoryView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleHistoryViewModel

    init(viewModel: PointOfSaleHistoryViewModel) {
        self.viewModel = viewModel
    }

    private var titleView: some View {
        HStack {
            Text("History")
                .font(.title)
                .bold()
                .foregroundColor(Color.primaryText)
            Spacer()
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .tint(Color.primaryText)
        }
    }

    private let dateFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    @ViewBuilder
    private var headerView: some View {
        HStack {
            Text("This session:")
            Spacer()
            if let sessionStart = viewModel.sessionStart,
               let duration = dateFormatter.string(from: sessionStart, to: Date()) {
                Text(duration)
                Spacer()
            }
            if viewModel.items.count == 1 {
                Text("1 transaction")
            }
            else {
                Text("\(viewModel.items.count) transactions")
            }
            Spacer()
            transactionsAmountView
        }
        .foregroundColor(Color.primaryText)
    }
    
    @ViewBuilder
    private var transactionsAmountView: some View {
        let totalAmount = Double(viewModel.itemsAmount) / 100.0
        if let amount = currencyFormatter.string(from: NSNumber(value: totalAmount)) {
            Text(amount)
        }
        else {
            EmptyView()
        }
    }

    @State private var searchText: String = ""

    private var searchView: some View {
        HStack {
            HStack {
                TextField("Search", text: $searchText)
                    .placeholder(when: searchText.isEmpty) {
                        Text("Search").foregroundColor(Color.primaryText)
                    }
                    .foregroundColor(Color.primaryText)
                    .padding()
            }
            .background(Color.tertiaryBackground)
            .cornerRadius(12.0)
            Spacer()
            Button {
            } label: {
                Text("Filter")
                    .fontWeight(.medium)
                    .padding()
                    .foregroundColor(Color.primaryText)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                        .stroke(Color.primaryText, lineWidth: 2)
                    )
            }
        }
    }

    private var itemsView: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.items) { item in
                    HistoryItemView(item: item)
                }
            }
        }
    }

    var body: some View {
        VStack {
            VStack {
                titleView
                headerView
                    .padding(.vertical)
                searchView
                itemsView
            }
            .padding()
        }
        .background(Color.secondaryBackground)
    }
}

struct HistoryItemView: View {
    let item: HistoryItem

    var body: some View {
        HStack {
            Text(item.createdAt.formatted())
                .foregroundColor(Color.primaryText)
                .padding()
            Spacer()
        }
        .background(Color.tertiaryBackground)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
