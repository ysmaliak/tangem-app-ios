//
//  SendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendTransactionSummaryDescriptionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func makeDescription(amount: Decimal, fee: Decimal) -> String? {
        let amountInFiat = tokenItem.id.flatMap { BalanceConverter().convertToFiat(amount, currencyId: $0) }
        let feeInFiat = feeTokenItem.id.flatMap { BalanceConverter().convertToFiat(fee, currencyId: $0) }
        let totalInFiat = [amountInFiat, feeInFiat].compactMap { $0 }.reduce(0, +)

        let formatter = BalanceFormatter()
        let totalInFiatFormatted = formatter.formatFiatBalance(totalInFiat, formattingOptions: .defaultFiatFormattingOptions(for: totalInFiat))
        let feeInFiatFormatted = formatter.formatFiatBalance(feeInFiat, formattingOptions: .defaultFiatFormattingOptions(for: feeInFiat))

        return Localization.sendSummaryTransactionDescription(totalInFiatFormatted, feeInFiatFormatted)
    }
}
