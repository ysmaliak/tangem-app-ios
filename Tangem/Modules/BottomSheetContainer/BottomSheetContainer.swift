//
//  BottomSheetContainer.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetContainer<Item, ContentView: View>: View {
    @Binding private var isShowing: Bool

    private let settings: Settings
    private let content: () -> ContentView

    // MARK: - Internal

    @State private var contentHeight: CGFloat = 400
    @State private var isDragging: Bool = false
    @State private var previousDragTransition: CGSize = .zero
    @State private var offset: CGFloat = UIScreen.main.bounds.height

    private let indicatorSize = CGSize(width: 40, height: 4)

    var dragPercentage: CGFloat {
        let visibleHeight = contentHeight - offset
        let percentage = visibleHeight / contentHeight
        return max(0, percentage)
    }

    var opacity: CGFloat {
        max(0, settings.backgroundOpacity * dragPercentage)
    }

    init(
        isShowing: Binding<Bool>,
        settings: Settings,
        @ViewBuilder content: @escaping () -> ContentView
    ) {
        _isShowing = isShowing
        self.settings = settings
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isShowing {
                Color.black.opacity(opacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideView(withDelay: true)
                    }

                sheetView
                    .transition(.move(edge: .bottom))

                settings.backgroundColor
                    // For hide bottom space when sheet is up
                    .frame(height: abs(min(0, offset)))
                    // Added to hide the line between views
                    .offset(y: -1)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .animation(isDragging ? .interactiveSpring() : .easeOut(duration: settings.animationDuration))
        .onChange(of: isShowing, perform: didChange)
        .onAppear { didChange(isShowing: isShowing) }
    }

    private var sheetView: some View {
        VStack(spacing: 0) {
            indicator

            content()
                .padding(.bottom, UIApplication.safeAreaInsets.bottom)
        }
        .zIndex(1)
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
        .cornerRadius(settings.cornerRadius, corners: [.topLeft, .topRight])
        .readSize { contentHeight = $0.height }
        .gesture(dragGesture)
        .offset(y: offset)
    }

    private var indicator: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(Color.secondary)
                .frame(size: indicatorSize)
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }

                let dragValue = value.translation.height - previousDragTransition.height
                let locationChange = value.startLocation.y - value.location.y

                if locationChange > 0 {
                    offset += dragValue / 3
                } else {
                    offset += dragValue
                }

                previousDragTransition = value.translation
            }
            .onEnded { value in
                previousDragTransition = .zero
                isDragging = false

                // If swipe did be enough then hide view
                if value.translation.height > settings.distanceToHide {
                    hideView(withDelay: true) // false
                    // Otherwise set the view to default state
                } else {
                    offset = 0
                }
            }
    }

    private func didChange(isShowing: Bool) {
        if isShowing {
            offset = 0
        } else {
            hideView(withDelay: true)
        }
    }

    /// If item we want close view from external place need to await animation completion
    /// Otherwise, like close after swipe we shouldn't wait
    private func hideView(withDelay: Bool) {
        offset = UIScreen.main.bounds.height
        guard isShowing else { return }

        let delay: CGFloat = withDelay ? settings.animationDuration : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isShowing = false
        }
    }

    private func showView() {
        offset = 0
    }
}

extension BottomSheetContainer {
    struct Settings {
        let cornerRadius: CGFloat
        let backgroundColor: Color
        let backgroundOpacity: CGFloat
        let distanceToHide: CGFloat
        let animationDuration: Double

        init(
            cornerRadius: CGFloat = 16,
            backgroundColor: Color = Colors.Background.secondary,
            backgroundOpacity: CGFloat = 0.5,
            distanceToHide: CGFloat = UIScreen.main.bounds.height * 0.1,
            animationDuration: Double = 0.45
        ) {
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
            self.backgroundOpacity = backgroundOpacity
            self.distanceToHide = distanceToHide
            self.animationDuration = animationDuration
        }
    }
}

struct BottomSheetContainer_Previews: PreviewProvider {
    struct StatableContainer: View {
        @State private var item: SwappingPermissionViewModel? = nil

        var body: some View {
            ZStack {
                Color.green
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((item != nil).description)") {
                    toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $item) {
                        SwappingPermissionView(viewModel: $0)
                    }
            }
        }

        func toggleItem() {
            let isShowing = item != nil

            if !isShowing {
                item = SwappingPermissionViewModel(
                    inputModel: SwappingPermissionInputModel(fiatFee: 1.45, transactionInfo: .mock),
                    transactionSender: TransactionSenderMock(),
                    coordinator: SwappingCoordinator()
                )
            } else {
                item = nil
            }
        }
    }

    static var previews: some View {
        StatableContainer()
    }
}

// MARK: - View +

extension View {
    @ViewBuilder
    func bottomSheet<Item, ContentView: View>(
        item: Binding<Item?>,
        settings: BottomSheetContainer<Item, ContentView>.Settings = .init(),
        @ViewBuilder content: @escaping (Item) -> ContentView
    ) -> some View {
        let isShowing = Binding<Bool>(
            get: { item.wrappedValue != nil },
            set: { isShow in
                if !isShow {
                    item.wrappedValue = nil
                }
            }
        )

        if let itemValue = item.wrappedValue {
            BottomSheetContainer(isShowing: isShowing, settings: settings) { content(itemValue) }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func bottomSheet<Item, ContentView: View>(
        isShowing: Binding<Bool>,
        settings: BottomSheetContainer<Item, ContentView>.Settings = .init(),
        @ViewBuilder content: @escaping () -> ContentView
    ) -> some View {
        if isShowing.wrappedValue {
            BottomSheetContainer(isShowing: isShowing, settings: settings, content: content)
        } else {
            EmptyView()
        }
    }
}
