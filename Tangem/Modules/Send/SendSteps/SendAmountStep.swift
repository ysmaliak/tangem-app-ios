//
//  SendAmountStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendAmountStep {
    private let viewModel: SendAmountViewModel
    private let interactor: SendAmountInteractor
    private let sendFeeInteractor: SendFeeInteractor

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeInteractor = sendFeeInteractor
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .amount(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        guard step.type.isSummary else {
            return
        }

        viewModel.setAnimatingAuxiliaryViewsOnAppear()
    }

    func willDisappear(next step: SendStep) {
        UIApplication.shared.endEditing()

        guard step.type.isSummary else {
            return
        }

        sendFeeInteractor.updateFees()
    }
}
