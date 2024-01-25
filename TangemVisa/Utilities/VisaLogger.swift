//
//  VisaLogger.swift
//  TangemVisa
//
//  Created by Andrew Son on 22/01/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol VisaLogger {
    func error(_ error: Error)
    func debug<T>(_ message: @autoclosure () -> T)
}

class InternalLogger {
    private let logger: VisaLogger

    init(logger: VisaLogger) {
        self.logger = logger
    }

    func error(error: Error) {
        logger.error(error)
    }

    func debug<T>(subsystem: Subsystem, _ message: @autoclosure () -> T) {
        logger.debug("\(subsystem.rawValue)\(message())")
    }
}

extension InternalLogger {
    enum Subsystem: String {
        case bridgeInteractorBuilder = "[Visa] Bridge Interactor Builder - "
        case bridgeInteractor = "[Visa] Bridge Interactor - "
    }
}
