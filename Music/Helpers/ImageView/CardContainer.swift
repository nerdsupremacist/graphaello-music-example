//
//  Card.swift
//  Music
//
//  Created by Mathias Quintero on 12/23/19.
//  Copyright © 2019 Mathias Quintero. All rights reserved.
//

import Foundation
import SwiftUI

struct CardContainer: View {
    let content: AnyView

    @Environment(\.colorScheme)
    private var colorScheme: ColorScheme

    var body: some View {
        content
            .cornerRadius(10.0)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.borderColor(colorScheme: colorScheme), lineWidth: 1)
            )
            .padding([.horizontal, .bottom])
    }
}

extension CardContainer {

    init<Content: View>(content: () -> Content) {
        self.init(content: AnyView(content()))
    }

}

extension Color {

    static func borderColor(colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(.sRGB, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.2)
        case .light:
            fallthrough
        @unknown default:
            return Color(.sRGB, red: 150/255, green: 150/255, blue: 150/255, opacity: 0.1)
        }
    }

}
