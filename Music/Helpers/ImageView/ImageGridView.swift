//
//  ImageGridView.swift
//  Music
//
//  Created by Mathias Quintero on 12/23/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct ImageGridView: View {
    let images: [URL]

    var body: some View {
        guard let first = images.first else { return AnyView(Text("")) }
        if images.count < 4 {
            return AnyView(Image.artwork(first))
        } else {
            let grid = VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image.artwork(images[0])
                    Image.artwork(images[1])
                }
                HStack(spacing: 0) {
                    Image.artwork(images[2])
                    Image.artwork(images[3])
                }
            }
            return AnyView(grid)
        }
    }
}
