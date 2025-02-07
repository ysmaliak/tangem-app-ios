//
//  SendAmountInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendAmountInteractor {
    var errorPublisher: AnyPublisher<String?, Never> { get }
    var isValidPublisher: AnyPublisher<Bool, Never> { get }

    func update(amount: Decimal?) -> SendAmount?
    func update(type: SendAmountCalculationType) -> SendAmount?
    func updateToMaxAmount() -> SendAmount?
}

class CommonSendAmountInteractor {
    private let tokenItem: TokenItem
    private let balanceValue: Decimal

    private weak var input: SendAmountInput?
    private weak var output: SendAmountOutput?
    private let validator: SendAmountValidator

    private var type: SendAmountCalculationType
    private var _error: CurrentValueSubject<Error?, Never> = .init(nil)
    private var _isValid: CurrentValueSubject<Bool, Never> = .init(false)

    init(
        input: SendAmountInput,
        output: SendAmountOutput,
        tokenItem: TokenItem,
        balanceValue: Decimal,
        validator: SendAmountValidator,
        type: SendAmountCalculationType
    ) {
        self.input = input
        self.output = output
        self.tokenItem = tokenItem
        self.balanceValue = balanceValue
        self.validator = validator
        self.type = type
    }

    private func validateAndUpdate(amount: SendAmount?) {
        do {
            try amount?.crypto.map { try validator.validate(amount: $0) }
            _error.send(.none)
            _isValid.send(amount != nil)
            output?.amountDidChanged(amount: amount)
        } catch {
            _error.send(error)
            _isValid.send(false)
            output?.amountDidChanged(amount: .none)
        }
    }

    private func makeSendAmount(value: Decimal) -> SendAmount? {
        switch type {
        case .crypto:
            let fiat = convertToFiat(cryptoValue: value)
            return .init(type: .typical(crypto: value, fiat: fiat))
        case .fiat:
            let crypto = convertToCrypto(fiatValue: value)
            return .init(type: .alternative(fiat: value, crypto: crypto))
        }
    }

    private func convertToCrypto(fiatValue: Decimal?) -> Decimal? {
        // If already have the converted the `crypto` amount associated with current `fiat` amount
        if input?.amount?.fiat == fiatValue {
            return input?.amount?.crypto
        }

        return SendAmountConverter().convertToCrypto(fiatValue, tokenItem: tokenItem)
    }

    private func convertToFiat(cryptoValue: Decimal?) -> Decimal? {
        // If already have the converted the `fiat` amount associated with current `crypto` amount
        if input?.amount?.crypto == cryptoValue {
            return input?.amount?.fiat
        }

        return SendAmountConverter().convertToFiat(cryptoValue, tokenItem: tokenItem)
    }
}

// MARK: - SendAmountInteractor

extension CommonSendAmountInteractor: SendAmountInteractor {
    var errorPublisher: AnyPublisher<String?, Never> {
        _error.map { $0?.localizedDescription }.eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        _isValid.eraseToAnyPublisher()
    }

    func update(amount: Decimal?) -> SendAmount? {
        guard let amount else {
            validateAndUpdate(amount: nil)
            return nil
        }

        let sendAmount = makeSendAmount(value: amount)
        validateAndUpdate(amount: sendAmount)
        return sendAmount
    }

    func update(type: SendAmountCalculationType) -> SendAmount? {
        guard self.type != type else {
            return input?.amount
        }

        self.type = type
        let sendAmount = input?.amount?.toggle(type: type)
        validateAndUpdate(amount: sendAmount)
        return sendAmount
    }

    func updateToMaxAmount() -> SendAmount? {
        switch type {
        case .crypto:
            let fiat = convertToFiat(cryptoValue: balanceValue)
            let amount = SendAmount(type: .typical(crypto: balanceValue, fiat: fiat))
            validateAndUpdate(amount: amount)
            return amount
        case .fiat:
            let fiat = convertToFiat(cryptoValue: balanceValue)
            let amount = SendAmount(type: .alternative(fiat: fiat, crypto: balanceValue))
            validateAndUpdate(amount: amount)
            return amount
        }
    }
}

enum SendAmountCalculationType {
    case crypto
    case fiat
}
