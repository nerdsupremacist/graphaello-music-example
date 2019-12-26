//
//  ArtistAlbumCell.swift
//  Music
//
//  Created by Mathias Quintero on 12/23/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct ArtistAlbumCell: View {
    @GraphQL(Music.ReleaseGroup.title)
    var title: String?

    @GraphQL(Music.ReleaseGroup.theAudioDb.frontImage)
    var cover: String?

    @GraphQL(Music.ReleaseGroup.theAudioDb.frontImage)
    var discImage: String?

    var body: some View {
        VStack {
            Image.artwork(cover.flatMap(URL.init(string:)) ?? discImage.flatMap(URL.init(string:)))
                .clipped()
                .cornerRadius(5)

            title.map { Text($0).font(.body).lineLimit(1) }
        }
    }
}
