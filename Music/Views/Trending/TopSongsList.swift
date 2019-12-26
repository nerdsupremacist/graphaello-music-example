//
//  TopSongsList.swift
//  Music
//
//  Created by Mathias Quintero on 12/23/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct TopSongsList: View {
    let paging: Paging<TrendingTrackCell.LastFMTrack>

    var body: some View {
        List {
            PagingView(paging, pageSize: 20) {
                TrendingTrackCell(lastFmTrack: $0)
            }
            .animation(nil)
        }
        .navigationBarTitle("Top Songs")
    }
}
