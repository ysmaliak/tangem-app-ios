//
//  TangemBlogUrlBuilder.swift
//  Tangem
//
//  Created by Andrey Chukavin on 26.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct TangemBlogUrlBuilder {
    func url(post: Post) -> URL {
        let currentLanguageCode = Locale.current.languageCode ?? LanguageCode.en

        let languageCode: String
        switch currentLanguageCode {
        case LanguageCode.ru:
            languageCode = currentLanguageCode
        default:
            languageCode = LanguageCode.en
        }
        return URL(string: "https://tangem.com/\(languageCode)/blog/post/\(post.path)/")!
    }
}

extension TangemBlogUrlBuilder {
    enum Post {
        case fee
        case scanCard
    }
}

private extension TangemBlogUrlBuilder.Post {
    var path: String {
        switch self {
        case .fee:
            "what-is-a-transaction-fee-and-why-do-we-need-it"
        case .scanCard:
            "scan-tangem-card"
        }
    }
}
