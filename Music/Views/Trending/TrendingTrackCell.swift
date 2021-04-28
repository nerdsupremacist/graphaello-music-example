//
//  TrendingAlbumCell.swift
//  Music
//
//  Created by Mathias Quintero on 12/22/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct TrendingTrackCell: View {
    let api: Music

    @GraphQL(Music.LastFmTrack.title)
    var title: String?

    @GraphQL(Music.LastFmTrack.artist.name)
    var artist: String?

    @GraphQL(Music.LastFmTrack.album.image)
    var image: URL?

    @GraphQL(Music.LastFmTrack.album.mbid)
    var albumId: String?

    var body: some View {
        let stack = HStack {
            Image.artwork(image).frame(width: 50)
            
            VStack(alignment: .leading) {
                title.map { title in
                    Text(title)
                        .foregroundColor(.primary)
                }
                artist.map { artist in
                    Text(artist)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }

        guard let albumId = albumId else {
            return AnyView(stack)
        }

        return AnyView(
            NavigationLink(destination: api.albumDetailView(mbid: albumId)) { stack }
        )
    }
}
