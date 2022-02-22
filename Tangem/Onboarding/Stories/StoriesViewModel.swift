//
//  StoriesViewModel.swift
//  StoriesDemo
//
//  Created by Andrey Chukavin on 26.01.2022.
//

import Foundation
import Combine
import SwiftUI

class StoriesViewModel: ViewModel, ObservableObject {
    var assembly: Assembly!
    var navigation: NavigationCoordinator!
    weak var userPrefsService: UserPrefsService! {
        didSet {
            self.didDisplayMainScreenStories = userPrefsService.didDisplayMainScreenStories
            userPrefsService.didDisplayMainScreenStories = true
        }
    }
    
    @Published var currentPage: WelcomeStoryPage = WelcomeStoryPage.allCases.first!
    @Published var currentProgress = 0.0
    let pages = WelcomeStoryPage.allCases
    
    private var timerSubscription: AnyCancellable?
    private var timerStartDate: Date?
    private var longTapTimerSubscription: AnyCancellable?
    private var longTapDetected = false
    private var currentDragLocation: CGPoint?
    private var didDisplayMainScreenStories = false
    private var bag: Set<AnyCancellable> = []
    
    private let longTapDuration = 0.25
    private let minimumSwipeDistance = 100.0
    
    func onAppear() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .dropFirst()
            .sink { [weak self] _ in
                self?.pauseTimer()
            }
            .store(in: &bag)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .dropFirst()
            .sink { [weak self] _ in
                self?.resumeTimer()
            }
            .store(in: &bag)
        
        DispatchQueue.main.async {
            self.restartTimer()
        }
    }
    
    func onDisappear() {
        pauseTimer()
        bag = []
    }
    
    @ViewBuilder
    func currentStoryPage(scanCard: @escaping () -> Void, orderCard: @escaping () -> Void) -> some View {
        switch currentPage {
        case WelcomeStoryPage.meetTangem:
            let progressBinding = Binding<Double> { [weak self] in
                self?.currentProgress ?? 0
            } set: { [weak self] in
                self?.currentProgress = $0
            }

            MeetTangemStoryPage(
                progress: progressBinding,
                immediatelyShowButtons: didDisplayMainScreenStories,
                scanCard: scanCard,
                orderCard: orderCard
            )
        case WelcomeStoryPage.awe:
            AweStoryPage(scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.backup:
            BackupStoryPage(scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.currencies:
            CurrenciesStoryPage(scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.web3:
            Web3StoryPage(scanCard: scanCard, orderCard: orderCard)
        case WelcomeStoryPage.finish:
            FinishStoryPage(scanCard: scanCard, orderCard: orderCard)
        }
    }

    func didDrag(_ current: CGPoint) {
        if longTapDetected {
            return
        }
        
        if let currentDragLocation = currentDragLocation, currentDragLocation.distance(to: current) < minimumSwipeDistance {
            return
        }

        currentDragLocation = current
        pauseTimer()
        
        longTapTimerSubscription = Timer.publish(every: longTapDuration, on: RunLoop.main, in: .default)
            .autoconnect()
            .sink { [unowned self] _ in
                self.currentDragLocation = nil
                self.longTapTimerSubscription = nil
                self.longTapDetected = true
            }
    }
    
    func didEndDrag(_ current: CGPoint, destination: CGPoint, viewWidth: CGFloat) {
        if let currentDragLocation = currentDragLocation {
            let distance = (destination.x - current.x)
            
            let moveForward: Bool
            if abs(distance) < minimumSwipeDistance {
                moveForward = currentDragLocation.x > viewWidth / 2
            } else {
                moveForward = distance > 0
            }

            move(forward: moveForward)
        } else {
            resumeTimer()
        }
        
        currentDragLocation = nil
        longTapTimerSubscription = nil
        longTapDetected = false
    }
    
    private func move(forward: Bool) {
        currentPage = WelcomeStoryPage(rawValue: currentPage.rawValue + (forward ? 1 : -1)) ?? pages.first!
        restartTimer()
        if currentPage != pages.first {
            didDisplayMainScreenStories = true
        }
    }
    
    private func restartTimer() {
        currentProgress = 0
        resumeTimer()
    }
    
    private func pauseTimer() {
        let now = Date()
        
        let elapsedTime: TimeInterval
        if let timerStartDate = timerStartDate {
            elapsedTime = now.timeIntervalSince(timerStartDate)
        } else {
            elapsedTime = 0
        }
        
        let progress = elapsedTime / currentPage.duration
        
        timerSubscription = nil
        withAnimation(.linear(duration: 0)) {
            self.currentProgress = progress
        }
    }
    
    private func resumeTimer() {
        let remainingProgress = 1 - currentProgress
        let remainingStoryDuration = currentPage.duration * remainingProgress
        let currentStoryTime = currentPage.duration * currentProgress
        
        timerStartDate = Date() - TimeInterval(currentStoryTime)
        
        withAnimation(.linear(duration: remainingStoryDuration)) {
            self.currentProgress = 1
        }
        
        timerSubscription = Timer.publish(every: remainingStoryDuration, on: .main, in: .default)
            .autoconnect()
            .sink { [unowned self] _ in
                self.timerSubscription = nil
                self.move(forward: true)
            }
    }
}


fileprivate extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return sqrt(pow(self.x - other.x, 2) + pow(self.y - other.y, 2))
    }
}
