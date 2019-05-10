//
//  JSONDecoderExtensions.swift
//  CloudSDK
//
//  Created by Mike Kasperlik on 10.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

extension JSONDecoder {
    func decodeOrNull(type: Decodable, from: Data) {
        return try? decode(type, from: data)
    }
}
