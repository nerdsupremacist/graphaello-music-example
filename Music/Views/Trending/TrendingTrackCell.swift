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
    @GraphQL(Music.LastFMTrack.title)
    var title: String?

    @GraphQL(Music.LastFMTrack.artist.name)
    var artist: String?

    @GraphQL(Music.LastFMTrack.album.image)
    var image: String?

    var body: some View {
        HStack {
            Image.artwork(image.flatMap(URL.init(string:)))
                .frame(width: 50)
            
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
    }
}
