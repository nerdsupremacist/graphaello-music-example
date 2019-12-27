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

    var body: some View {
        HStack {
            position.map { Text(String($0)).foregroundColor(.secondary) }

            VStack(alignment: .leading) {
                title.map { title in
                    Text(title)
                        .foregroundColor(.primary)
                }
//                artist.map { artist in
////                    Text(artist)
//                        .foregroundColor(.secondary)
//                }
            }
            Spacer()
        }
    }
}
