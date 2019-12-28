//
//  ArtistAlbumList.swift
//  Music
//
//  Created by Mathias Quintero on 12/24/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct ArtistAlbumList: View {
    let api: Music
    let albums: Paging<ArtistAlbumCell.ReleaseGroup>?

    var body: some View {
        albums.map { albums in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    PagingView(albums) { album in
                        ArtistAlbumCell(api: self.api, releaseGroup: album)
                            .frame(width: 180, height: 200, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
