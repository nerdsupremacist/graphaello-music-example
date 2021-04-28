//
//  ArtistsSearchResults.swift
//  Music
//
//  Created by Mathias Quintero on 12/22/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import SwiftUI
import FancyScrollView

struct TrendingArtistsList: View {
    let api: Music

    @GraphQL(Music.lastFm.chart.topArtists)
    var artists: Paging<TrendingArtistCell.LastFmArtist>?

    @GraphQL(Music.lastFm.chart.topTracks)
    var tracks: Paging<TrendingTrackCell.LastFmTrack>?

    var body: some View {
        FancyScrollView {
            VStack(alignment: .leading) {
                Text("Top Songs")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .fontWeight(.black)
                    .padding([.horizontal, .top], 16)

                tracks.map { tracks in
                    VStack {
                        ForEach(tracks.values, id: \.title) { track in
                            TrendingTrackCell(api: self.api, lastFmTrack: track)
                        }
                    }
                }

                tracks.map { tracks in
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
                }

                Text("Top Artists")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .fontWeight(.black)
                    .padding([.horizontal, .top], 16)

                artists.map { artists in
                    ForEach(artists.values, id: \.name) { artist in
                        TrendingArtistCell(api: self.api, lastFmArtist: artist)
                    }
                }

                artists.map { artists in
                    HStack {
                        Spacer()
                        NavigationLink(destination: TopArtistsList(api: api, paging: artists)) {
                            Text("More")
                                .foregroundColor(.orange)
                                .font(.callout)
                                .frame(alignment: .center)
                        }.frame(alignment: .center)
                        Spacer()
                    }
                }

                Spacer()
            }
        }
    }
}
