//
//  SingleWalletNotificationManager.swift
//  Tangem
//
//  Created by Andrew Son on 29/08/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import BlockchainSdk
import TangemStaking

final class SingleTokenNotificationManager {
    @Injected(\.stakingRepositoryProxy) private var stakingRepositoryProxy: StakingRepositoryProxy

    private let analyticsService: NotificationsAnalyticsService = .init()

    private let walletModel: WalletModel
    private let walletModelsManager: WalletModelsManager
    private weak var delegate: NotificationTapDelegate?

    private let notificationInputsSubject: CurrentValueSubject<[NotificationViewInput], Never> = .init([])

    private var rentFeeNotification: NotificationViewInput?
    private var bag: Set<AnyCancellable> = []
    private var notificationsUpdateTask: Task<Void, Never>?

    init(
        walletModel: WalletModel,
        walletModelsManager: WalletModelsManager,
        contextDataProvider: AnalyticsContextDataProvider?
    ) {
        self.walletModel = walletModel
        self.walletModelsManager = walletModelsManager

        analyticsService.setup(with: self, contextDataProvider: contextDataProvider)
    }

    private func bind() {
        bag = []

        walletModel
            .walletDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.notificationsUpdateTask?.cancel()

                switch state {
                case .failed:
                    self?.setupNetworkUnreachable()
                case .noAccount(let message, _):
                    self?.setupNoAccountNotification(with: message)
                case .loading, .created:
                    break
                case .idle, .noDerivation:
                    self?.setupLoadedStateNotifications()
                }
            }
            .store(in: &bag)
    }

    private func setupLoadedStateNotifications() {
        let factory = NotificationsFactory()

        var events = [TokenNotificationEvent]()

        if let event = makeStakingNotificationEvent() {
            events.append(event)
        }

        if let existentialWarning = walletModel.existentialDepositWarning {
            events.append(.existentialDepositWarning(message: existentialWarning))
        }

        if case .solana = walletModel.tokenItem.blockchain, !walletModel.isZeroAmount {
            events.append(.solanaHighImpact)
        }

        if case .binance = walletModel.tokenItem.blockchain {
            events.append(.bnbBeaconChainRetirement)
        }

        let amounts = walletModel.wallet.amounts
        if case .koinos = walletModel.tokenItem.blockchain,
           let currentMana = amounts[.feeResource(.mana)]?.value,
           let maxMana = amounts[.coin]?.value {
            events.append(
                .manaLevel(
                    currentMana: "\(currentMana)",
                    maxMana: "\(maxMana)"
                )
            )
        }

        if let sendingRestrictions = walletModel.sendingRestrictions {
            let isFeeCurrencyPurchaseAllowed = walletModelsManager.walletModels.contains {
                $0.tokenItem == walletModel.feeTokenItem && $0.blockchainNetwork == walletModel.blockchainNetwork
            }

            if let event = TokenNotificationEvent.event(for: sendingRestrictions, isFeeCurrencyPurchaseAllowed: isFeeCurrencyPurchaseAllowed) {
                events.append(event)
            }
        }

        events += makeAssetRequirementsNotificationEvents()

        let inputs = events.map {
            factory.buildNotificationInput(
                for: $0,
                buttonAction: { [weak self] id, actionType in
                    self?.delegate?.didTapNotification(with: id, action: actionType)
                },
                dismissAction: { [weak self] id in
                    self?.dismissNotification(with: id)
                }
            )
        }

        notificationInputsSubject.send(inputs)

        setupRentFeeNotification()
    }

    private func setupRentFeeNotification() {
        if let rentFeeNotification {
            notificationInputsSubject.value.append(rentFeeNotification)
        }

        notificationsUpdateTask?.cancel()
        notificationsUpdateTask = Task { [weak self] in
            guard
                let rentInput = await self?.loadRentNotificationIfNeeded(),
                let self
            else {
                return
            }

            if Task.isCancelled {
                return
            }

            if !notificationInputsSubject.value.contains(where: { $0.id == rentInput.id }) {
                await runOnMain {
                    self.rentFeeNotification = rentInput
                    self.notificationInputsSubject.value.append(rentInput)
                }
            }
        }
    }

    private func setupNetworkUnreachable() {
        let factory = NotificationsFactory()
        notificationInputsSubject
            .send([
                factory.buildNotificationInput(
                    for: .networkUnreachable(currencySymbol: walletModel.blockchainNetwork.blockchain.currencySymbol),
                    dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
                ),
            ])
    }

    private func setupNoAccountNotification(with message: String) {
        // Skip displaying the BEP2 account creation top-up notification
        // since it will be deprecated shortly due to the network shutdown
        if case .binance = walletModel.tokenItem.blockchain {
            return
        }

        let factory = NotificationsFactory()
        let event = TokenNotificationEvent.noAccount(message: message)

        notificationInputsSubject
            .send([
                factory.buildNotificationInput(
                    for: event,
                    buttonAction: { [weak self] id, actionType in
                        self?.delegate?.didTapNotification(with: id, action: actionType)
                    },
                    dismissAction: { [weak self] id in
                        self?.dismissNotification(with: id)
                    }
                ),
            ])
    }

    private func loadRentNotificationIfNeeded() async -> NotificationViewInput? {
        guard walletModel.hasRent else { return nil }

        guard let rentMessage = try? await walletModel.updateRentWarning().async() else {
            return nil
        }

        if Task.isCancelled {
            return nil
        }

        let factory = NotificationsFactory()
        let input = factory.buildNotificationInput(
            for: .rentFee(rentMessage: rentMessage),
            dismissAction: weakify(self, forFunction: SingleTokenNotificationManager.dismissNotification(with:))
        )
        return input
    }

    private func makeAssetRequirementsNotificationEvents() -> [TokenNotificationEvent] {
        let asset = walletModel.amountType

        guard
            !walletModel.hasPendingTransactions,
            let assetRequirementsManager = walletModel.assetRequirementsManager,
            assetRequirementsManager.hasRequirements(for: asset)
        else {
            return []
        }

        switch assetRequirementsManager.requirementsCondition(for: asset) {
        case .paidTransaction:
            return [.hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation(associationFee: nil))]
        case .paidTransactionWithFee(let feeAmount):
            let balanceFormatter = BalanceFormatter()
            let associationFee = TokenNotificationEvent.UnfulfilledRequirementsConfiguration.HederaTokenAssociationFee(
                formattedValue: balanceFormatter.formatDecimal(feeAmount.value),
                currencySymbol: feeAmount.currencySymbol
            )
            return [.hasUnfulfilledRequirements(configuration: .missingHederaTokenAssociation(associationFee: associationFee))]
        case .none:
            return []
        }
    }

    func makeStakingNotificationEvent() -> TokenNotificationEvent? {
        guard FeatureProvider.isAvailable(.staking) else {
            return nil
        }

        guard let yield = stakingRepositoryProxy.getYield(item: walletModel.stakingTokenItem) else {
            return nil
        }

        let days = 2
        let apyFormatted = PercentFormatter().format(yield.apy, option: .staking)
        let rewardPeriodDaysFormatted = days.formatted()

        return .staking(
            tokenSymbol: walletModel.tokenItem.currencySymbol,
            tokenIconInfo: TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom),
            earnUpToFormatted: apyFormatted,
            rewardPeriodDaysFormatted: rewardPeriodDaysFormatted
        )
    }
}

extension SingleTokenNotificationManager: NotificationManager {
    var notificationInputs: [NotificationViewInput] {
        notificationInputsSubject.value
    }

    var notificationPublisher: AnyPublisher<[NotificationViewInput], Never> {
        notificationInputsSubject.eraseToAnyPublisher()
    }

    func setupManager(with delegate: NotificationTapDelegate?) {
        self.delegate = delegate

        setupLoadedStateNotifications()
        bind()
    }

    func dismissNotification(with id: NotificationViewId) {
        notificationInputsSubject.value.removeAll(where: { $0.id == id })
    }
}
