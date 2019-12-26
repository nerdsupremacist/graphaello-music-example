//
//  RelatedArtistList.swift
//  Music
//
//  Created by Mathias Quintero on 12/24/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct RelatedArtistList: View {
    @GraphQL(Music.lookup.artist.relationships.artists)
    var artists: Paging<RelatedArtistCell.Relationship>?

    var body: some View {
        artists.map { artists in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    PagingView(artists) { artist in
                        RelatedArtistCell(relationship: artist)
                            .frame(width: 180, height: 200, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
