import SwiftUI

struct TopTabItem<Content: View> {
    let name: String
    let icon: UIImage?
    let content: () -> Content
    let onSelected: (() -> Void)?

    /// Generic accessibility value for VoiceOver
    /// Introduced to narrate "Fulfilled" state of shipment tabs. Can be used for other purposes.
    let customAccessibilityValue: String?

    init(name: String,
         icon: UIImage? = nil,
         customAccessibilityValue: String? = nil,
         @ViewBuilder content: @escaping () -> Content,
         onSelected: (() -> Void)? = nil) {
        self.name = name
        self.icon = icon
        self.content = content
        self.customAccessibilityValue = customAccessibilityValue
        self.onSelected = onSelected
    }
}

struct TopTabView<Content: View>: View {
    enum TabsIconAlignment {
        case leading
        case trailing
    }

    @OptionalBinding private var selectedTab: Int = 0
    @State private var underlineOffset: CGFloat = 0
    @State private var tabWidths: [CGFloat]
    @GestureState private var dragState: DragState = .inactive
    @State private var contentSize: CGSize = .zero

    @Binding var showTabs: Bool

    private let showContent: Bool
    private let showDividerBelowTabs: Bool

    let tabs: [TopTabItem<Content>]

    // // Tabs container customization
    // Specifies horizontal padding for the entire container of tabs.
    // - Default value is 0
    let tabsContainerHorizontalPadding: CGFloat?
    // Color used for tab name and underline selection indicator when selected
    let selectedStateColor: Color
    // Color used for tab name when not selected
    let unselectedStateColor: Color
    // Specifies the height of the selected tab indicator
    // - Default value is Layout.selectedTabIndicatorHeight
    let selectedTabIndicatorHeight: CGFloat
    // Padding between tab items
    let tabPadding: CGFloat

    // // Individual tab item customization
    let tabsNameFont: Font
    // Specifies the height and width of the icon
    // - Applied with the conditional modifier
    let tabsIconSize: CGFloat?
    let tabsIconAlignment: TabsIconAlignment
    let tabsIconForegroundColor: Color?

    let tabItemContentHorizontalPadding: CGFloat?
    let tabItemContentVerticalPadding: CGFloat?

    init(tabs: [TopTabItem<Content>],
         showTabs: Binding<Bool> = .constant(true),
         showContent: Bool = true,
         showDividerBelowTabs: Bool = true,
         selectedTabIndex: Binding<Int>? = nil,
         tabsContainerHorizontalPadding: CGFloat? = 0.0,
         selectedStateColor: Color = Colors.selected,
         unselectedStateColor: Color = .primary,
         selectedTabIndicatorHeight: CGFloat = Layout.selectedTabIndicatorHeight,
         tabPadding: CGFloat = Layout.tabPadding,
         tabsNameFont: Font = .headline,
         tabsIconSize: CGFloat? = 20.0,
         tabsIconAlignment: TabsIconAlignment = .leading,
         tabsIconForegroundColor: Color? = nil,
         tabItemContentHorizontalPadding: CGFloat? = nil,
         tabItemContentVerticalPadding: CGFloat? = nil) {
        self.tabs = tabs
        self._showTabs = showTabs
        self.showContent = showContent
        self.showDividerBelowTabs = showDividerBelowTabs
        self._selectedTab = OptionalBinding(selectedTabIndex, default: 0)
        _tabWidths = State(initialValue: [CGFloat](repeating: 0, count: tabs.count))
        self.tabsContainerHorizontalPadding = tabsContainerHorizontalPadding
        self.selectedStateColor = selectedStateColor
        self.unselectedStateColor = unselectedStateColor
        self.selectedTabIndicatorHeight = selectedTabIndicatorHeight
        self.tabPadding = tabPadding
        self.tabsNameFont = tabsNameFont
        self.tabsIconSize = tabsIconSize
        self.tabsIconAlignment = tabsIconAlignment
        self.tabsIconForegroundColor = tabsIconForegroundColor
        self.tabItemContentHorizontalPadding = tabItemContentHorizontalPadding
        self.tabItemContentVerticalPadding = tabItemContentVerticalPadding
    }

