//
//  BalanceFormattingOptions.swift
//  Tangem
//
//  Created by Andrew Son on 27/04/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BalanceFormattingOptions {
    let minFractionDigits: Int
    let maxFractionDigits: Int
    let formatEpsilonAsLowestRepresentableValue: Bool
    let roundingType: AmountRoundingType?

    static var defaultFiatFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 2,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
    }

    static var defaultCryptoFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: 2,
            maxFractionDigits: 8,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .down, scale: 8)
        )
    }

    static var defaultCryptoFeeFormattingOptions: BalanceFormattingOptions {
        .init(
            minFractionDigits: Self.defaultCryptoFormattingOptions.minFractionDigits,
            maxFractionDigits: 6,
            formatEpsilonAsLowestRepresentableValue: Self.defaultCryptoFormattingOptions.formatEpsilonAsLowestRepresentableValue,
            roundingType: Self.defaultCryptoFormattingOptions.roundingType
        )
    }

    static func defaultFiatFormattingOptions(for value: Decimal?) -> BalanceFormattingOptions {
        guard let value else { return .defaultFiatFormattingOptions }
        let maxFractionDigits = (value > 1 || value < -1) ? 2 : value.countLeadingZerosAfterDecimal() + 5
        return BalanceFormattingOptions(
            minFractionDigits: 2,
            maxFractionDigits: maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: .default(roundingMode: .plain, scale: 2)
        )
    }
}

private extension Decimal {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        return formatter
    }()

    func countLeadingZerosAfterDecimal() -> Int {
        guard let numberString = Self.numberFormatter.string(from: self as NSDecimalNumber) else { return 0 }

        let decimalSeparator = Self.numberFormatter.decimalSeparator ?? "."
        let parts = numberString.split(separator: Character(decimalSeparator))

        guard parts.count == 2 else { return 0 }

        let fractionalPart = parts[1]

        var zeroCount = 0
        for char in fractionalPart {
            if char == "0" {
                zeroCount += 1
            } else {
                break
            }
        }

        return zeroCount
    }
}
