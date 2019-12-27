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
    @GraphQL(Music.lookup.artist.lastFm.topTracks)
    var tracks: Paging<TrendingTrackCell.LastFMTrack>?

    var body: some View {
        tracks.map { tracks in
            VStack {
                ForEach(tracks.values, id: \.title) { track in
                    TrendingTrackCell(lastFmTrack: track)
                }

                HStack {
                    Spacer()
                    NavigationLink(destination: TopSongsList(paging: tracks)) {
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
