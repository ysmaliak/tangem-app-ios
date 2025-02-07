//
//  CommonSellStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 09.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonSellStepsManager {
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        feeStep: SendFeeStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.feeStep = feeStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last

        assert(last != nil, "Stack is empty")

        return last ?? initialState.step
    }

    private func next(step: SendStep) {
        let isEditAction = stack.contains(where: { $0.type.isSummary })
        stack.append(step)

        switch step.type {
        case .summary:
            output?.update(state: .moveAndFade(step: step, action: .send))
        case .finish:
            output?.update(state: .moveAndFade(step: step, action: .close))
        case .amount where isEditAction,
             .destination where isEditAction,
             .fee where isEditAction:
            output?.update(state: .moveAndFade(step: step, action: .continue))
        case .amount, .destination, .fee:
            output?.update(state: .next(step: step))
        }
    }

    private func back() {
        stack.removeLast()
        let step = currentStep()

        switch step.type {
        case .summary:
            output?.update(state: .moveAndFade(step: step, action: .send))
        default:
            output?.update(state: .back(step: step))
        }
    }
}

// MARK: - SendStepsManager

extension CommonSellStepsManager: SendStepsManager {
    var initialState: SendStepsManagerViewState {
        .init(step: summaryStep, animation: .moveAndFade, mainButtonType: .send, backButtonVisible: false)
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        assertionFailure("There's not back action in this flow")
    }

    func performNext() {
        assertionFailure("There's not next action in this flow")
    }

    func performFinish() {
        next(step: finishStep)
    }

    func performContinue() {
        assert(stack.contains(where: { $0.type.isSummary }), "Continue is possible only after summary")

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonSellStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditAmount() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditFee() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: feeStep)
    }
}
