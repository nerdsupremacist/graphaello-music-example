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

    @GraphQL(Music.lookup.artist.lastFm.topTracks(first: .value(5)))
    var topSongs: Paging<TrendingTrackCell.LastFMTrack>?

    @GraphQL(Music.lookup.artist.releaseGroups(type: .value([.album]), first: .value(5)))
    var albums: Paging<ArtistAlbumCell.ReleaseGroup>?

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

    @GraphQL(Music.lookup.artist.lastFm.similarArtists(first: .value(3)))
    var similarArtists: Paging<SimilarArtistCell.LastFMArtist>?

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
                VStack(alignment: .leading, spacing: 16) {
                    ArtistInfoSection("Top Songs") {
                        ArtistTopSongsList(tracks: self.topSongs)
                    }

                    ArtistInfoSection("Albums") {
                        ArtistAlbumList(api: self.api, albums: self.albums)
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

                        ArtistInfoSection("Similar Artists") {
                            SimilarArtistsList(api: self.api, artists: self.similarArtists)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color(UIColor.systemGray6))
                }
                .padding(.top, 16)
            }
        }
    }
}
