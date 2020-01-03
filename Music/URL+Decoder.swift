//
//  URL+Decoder.swift
//  Music
//
//  Created by Mathias Quintero on 03.01.20.
//  Copyright © 2020 Mathias Quintero. All rights reserved.
//

import Foundation

extension URL {
    
    enum Decoder: GraphQLValueDecoder {
        static func decode(encoded: String) throws -> URL {
            return URL(string: encoded)!
        }
    }
    
}
