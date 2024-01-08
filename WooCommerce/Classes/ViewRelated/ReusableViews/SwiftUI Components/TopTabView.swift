import SwiftUI

struct TopTabItem<Content: View> {
    let name: String
    let content: () -> Content
    let onSelected: (() -> Void)?

    init(name: String,
         @ViewBuilder content: @escaping () -> Content,
         onSelected: (() -> Void)? = nil) {
        self.name = name
        self.content = content
        self.onSelected = onSelected
    }
}

struct TopTabView<Content: View>: View {
    @State private var selectedTab = 0
    @State private var underlineOffset: CGFloat = 0
    @State private var tabWidths: [CGFloat]
    @GestureState private var dragState: DragState = .inactive
    @State private var contentSize: CGSize = .zero

    @Binding var showTabs: Bool

    let tabs: [TopTabItem<Content>]

    init(tabs: [TopTabItem<Content>],
         showTabs: Binding<Bool> = .constant(true)) {
        self.tabs = tabs
        self._showTabs = showTabs
        _tabWidths = State(initialValue: [CGFloat](repeating: 0, count: tabs.count))
    }

    var body: some View {
        VStack(spacing: 0) {
            if tabs.count > 1 && showTabs {
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollViewProxy in
                        HStack(spacing: Layout.tabPadding * 2) {
                            ForEach(0..<tabs.count, id: \.self) { index in
                                VStack {
                                    Text(tabs[index].name)
                                        .font(.headline)
                                        .foregroundColor(selectedTab == index ? Colors.selected : .primary)
                                        .id(index)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedTab = index
                                                tabs[selectedTab].onSelected?()
                                            }
                                        }
                                        .onChange(of: selectedTab, perform: { newSelectedTab in
                                            withAnimation {
                                                scrollViewProxy.scrollTo(newSelectedTab, anchor: .center)
                                                underlineOffset = calculateOffset(index: newSelectedTab)
                                            }
                                        })
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityAddTraits(selectedTab == index ? [.isSelected, .isHeader] : [])
                                }
                                .padding()
                                .background(GeometryReader { geometry in
                                    Color.clear.onAppear {
                                        if index < tabWidths.count {
                                            tabWidths[index] = geometry.size.width
                                        }
                                    }
                                })
                            }
                            .onAppear {
                                withAnimation {
                                    scrollViewProxy.scrollTo(selectedTab, anchor: .center)
                                    underlineOffset = calculateOffset(index: selectedTab)
                                }
                            }
                        }
                        .padding(.horizontal, Layout.tabPadding)
                        .overlay(
                            Rectangle()
                                .frame(width: selectedTabUnderlineWidth(),
                                       height: Layout.selectedTabIndicatorHeight)
                                .foregroundColor(Colors.selected)
                                .offset(x: underlineOffset),
                            alignment: .bottomLeading
                        )
                    }
                }
                Divider()
            }

            // Display all the tabs in an HStack, each tab the same width as the TopTabView
            // This GeometryReader is used to set the width and drag offsets for swiping between views
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        // Tab content as passed to the TopTabView at init
                        tabs[index].content()
                            .frame(width: geometry.size.width)
                    }
                }
                .background(
                    // Use a background GeometryReader to get the height of the tab content.
                    // This is used later as the height of the top-level GeometryReader, to override the default
                    // behaviour of setting the frame to zero (and hiding the content.)
                    GeometryReader { contentGeometry in
                        Color.clear
                        .onAppear {
                            contentSize = contentGeometry.size
                        }
                        .onChange(of: contentGeometry.size) { newSize in
                            contentSize = newSize
                        }
                    })
                .offset(x: self.dragOffset(width: geometry.size.width))
                .animation(.interactiveSpring(), value: dragOffset(width: geometry.size.width))
                // Allows swipes to be started on any part of the content view area, not just occupied space e.g. Text.
                .contentShape(Rectangle())
                // The gesture could be simultaneous with an external scroll view
                .simultaneousGesture(
                    DragGesture()
                        .updating($dragState) { drag, state, transaction in
                            let isHorizontalDrag = abs(drag.translation.width) > abs(drag.translation.height)
                            if isHorizontalDrag {
                                state = .dragging(translation: drag.translation)
                            }
                        }
                        .onEnded { drag in
                            // We use `predictedEndTranslation` to account for velocity as the user ends the drag
                            // For fast, short swipes, this will likely be higher than `translation`, and lead to a
                            // more natural feeling animation.
                            let horizontalAmount = drag.predictedEndTranslation.width as CGFloat
                            let threshold: CGFloat = geometry.size.width / 2
                            let newIndex: Int
                            if horizontalAmount > threshold {
                                // A swipe more than 50% to the right: move back
                                newIndex = max(selectedTab - 1, 0)
                            } else if horizontalAmount < -threshold {
                                // A swipe more than 50% to the left: move forward
                                newIndex = min(selectedTab + 1, tabs.count - 1)
                            } else {
                                newIndex = selectedTab
                            }

                            // Notifiy the new tab that it's been selected, but only if it's changed
                            if newIndex != selectedTab {
                                tabs[newIndex].onSelected?()
                            }

                            // Update the selected tab to the new index
                            withAnimation(.easeOut) {
                                selectedTab = newIndex
                            }
                        }
                )
            }
            .frame(height: contentSize.height)
        }
    }

    private func selectedTabUnderlineWidth() -> CGFloat {
        guard let selectedTabWidth = tabWidths[safe: selectedTab] else {
            DDLogError("Out of bounds tab selected at index \(selectedTab)")
            return 0
        }
        return selectedTabWidth + (Layout.tabPadding * 2)
    }

    private func calculateOffset(index: Int) -> CGFloat {
        // Takes all preceeding tab widths, and adds appropriate spacing to each side to get the overall offset
        return tabWidths.prefix(index).reduce(0, +) + CGFloat(index) * (Layout.tabPadding * 2)
    }

    private func dragOffset(width: CGFloat) -> CGFloat {
        if dragState.isActive {
            let offset = -CGFloat(selectedTab) * width + dragState.translation.width
            return offset
        } else {
            return -CGFloat(selectedTab) * width
        }
    }

    enum DragState {
        case inactive
        case dragging(translation: CGSize)

        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }

        var isActive: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }

    private enum Layout {
        static var tabPadding: CGFloat { 10 }
        static var selectedTabIndicatorHeight: CGFloat { 2 }
    }

    private enum Colors {
        static var selected: Color { .withColorStudio(name: .wooCommercePurple, shade: .shade50) }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let tabs: [TopTabItem] = [
            TopTabItem(name: "A tab name", content: {
                Text("Content for Tab 1")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "A tab name", content: {
                Text("Content for Tab 2")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "More detail", content: {
                Text("Content for Tab 3")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "A really long tab name", content: {
                Text("Content for Tab 4")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "Tab", content: {
                Text("Content for Tab 5")
                    .font(.largeTitle)
                    .padding()
            })
        ]
        TopTabView(tabs: tabs)
            .previewLayout(.sizeThatFits)

        let oneTab: [TopTabItem] = [
            TopTabItem(name: "A tab name", content: {
                Text("Content for Tab 1")
                    .font(.largeTitle)
                    .padding()
            })
        ]
        TopTabView(tabs: oneTab)
            .previewLayout(.sizeThatFits)
    }
}
