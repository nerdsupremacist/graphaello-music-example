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

    @GraphQL(Music.lookup.artist.name)
    var name: String?

    @GraphQL(Music.lookup.artist.theAudioDb.thumbnail)
    var image: URL?

    @GraphQL(Music.lookup.artist.lastFm.topTracks(first: .value(5)))
    var topSongs: Paging<TrendingTrackCell.LastFmTrack>?

    @GraphQL(Music.lookup.artist.releaseGroups(type: .value([.album]), first: .value(5)))
    var albums: Paging<ArtistAlbumCell.ReleaseGroup>?
    
    @GraphQL(Music.lookup.artist.releaseGroups(type: .value([.single]), first: .value(5)))
    var singles: Paging<ArtistAlbumCell.ReleaseGroup>?

    @GraphQL(Music.lookup.artist.theAudioDb.biography)
    var bio: String?

    @GraphQL(Music.lookup.artist.area.name)
    var area: String?

    @GraphQL(Music.lookup.artist.type)
    var type: String?

    @GraphQL(Music.lookup.artist.lifeSpan.begin)
    var formed: String?

    @GraphQL(Music.lookup.artist.theAudioDb.style)
    var genre: String?

    @GraphQL(Music.lookup.artist.theAudioDb.mood)
    var mood: String?

    var body: some View {
        FancyScrollView(title: name ?? "",
                        headerHeight: 350,
                        scrollUpHeaderBehavior: .parallax,
                        scrollDownHeaderBehavior: .sticky,
                        header: {
                            image
                                .map { url in
                                    Image.artwork(url).aspectRatio(contentMode: .fill).clipped()
                                }
                        }) {

            VStack(alignment: .leading, spacing: 16) {
                ArtistInfoSection("Top Songs") {
                    ArtistTopSongsList(api: self.api, tracks: self.topSongs)
                }

                ArtistInfoSection("Albums") {
                    ArtistAlbumList(api: self.api, albums: self.albums)
                }
                
                ArtistInfoSection("Singles") {
                    ArtistAlbumList(api: self.api, albums: self.singles)
                }

                VStack(spacing: 16) {
                    bio.map { bio in
                        ArtistInfoSection("About") {
                            Text(bio)
                                .font(.body)
                                .fontWeight(.light)
                                .padding(.horizontal, 16)
                                .lineLimit(4)
                        }
                    }

                    ArtistMetadata(type: "Origin", text: area)
                    ArtistMetadata(type: type == "Person" ? "Born" : "Formed", text: formed)
                    ArtistMetadata(type: "Genre", text: genre)
                    ArtistMetadata(type: "Mood", text: mood)

                    Divider()
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.systemGray6))
            }
            .padding(.top, 16)
        }
    }
}
