//
//  RelatedArtistCell.swift
//  Music
//
//  Created by Mathias Quintero on 12/24/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct RelatedArtistCell: View {
    @GraphQL(Music.Relationship.target.artist.name)
    var title: String?

    @GraphQL(Music.Relationship.target.artist.theAudioDb.thumbnail)
    var image: String?

    @GraphQL(Music.Relationship.type)
    var type: String?

    var body: some View {
        VStack {
            Image.artwork(image.flatMap(URL.init(string:))).clipShape(Circle())
            title.map { Text($0).font(.body).lineLimit(1) }
            type.map { Text($0).font(.body).fontWeight(.light).lineLimit(1) }
        }
    }
}
