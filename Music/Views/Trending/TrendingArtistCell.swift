//
//  ArtistCell.swift
//  Music
//
//  Created by Mathias Quintero on 12/22/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import SwiftUI

struct TrendingArtistCell: View {
    let api: Music

    @GraphQL(Music.LastFMArtist.mbid)
    var id: String?

    @GraphQL(Music.LastFMArtist.name)
    var name: String?

    @GraphQL(Music.LastFMArtist.topTags(first: .value(3)).nodes._forEach(\.name))
    var tags: [String?]?

    @GraphQL(Music.LastFMArtist.topAlbums(first: .value(4)).nodes._forEach(\.image))
    var images: [String?]?

    @GraphQL(Music.LastFMArtist.topTracks(first: .value(1)).nodes._forEach(\.title))
    var mostFamousSongs: [String?]?

    var body: some View {
        let card = SimpleCardView(images: images?.compactMap { $0.flatMap(URL.init(string:)) },
                                  title: name,
                                  headline: mostFamousSongs?.first.flatMap { $0 }.map { "Known for \"\($0)\"" },
                                  caption: tags?.first(3).compactMap { $0 }.joined(separator: ", "))
        
        return VStack {
            id.map { id in
                NavigationLink(destination: api.artistDetailView(mbid: id)) {
                    card
                }
            }
            id == nil ? card : nil
        }
    }
}

extension Collection {

    func first(_ n: Int) -> [Element] {
        let diff = Swift.max(0, count - n)
        return dropLast(diff)
    }

}
