//
//  ArtistTopSongsList.swift
//  Music
//
//  Created by Mathias Quintero on 12/24/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct ArtistTopSongsList: View {
    let api: Music
    let tracks: Paging<TrendingTrackCell.LastFmTrack>?

    var body: some View {
        tracks.map { tracks in
            VStack {
                ForEach(tracks.values, id: \.title) { track in
                    TrendingTrackCell(api: self.api, lastFmTrack: track)
                }

                HStack {
                    Spacer()
                    NavigationLink(destination: TopSongsList(api: api, paging: tracks)) {
                        Text("More")
                            .foregroundColor(.orange)
                            .font(.callout)
                            .frame(alignment: .center)
                    }.frame(alignment: .center)
                    Spacer()
                }
            }.padding(.horizontal, 16)
        }
    }
}
