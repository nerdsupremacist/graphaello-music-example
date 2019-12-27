//
//  ArtistMetadata.swift
//  Music
//
//  Created by Mathias Quintero on 12/27/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct ArtistMetadata: View {
    let type: String
    let text: String?

    var body: some View {
        text.map { text in
            HStack {
                VStack(alignment: .leading) {
                    Text(type.uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(text)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}
