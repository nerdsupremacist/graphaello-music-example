//
//  AlbumArtistCreditButton.swift
//  Music
//
//  Created by Mathias Quintero on 12/28/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct AlbumArtistCreditButton: View {
    let api: Music

    @GraphQL(Music.Artist.mbid)
    var id: String

    @GraphQL(Music.Artist.name)
    var name: String?

    var body: some View {
        NavigationLink(destination: api.artistDetailView(mbid: id)) {
            name.map { Text($0).font(.subheadline).foregroundColor(.orange).fontWeight(.bold) }
        }
    }
}
