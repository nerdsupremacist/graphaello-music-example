//
//  ArtistInfoSection.swift
//  Music
//
//  Created by Mathias Quintero on 12/24/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct ArtistInfoSection: View {
    let title: String
    let content: AnyView

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title)
                .fontWeight(.medium)
                .padding(.horizontal, 16)

            content
        }
    }
}

extension ArtistInfoSection {

    init<Content: View>(_ title: String, @ViewBuilder content: () -> Content) {
        self.init(title: title, content: AnyView(content()))
    }

}
