//
//  URLImage+artwork.swift
//  Music
//
//  Created by Mathias Quintero on 12/26/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI
import URLImage

extension Image {

    private static let artworkPlaceholder = Image("album-placeholder").theWholeShabang()

    static func artwork(_ url: URL?) -> some View {
        if let url = url {
            let image = URLImage<AnyView, AnyView>(url, placeholder: { _ in artworkPlaceholder }) { $0.image.theWholeShabang() }
            return AnyView(image)
        } else {
            return artworkPlaceholder
        }
    }

    private func theWholeShabang() -> AnyView {
        AnyView(
            self
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
        )
    }

}
