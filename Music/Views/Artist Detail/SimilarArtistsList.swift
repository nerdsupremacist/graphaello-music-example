//
//  SimilarArtistsList.swift
//  Music
//
//  Created by Mathias Quintero on 12/27/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct SimilarArtistsList: View {
    let api: Music
    let artists: Paging<SimilarArtistCell.LastFMArtist>?

    var body: some View {
        artists.map { artists in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    PagingView(artists) { artist in
                        SimilarArtistCell(api: self.api, lastFmArtist: artist)
                            .frame(width: 140, height: 160, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
