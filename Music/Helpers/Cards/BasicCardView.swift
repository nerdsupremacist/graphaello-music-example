//
//  BasicCardView.swift
//  Music
//
//  Created by Mathias Quintero on 12/22/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct SimpleCardView: View {
    let images: [URL]?
    let title: String?
    let headline: String?
    let caption: String?

    var body: some View {
        CardContainer {
            VStack {
                images
                    .map { images in
                        ImageGridView(images: images)
                    }

                HStack {
                    VStack(alignment: .leading) {
                        title.map { title in
                            Text(title)
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.primary)
                                .lineLimit(3)
                        }

                        headline.map { headline in
                            Text(headline)
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundColor(.secondary)
                        }

                        caption.map { caption in
                            Text(caption.uppercased())
                                .font(.caption)
                                .fontWeight(.light)
                                .foregroundColor(.secondary)
                        }
                    }
                    .layoutPriority(100.0)

                    Spacer()
                }
                .padding()
            }
        }
    }
}
