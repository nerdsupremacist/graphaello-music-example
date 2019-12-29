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
    @GraphQL(Music.Track.position)
    var position: Int?

    @GraphQL(Music.Track.title)
    var title: String?

    @GraphQL(Music.Track.recording.artistCredits)
    var credits: [AlbumTrackCellCredit.ArtistCredit?]?

    var body: some View {
        let credits = self.credits?
            .compactMap { $0 }
            .map { credit in
                [credit.name, credit.joinPhrase]
                    .compactMap { $0 }
                    .filter { $0 != "" }
                    .joined(separator: " ")
            } ?? []

        return HStack(alignment: .top) {
            position.map { Text(String($0)).foregroundColor(.secondary) }

            VStack(alignment: .leading) {
                title.map { title in
                    Text(title)
                        .foregroundColor(.primary)
                }
                credits.count > 1 ?
                    Text(credits.joined(separator: " "))
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
