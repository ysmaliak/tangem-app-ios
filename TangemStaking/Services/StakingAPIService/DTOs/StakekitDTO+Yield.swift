//
//  StakekitDTO+Yield.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 24.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// Polygon native
// ethereum-matic-native-staking
// 0x29010F8F91B980858EB298A0843264cfF21Fd9c9
// ccf0a87a-3d6a-41d0-afa4-3dfc1a101335
extension StakekitDTO {
    struct Required: Decodable {
        let required: Bool
    }

    enum Yield {
        enum Enabled {
            struct Response: Decodable {
                let data: [Info.Response]
            }
        }

        enum Info {
            struct Request: Encodable {
                let integrationId: String
            }

            struct Response: Decodable {
                let id: String
                let token: Token
                let tokens: [Token]
                let args: Actions
                let status: Status
                let apy: Decimal
                let rewardRate: Decimal
                let rewardType: RewardType
                let metadata: Metadata
                let validators: [Validator]
                let isAvailable: Bool?

                struct Actions: Decodable {
                    let enter: Action
                    let exit: Action

                    struct Action: Decodable {
                        let addresses: ActionAddresses
                        let args: ActionArgs

                        struct ActionAddresses: Decodable {
                            let address: Address
                            let additionalAddresses: AdditionalAddresses

                            struct Address: Decodable {
                                let required: Bool
                                let network: String
                            }

                            enum AdditionalAddresses: Decodable {
                                case binanceBeaconAddress(Required)
                            }
                        }

                        struct ActionArgs: Decodable {
                            let amount: Amount
                            let validatorAddress: Required

                            struct Amount: Decodable {
                                let required: Bool
                                let minimum: Decimal
                            }
                        }
                    }
                }

                struct Status: Decodable {
                    let enter: Bool?
                    let exit: Bool?
                }

                enum RewardType: String, Decodable {
                    case apr
                    case apy
                    case variable
                }

                struct Metadata: Decodable {
                    let name: String
                    let logoURI: String?
                    let description: String?
                    let documentation: String?
                    let token: Token
                    let tokens: [Token]
                    let type: MetadataType
                    let rewardSchedule: RewardScheduleType
                    let cooldownPeriod: Period?
                    let warmupPeriod: Period
                    let withdrawPeriod: Period
                    let rewardClaiming: RewardClaiming
                    let defaultValidator: String?
                    let supportsMultipleValidators: Bool?
                    let supportsLedgerWalletApi: Bool?
                    let revshare: Enabled
                    let fee: Enabled

                    enum MetadataType: String, Decodable {
                        case staking
                        case liquidStaking = "liquid-staking"
                        case lending
                        case restaking
                        case vault
                    }

                    enum RewardScheduleType: String, Decodable {
                        case block
                        case hour
                        case day
                        case week
                        case month
                        case era
                        case epoch
                    }

                    enum Period: Decodable {
                        case days(Int)
                    }

                    enum RewardClaiming: String, Decodable {
                        case auto
                        case manual
                    }

                    struct Enabled: Decodable {
                        let enabled: Bool
                    }
                }
            }
        }

        enum Balance {
            struct Request: Encodable {
                let integrationId: String
                let address: Address
            }

            struct Response: Decodable {
                let groupId: String
                let type: BalanceType
                let amount: String
                let date: Date?
                let pricePerShare: String
                let pendingActions: [PendingAction]
                let token: Token
                let validatorAddress: String?
                let providerId: String?

                enum BalanceType: String, Decodable {
                    case available
                    case staked
                    case unstaking
                    case unstaked
                    case preparing
                    case rewards
                    case locked
                    case unlocking
                }

                struct PendingAction: Decodable {
                    let type: PendingActionType
                    let passthrough: String

                    enum PendingActionType: String, Decodable {
                        case STAKE
                        case UNSTAKE
                        case CLAIM_REWARDS
                        case RESTAKE_REWARDS
                        case WITHDRAW
                        case RESTAKE
                        case CLAIM_UNSTAKED
                        case UNLOCK_LOCKED
                        case STAKE_LOCKED
                        case VOTE
                        case REVOKE
                        case VOTE_LOCKED
                        case REVOTE
                        case REBOND
                        case MIGRATE
                    }
                }
            }
        }
    }
}
