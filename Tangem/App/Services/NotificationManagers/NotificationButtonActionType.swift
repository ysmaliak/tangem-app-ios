//
//  NotificationButtonActionType.swift
//  Tangem
//
//  Created by Andrew Son on 04/09/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum NotificationButtonActionType: Identifiable, Hashable {
    case generateAddresses
    case backupCard
    case buyCrypto(currencySymbol: String?)
    case openFeeCurrency(currencySymbol: String)
    case refresh
    case refreshFee
    case goToProvider
    case leaveAmount(amount: Decimal, amountFormatted: String)
    case reduceAmountBy(amount: Decimal, amountFormatted: String)
    case reduceAmountTo(amount: Decimal, amountFormatted: String)
    case bookNow(promotionLink: URL)
    case addHederaTokenAssociation
    @available(*, unavailable, message: "Token trust lines support not implemented yet")
    case addTokenTrustline
    /// Rate the app.
    case openFeedbackMail
    /// Rate the app.
    case openAppStoreReview

    var id: Int { hashValue }

    var title: String {
        switch self {
        case .generateAddresses:
            return Localization.commonGenerateAddresses
        case .backupCard:
            return Localization.buttonStartBackupProcess
        case .buyCrypto(let currencySymbol):
            guard let currencySymbol else {
                // TODO: Replace when texts will be confirmed
                return "Top up card"
            }
            return Localization.commonBuyCurrency(currencySymbol)
        case .openFeeCurrency(let currencySymbol):
            return Localization.commonBuyCurrency(currencySymbol)
        case .refresh, .refreshFee:
            return Localization.warningButtonRefresh
        case .goToProvider:
            return Localization.commonGoToProvider
        case .reduceAmountBy(_, let amountFormatted):
            return Localization.sendNotificationReduceBy(amountFormatted)
        case .reduceAmountTo(_, let amountFormatted), .leaveAmount(_, let amountFormatted):
            return Localization.sendNotificationLeaveButton(amountFormatted)
        case .bookNow:
            return Localization.mainTravalaPromotionButton
        case .addHederaTokenAssociation:
            return Localization.warningHederaMissingTokenAssociationButtonTitle
        case .openFeedbackMail:
            return Localization.warningButtonCouldBeBetter
        case .openAppStoreReview:
            return Localization.warningButtonReallyCool
        }
    }

    var icon: MainButton.Icon? {
        switch self {
        case .generateAddresses:
            return .trailing(Assets.tangemIcon)
        case .backupCard,
             .buyCrypto,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .openFeedbackMail,
             .openAppStoreReview:
             .leaveAmount,
             .bookNow:
            return nil
        }
    }

    var style: MainButton.Style {
        switch self {
        case .generateAddresses,
             .bookNow,
             .openAppStoreReview:
            return .primary
        case .backupCard,
             .buyCrypto,
             .openFeeCurrency,
             .refresh,
             .refreshFee,
             .goToProvider,
             .reduceAmountBy,
             .reduceAmountTo,
             .addHederaTokenAssociation,
             .openFeedbackMail,
             .leaveAmount:
            return .secondary
        }
    }
}
