//
//  CommonWalletModelsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

class CommonWalletModelsManager {
    private let walletManagersRepository: WalletManagersRepository
    private let walletModelsFactory: WalletModelsFactory

    private var walletModels = CurrentValueSubject<[WalletModel], Never>([])
    private var bag = Set<AnyCancellable>()

    init(
        walletManagersRepository: WalletManagersRepository,
        walletModelsFactory: WalletModelsFactory
    ) {
        self.walletManagersRepository = walletManagersRepository
        self.walletModelsFactory = walletModelsFactory
        bind()
    }

    private func bind() {
        walletManagersRepository
            .walletManagersPublisher
            .sink { [weak self] managers in
                self?.updateWalletModels(with: managers)
            }
            .store(in: &bag)
    }

    private func updateWalletModels(with walletManagers: [BlockchainNetwork: WalletManager]) {
        AppLog.shared.debug("🔄 Updating Wallet models")

        var existingWalletModels = walletModels.value
        let newWalletModels = walletManagers.flatMap { walletModelsFactory.makeWalletModels(from: $0.value) }

        let walletModelsToDelete = Set(existingWalletModels).subtracting(newWalletModels).map { $0.id }
        let walletModelsToAdd = Set(newWalletModels).subtracting(existingWalletModels)

        guard !walletModelsToAdd.isEmpty || !walletModelsToDelete.isEmpty else {
            return
        }

        existingWalletModels.removeAll {
            walletModelsToDelete.contains($0.id)
        }

        walletModelsToAdd.forEach {
            $0.update(silent: false)
        }

        existingWalletModels.append(contentsOf: walletModelsToAdd)

        log(walletModels: existingWalletModels)
        
        walletModels.send(existingWalletModels)
    }
}

// MARK: - WalletListManager

extension CommonWalletModelsManager: WalletModelsManager {
    var walletModelsPublisher: AnyPublisher<[WalletModel], Never> {
        walletModels.eraseToAnyPublisher()
    }

//    func getWalletModels() -> [WalletModel] {
//        walletModels.value
//    }
//
//    func subscribeToWalletModels() -> AnyPublisher<[WalletModel], Never> {
//        walletModels.eraseToAnyPublisher()
//    }

//    func getEntriesWithoutDerivation() -> [StorageEntry] {
//        entriesWithoutDerivation.value
//    }
//
//    func subscribeToEntriesWithoutDerivation() -> AnyPublisher<[StorageEntry], Never> {
//        entriesWithoutDerivation.eraseToAnyPublisher()
//    }



//    func reloadWalletModels(silent: Bool) -> AnyPublisher<Void, Never> {
//        guard !getWalletModels().isEmpty else {
//            AppLog.shared.debug("‼️ WalletModels is empty")
//            return .just
//        }
//
//        return reloadAllWalletModelsPublisher(silent: silent)
//    }
}

private extension CommonWalletModelsManager {
//    func reloadAllWalletModelsPublisher(silent: Bool) -> AnyPublisher<Void, Never> {
//        tryMigrateTokens()
//            .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
//                guard let self = self else {
//                    return .just
//                }
//
//                return updateWalletModelsPublisher(silent: silent)
//            }
//            .eraseToAnyPublisher()
//    }

//    func updateWalletModelsPublisher(silent: Bool) -> AnyPublisher<Void, Never> {
//        let publishers = getWalletModels().map {
//            $0.update(silent: silent).replaceError(with: ())
//        }
//
//        return Publishers
//            .MergeMany(publishers)
//            .collect(publishers.count)
//            .mapVoid()
//            .eraseToAnyPublisher()
//    }

    func log(walletModels: [WalletModel]) {
        let printList = walletModels.map {
            return "\($0.name)"
        }

        AppLog.shared.debug("✅ Actual List of WalletModels [\(printList.joined(separator: ", "))]")
    }
}
