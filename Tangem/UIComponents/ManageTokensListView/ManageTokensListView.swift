//
//  ManageTokensListView.swift
//  Tangem
//
//  Created by Andrew Son on 22/05/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensListView<Header, Footer>: View where Header: View, Footer: View {
    typealias HeaderFactory = () -> Header?
    typealias FooterFactory = () -> Footer?

    @ObservedObject var viewModel: ManageTokensListViewModel
    let header: Header?
    let footer: Footer?

    init(
        viewModel: ManageTokensListViewModel,
        @ViewBuilder header: HeaderFactory,
        @ViewBuilder footer: FooterFactory
    ) {
        self.viewModel = viewModel
        self.header = header()
        self.footer = footer()
    }

    init(viewModel: ManageTokensListViewModel) where Header == EmptyView, Footer == EmptyView {
        self.viewModel = viewModel
        header = nil
        footer = nil
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                if let header {
                    header

                    divider
                }

                ForEach(viewModel.coinViewModels) {
                    ManageTokensCoinView(model: $0)
                        .padding(.horizontal)

                    divider
                }

                if viewModel.hasNextPage {
                    HStack(alignment: .center) {
                        ActivityIndicatorView(color: .gray)
                            .onAppear(perform: viewModel.fetch)
                    }
                }

                if let footer {
                    footer
                }
            }
        }
    }

    private var divider: some View {
        Divider()
            .padding([.leading])
    }
}
