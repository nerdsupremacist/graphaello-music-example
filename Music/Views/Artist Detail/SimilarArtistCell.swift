//
//  SimilarArtistCell.swift
//  Music
//
//  Created by Mathias Quintero on 12/27/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct SimilarArtistCell: View {
    let api: Music

    @GraphQL(Music.LastFMArtist.mbid)
    var id: String?

    @GraphQL(Music.LastFMArtist.name)
    var name: String?

    @GraphQL<[URL.Decoder?]?>(Music.LastFMArtist.topAlbums(first: .value(1)).nodes._forEach(\.image))
    var images: [URL?]?

    var body: some View {
        let stack = VStack {
            Image.artwork(images?.first?.flatMap { $0 }).clipShape(Circle())
            name.map { Text($0).font(.body).foregroundColor(.primary).lineLimit(1) }
        }

        return VStack {
            id.map { id in
                NavigationLink(destination: api.artistDetailView(mbid: id)) {
                    stack
                }
            }
            id == nil ? stack : nil
        }
    }
}
