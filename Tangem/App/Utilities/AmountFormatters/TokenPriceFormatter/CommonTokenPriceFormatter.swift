//
//  CommonTokenPriceFormatter.swift
//  Tangem
//
//  Created by skibinalexander on 21.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CommonTokenPriceFormatter {
    private let balanceFormatter = BalanceFormatter()
}

// MARK: - FeeFormatter

extension CommonTokenPriceFormatter {
    func formatFiatBalance(_ value: Decimal?) -> String {
        balanceFormatter.formatDecimal(value, formattingOptions: .defaultFiatFormattingOptions(for: value))
    }
}
