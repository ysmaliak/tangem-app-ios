//
//  CGSize+.swift
//  Tangem Tap
//
//  Created by Andrew Son on 19.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import CoreGraphics

extension CGSize: CustomStringConvertible {
    public var description: String {
        "w: \(width.rounded()), h: \(height.rounded())"
    }
}

extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        .init(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}
