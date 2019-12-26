//
//  ContentView.swift
//  Music
//
//  Created by Mathias Quintero on 12/22/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let api: Music

    var body: some View {
        NavigationView {
            api.trendingArtistsList(first: 5)
        }
    }
}