    private func tabItemContentView(_ index: Int, selected: Bool) -> some View {
        HStack {
            if let icon = tabs[index].icon, tabsIconAlignment == .leading {
                tabIconView(with: icon)
            }

            Text(tabs[index].name)
                .font(tabsNameFont)
                .foregroundColor(selected ? selectedStateColor : unselectedStateColor)
                .id(index)

            if let icon = tabs[index].icon, tabsIconAlignment == .trailing {
                tabIconView(with: icon)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                selectedTab = index
                tabs[selectedTab].onSelected?()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(selected ? [.isSelected, .isHeader] : [])
        .accessibilityValue(tabs[index].customAccessibilityValue ?? "")
    }

    func tabIconView(with icon: UIImage) -> some View {
        Image(uiImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .if(tabsIconForegroundColor != nil) {
                $0.foregroundStyle(tabsIconForegroundColor ?? .clear)
            }
            .if(tabsIconSize != nil) {
                $0.frame(width: tabsIconSize, height: tabsIconSize)
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            if tabs.count > 1 && showTabs {
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollViewProxy in
                        HStack {
                            HStack(spacing: tabPadding * 2) {
                                ForEach(0..<tabs.count, id: \.self) { index in
                                    tabItemContentView(index, selected: selectedTab == index)
                                        .padding(.vertical, tabItemContentVerticalPadding)
                                        .padding(.horizontal, tabItemContentHorizontalPadding)
                                        .background(GeometryReader { geometry in
                                            Color.clear.onAppear {
                                                if index < tabWidths.count {
                                                    tabWidths[index] = geometry.size.width
                                                } else if index < tabs.count {
                                                    /// Since `tabWidths` was initialized as a state for this view
                                                    /// it would not be updated again when `tabs` change.
                                                    /// Append a new width when the number of tabs increases.
                                                    tabWidths.append(geometry.size.width)
                                                }

                                                if index == selectedTab {
                                                    /// The `ForEach` loop might iterate in reverse.
                                                    /// As a result, `tabWidths` could be incomplete by the time the selected index is reached.
                                                    /// It's safer to rely on the geometry of a specific tab instead.
                                                    underlineTabWith(tabGeometry: geometry)
                                                    scrollFocusTab(in: scrollViewProxy, at: index)
                                                }
                                            }
                                            .onChange(of: geometry.size) { _, newSize in
                                                /// Support dynamic type size change
                                                if index < tabWidths.count {
                                                    tabWidths[index] = newSize.width
                                                    if index == selectedTab {
                                                        underlineTabWith(tabGeometry: geometry)
                                                    }
                                                }
                                            }
                                        })
                                        .accessibilityElement(children: .combine)
                                }
                            }
                            .padding(.horizontal, tabPadding)
                            .overlay(
                                Rectangle()
                                    .frame(width: selectedTabUnderlineWidth(),
                                           height: selectedTabIndicatorHeight)
                                    .foregroundColor(selectedStateColor)
                                    .offset(x: underlineOffset),
                                alignment: .bottomLeading
                            )
                            .onChange(of: selectedTab) { _, newSelectedTab in
                                withAnimation {
                                    selectTab(in: scrollViewProxy, at: newSelectedTab)
                                }
                            }
                            .coordinateSpace(name: Constants.tabsHorizontalStackNameSpace)
                        }
                        .padding(.horizontal, tabsContainerHorizontalPadding)
                        .onAppear {
                            /// Handle state change asynchronously to ensure
                            /// the view is safely updated in the next runloop
                            DispatchQueue.main.async {
                                selectTab(in: scrollViewProxy, at: selectedTab)
                            }
                        }
                    }
                }
                Divider()
                    .renderedIf(showDividerBelowTabs)
            }

            if showContent {
                // Display all the tabs in an HStack, each tab the same width as the TopTabView
                // This GeometryReader is used to set the width and drag offsets for swiping between views
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: 0) {
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
                                .onChange(of: contentGeometry.size) { _, newSize in
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
    }

    private func selectedTabUnderlineWidth() -> CGFloat {
        guard let selectedTabWidth = tabWidths[safe: selectedTab] else {
            DDLogError("Out of bounds tab selected at index \(selectedTab)")
            return 0
        }
        return selectedTabWidth + (tabPadding * 2)
    }

    private func calculateOffset(index: Int) -> CGFloat {
        // Takes all preceeding tab widths, and adds appropriate spacing to each side to get the overall offset
        return tabWidths.prefix(index).reduce(0, +) + CGFloat(index) * (tabPadding * 2)
    }

    private func dragOffset(width: CGFloat) -> CGFloat {
        if dragState.isActive {
            let offset = -CGFloat(selectedTab) * width + dragState.translation.width
            return offset
        } else {
            return -CGFloat(selectedTab) * width
        }
    }

    private func selectTab(in scrollView: ScrollViewProxy, at index: Int) {
        let offset = calculateOffset(index: index)

        scrollFocusTab(in: scrollView, at: index)
        underlineTabAt(offset: offset)
    }

    private func underlineTabAt(offset: CGFloat) {
        underlineOffset = offset
    }

    private func underlineTabWith(tabGeometry: GeometryProxy) {
        let frame = tabGeometry.frame(in: .named(Constants.tabsHorizontalStackNameSpace))
        let offset = frame.minX - tabPadding
        underlineTabAt(offset: offset)
    }

    private func scrollFocusTab(in scrollView: ScrollViewProxy, at index: Int) {
        scrollView.scrollTo(index, anchor: .center)
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

    private enum Constants {
        static var tabsHorizontalStackNameSpace: String { "TabsHorizontalStack" }
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
            TopTabItem(name: "Tab with icon", content: {
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
            .previewDisplayName("Default Light Style")
            .preferredColorScheme(.light)
        TopTabView(tabs: tabs)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Default Dark Style")
            .preferredColorScheme(.dark)

        let carrierTabs: [TopTabItem] = [
            TopTabItem(name: "USPS", icon: UIImage(named: "shipping-label-usps-logo"), content: {
                Text("Content for Tab 1")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "DHL Express", icon: UIImage(named: "shipping-label-dhl-logo"), content: {
                Text("Content for Tab 2")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "USPS", icon: UIImage(named: "shipping-label-usps-logo"), content: {
                Text("Content for Tab 3")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "DHL Express", icon: UIImage(named: "shipping-label-dhl-logo"), content: {
                Text("Content for Tab 4")
                    .font(.largeTitle)
                    .padding()
            }),
            TopTabItem(name: "USPS", icon: UIImage(named: "shipping-label-usps-logo"), content: {
                Text("Content for Tab 5")
                    .font(.largeTitle)
                    .padding()
            })
        ]
        TopTabView(tabs: carrierTabs,
                   tabsContainerHorizontalPadding: nil,
                   unselectedStateColor: .secondary,
                   selectedTabIndicatorHeight: 3.0,
                   tabPadding: 0,
                   tabsNameFont: Font.subheadline.bold(),
                   tabItemContentHorizontalPadding: 16.0,
                   tabItemContentVerticalPadding: 9.0)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
            .previewDisplayName("Carrier Packages Light Style")
        TopTabView(tabs: carrierTabs,
                   tabsContainerHorizontalPadding: nil,
                   unselectedStateColor: .secondary,
                   selectedTabIndicatorHeight: 3.0,
                   tabPadding: 0,
                   tabsNameFont: Font.subheadline.bold(),
                   tabItemContentHorizontalPadding: 16.0,
                   tabItemContentVerticalPadding: 9.0)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
            .previewDisplayName("Carrier Packages Dark Style")
        TopTabView(tabs: carrierTabs,
                   showContent: false,
                   tabsContainerHorizontalPadding: nil,
                   unselectedStateColor: .secondary,
                   selectedTabIndicatorHeight: 3.0,
                   tabPadding: 0,
                   tabsNameFont: Font.subheadline.bold(),
                   tabItemContentHorizontalPadding: 16.0,
                   tabItemContentVerticalPadding: 9.0)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
            .previewDisplayName("Carrier Packages Without Content Dark Style")
        let oneTab: [TopTabItem] = [
            TopTabItem(name: "A tab name", content: {
                Text("Content for Tab 1")
                    .font(.largeTitle)
                    .padding()
            })
        ]
        TopTabView(tabs: oneTab)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("One Tab")
    }
}
