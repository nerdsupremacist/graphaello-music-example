//
//  AlbumDetailView.swift
//  Music
//
//  Created by Mathias Quintero on 12/27/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI
import FancyScrollView

struct AlbumDetailView: View {
    @GraphQL(Music.lookup.release.title)
    var title: String?

    @GraphQL(Music.lookup.release.coverArtArchive.front)
    var cover: String?

    @GraphQL(Music.lookup.release.media._forEach(\.tracks))
    var media: [[AlbumTrackCell.Track?]?]?

    var body: some View {
        let media = self.media?.compactMap { $0?.compactMap { $0 } } ?? []

        return GeometryReader { geometry in
            FancyScrollView(
                headerHeight: 150 + geometry.safeAreaInsets.top + 32 + 44,
                scrollUpHeaderBehavior: .sticky,
                scrollDownHeaderBehavior: .sticky,
                header: {
                    HStack(spacing: 8) {
                        Image
                            .artwork(self.cover.flatMap(URL.init(string:)))
                            .cornerRadius(5)
                            .frame(width: 150, height: 150)

                        VStack {
                            self.title.map { Text($0).font(.headline).fontWeight(.bold) }
                            Spacer()
                        }

                        Spacer()
                    }
                    .padding([.horizontal], 16)
                    .padding(.top, geometry.safeAreaInsets.top + 16 + 44)
                    .padding(.bottom, 16)
                }
            ) {
                VStack(spacing: 16) {
                    ForEach(media.indices) { mediaIndex in
                        VStack {
                            ForEach(media[mediaIndex].indices) { trackIndex in
                                VStack {
                                    AlbumTrackCell(track: media[mediaIndex][trackIndex])

                                    Divider()
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding(.leading, 16)
                }
                .padding(.top, 16)
            }
        }
    }
}
