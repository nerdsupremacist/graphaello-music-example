//
//  AlbumTrackCell.swift
//  Music
//
//  Created by Mathias Quintero on 12/27/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct AlbumTrackCell: View {
    let albumTrackCount: Int
    let playCountForAlbum: Double?

    @GraphQL(Music.Track.position)
    var position: Int?

    @GraphQL(Music.Track.title)
    var title: String?

    @GraphQL(Music.Track.recording.artistCredits)
    var credits: [AlbumTrackCellCredit.ArtistCredit?]?

    @GraphQL(Music.Track.recording.lastFm.playCount)
    var playCount: Double?

    var body: some View {
        let isPopular: Bool? = playCountForAlbum.map { playCountForAlbum in
            playCount.map { playCount in
                if playCount < playCountForAlbum {
                    return playCount > 0.1 * playCountForAlbum
                } else {
                    return playCount > 0.1 * playCountForAlbum * Double(albumTrackCount)
                }
            } ?? false
        }

        let credits = self.credits?
            .compactMap { $0 }
            .map { credit in
                [credit.name, credit.joinPhrase]
                    .compactMap { $0 }
                    .filter { $0 != "" }
                    .joined(separator: "")
            } ?? []

        return HStack(alignment: .top) {
            isPopular.map { isPopular in
                isPopular ?
                    AnyView(
                        Image(systemName: "star.fill")
                            .resizable()
                            .foregroundColor(.secondary)
                            .frame(width: 14, height: 14)
                            .padding(.top, 2)
                    ) : AnyView(Color.clear.frame(width: 14))
            }

            position.map { Text(String($0)).foregroundColor(.secondary) }

            VStack(alignment: .leading) {
                title.map { title in
                    Text(title)
                        .foregroundColor(.primary)
                }
                credits.count > 1 ?
                    Text(credits.joined(separator: ""))
                        .font(.body)
                        .foregroundColor(.secondary) : nil
            }
            Spacer()
        }
    }
}

struct AlbumTrackCellCredit {
    @GraphQL(Music.ArtistCredit.name)
    var name: String?

    @GraphQL(Music.ArtistCredit.joinPhrase)
    var joinPhrase: String?
}
