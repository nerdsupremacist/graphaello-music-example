//
//  ArtistDetailView.swift
//  Music
//
//  Created by Mathias Quintero on 12/23/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI
import FancyScrollView

struct ArtistDetailView: View {
    let api: Music

    @GraphQL(Music.lookup.artist.mbid)
    var id: String?

    @GraphQL(Music.lookup.artist.name)
    var name: String?

    @GraphQL(Music.lookup.artist.theAudioDb.thumbnail)
    var image: String?

    @GraphQL(Music.lookup.artist.theAudioDb.biography)
    var bio: String?

    var body: some View {
        FancyScrollView(title: name ?? "",
                        headerHeight: 350,
                        scrollUpHeaderBehavior: .parallax,
                        scrollDownHeaderBehavior: .sticky,
                        header: {
                            image
                                .flatMap(URL.init(string:))
                                .map { url in
                                    Image.artwork(url).aspectRatio(contentMode: .fill).clipped()
                                }
                        }) {

            id.map { id in
                VStack(alignment: .leading) {
                    bio.map { bio in
                        ArtistInfoSection("About") {
                            Text(bio)
                                .font(.body)
                                .fontWeight(.light)
                                .padding(.horizontal, 16)
                                .lineLimit(4)
                        }
                        .padding(.top, 16)
                    }

                    ArtistInfoSection("Top Songs") {
                        api.artistTopSongsList(mbid: id, first: 5)
                    }

                    ArtistInfoSection("Albums") {
                        api.artistAlbumList(mbid: id, type: [.album], first: 3)
                    }

                    ArtistInfoSection("EPs") {
                        api.artistAlbumList(mbid: id, type: [.ep], first: 3)
                    }

                    ArtistInfoSection("Singles") {
                        api.artistAlbumList(mbid: id, type: [.single], first: 3)
                    }
                }
            }
        }
    }
}
