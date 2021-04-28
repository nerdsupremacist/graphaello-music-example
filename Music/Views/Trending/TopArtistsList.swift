//
//  TopArtistsList.swift
//  Music
//
//  Created by Mathias Quintero on 12/23/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct TopArtistsList: View {
    let api: Music
    let paging: Paging<TrendingArtistCell.LastFmArtist>

    var body: some View {
        ScrollView {
            VStack {
                PagingView(paging, pageSize: 20) { TrendingArtistCell(api: self.api, lastFmArtist: $0) }
            }
        }
        .navigationBarTitle("Top Artists")
    }
}
