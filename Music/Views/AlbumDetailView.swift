//
//  AlbumDetailView.swift
//  Music
//
//  Created by Mathias Quintero on 12/27/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI
import FancyScrollView

struct AlbumDetailView: View {
    let api: Music

    @GraphQL(Music.lookup.release.title)
    var title: String?

    @GraphQL(Music.lookup.release.coverArtArchive.front(size: .value(.small)))
    var cover: String?

    @GraphQL(Music.lookup.release.artistCredits._forEach(\.artist))
    var artists: [AlbumArtistCreditButton.Artist?]?

    @GraphQL(Music.lookup.release.discogs.genres)
    var genres: [String]?

    @GraphQL(Music.lookup.release.date)
    var date: String?

    @GraphQL(Music.lookup.release.media._forEach(\.tracks))
    var media: [[AlbumTrackCell.Track?]?]?

    @GraphQL(Music.lookup.release.lastFm.playCount)
    var playCount: Double?

    var body: some View {
        let media = self.media?.compactMap { $0?.compactMap { $0 } } ?? []
        let trackCount = media.reduce(0) { $0 + $1.count }
        let info = [genres?.first, date?.year.map(String.init)].compactMap { $0 }.joined(separator: " · ")

        return GeometryReader { geometry in
            FancyScrollView(
                headerHeight: 150 + geometry.safeAreaInsets.top + 32 + 44,
                scrollUpHeaderBehavior: .sticky,
                scrollDownHeaderBehavior: .sticky,
                header: {
                    HStack(spacing: 8) {
                        Image
                            .artwork(self.cover.flatMap(URL.init(string:)))
                            .cornerRadius(5)
                            .frame(width: 150, height: 150)

                        VStack(alignment: .leading) {
                            self.title.map { Text($0).font(.headline).fontWeight(.bold).foregroundColor(.primary) }

                            self.artists.map { artists in
                                ForEach(artists.compactMap { $0 }, id: \.name) { artist in
                                    AlbumArtistCreditButton(api: self.api,
                                                            artist: artist)
                                }
                            }

                            !info.isEmpty ? Text(info).font(.callout).foregroundColor(.secondary) : nil

                            Spacer()
                        }

                        Spacer()
                    }
                    .padding([.horizontal], 16)
                    .padding(.top, geometry.safeAreaInsets.top + 16 + 44)
                    .padding(.bottom, 16)
                }
            ) {
                VStack(spacing: 16) {
                    ForEach(media.indices) { mediaIndex in
                        VStack {
                            ForEach(media[mediaIndex].indices) { trackIndex in
                                VStack {
                                    AlbumTrackCell(albumTrackCount: trackCount,
                                                   playCountForAlbum: self.playCount,
                                                   track: media[mediaIndex][trackIndex])

                                    Divider()
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(.leading, 16)
                }
                .padding(.top, 16)
            }
        }
    }
}

extension String {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-DD"
        return dateFormatter
    }()

    fileprivate var year: Int? {
        return String
            .dateFormatter
            .date(from: self)
            .map { Calendar.current.component(.year, from: $0) }
    }

}
