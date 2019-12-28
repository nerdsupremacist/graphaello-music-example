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
    let api: Music
    
    @GraphQL(Music.ReleaseGroup.title)
    var title: String?

    @GraphQL(Music.ReleaseGroup.theAudioDb.frontImage)
    var cover: String?

    @GraphQL(Music.ReleaseGroup.theAudioDb.frontImage)
    var discImage: String?

    @GraphQL(Music.ReleaseGroup.releases(type: .value([.album]), status: .value([.official])).nodes._forEach(\.mbid))
    var releaseIds: [String?]?

    var body: some View {
        let stack = VStack {
            Image.artwork(cover.flatMap(URL.init(string:)) ?? discImage.flatMap(URL.init(string:)))
                .clipped()
                .cornerRadius(5)

            title.map { title in
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }

        guard let releaseId = releaseIds?.first.flatMap({ $0 }) else { return AnyView(stack) }
        return AnyView(
            NavigationLink(destination: api.albumDetailView(mbid: releaseId)) {
                stack
            }
        )
    }
}
