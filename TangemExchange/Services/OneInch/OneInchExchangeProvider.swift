//
//  OneInchExchangeProvider.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 08.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class OneInchExchangeProvider {
    /// OneInch use this contractAddress for coins
    private let oneInchCoinContractAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    private let oneInchAPIProvider: OneInchAPIServicing

    private var bag = Set<AnyCancellable>()

    init(exchangeService: OneInchAPIServicing) {
        self.oneInchAPIProvider = exchangeService
    }
}

extension OneInchExchangeProvider: ExchangeProvider {
    // MARK: - Fetch data

    func fetchExchangeAmountAllowance(for currency: Currency) async throws -> Decimal {
        guard currency.isToken,
              let contractAddress = currency.contractAddress,
              let blockchain = ExchangeBlockchain.convert(from: currency.chainId) else {
            throw Errors.noData
        }

        let parameters = ApproveAllowanceParameters(
            tokenAddress: contractAddress,
            walletAddress: currency.walletAddress
        )

        let allowanceResult = await oneInchAPIProvider.allowance(
            blockchain: blockchain,
            allowanceParameters: parameters
        )

        switch allowanceResult {
        case .success(let allowanceInfo):
            return Decimal(string: allowanceInfo.allowance) ?? 0
        case .failure(let error):
            throw error
        }
    }

    func fetchTxDataForExchange(items: ExchangeItems, amount: String, slippage: Int) async throws -> ExchangeDataModel {
        guard let destination = items.destination,
              let blockchain = ExchangeBlockchain.convert(from: items.source.chainId) else {
            throw Errors.noData
        }

        let parameters = ExchangeParameters(fromTokenAddress: items.source.contractAddress ?? oneInchCoinContractAddress,
                                            toTokenAddress: destination.contractAddress ?? oneInchCoinContractAddress,
                                            amount: amount,
                                            fromAddress: items.source.walletAddress,
                                            slippage: slippage)

        let result = await oneInchAPIProvider.swap(blockchain: blockchain, parameters: parameters)

        switch result {
        case .success(let swapData):
            return ExchangeDataModel(swapData: swapData)
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Approve API

    func approveTxData(for currency: Currency) async throws -> ExchangeApprovedDataModel {
        guard let contractAddress = currency.contractAddress,
              let blockchain = ExchangeBlockchain.convert(from: currency.chainId) else {
            throw Errors.noData
        }

        let parameters = ApproveTransactionParameters(tokenAddress: contractAddress, amount: .infinite)
        let txResponse = await oneInchAPIProvider.approveTransaction(
            blockchain: blockchain,
            approveTransactionParameters: parameters
        )

        switch txResponse {
        case .success(let approveTxData):
            return ExchangeApprovedDataModel(approveTxData: approveTxData)
        case .failure(let error):
            throw error
        }
    }

    func getSpenderAddress(for currency: Currency) async throws -> String {
        guard let blockchain = ExchangeBlockchain.convert(from: currency.chainId) else {
            throw Errors.noData
        }

        let spender = await oneInchAPIProvider.spender(blockchain: blockchain)

        switch spender {
        case .success(let spender):
            return spender.address
        case .failure(let error):
            throw error
        }
    }
}
