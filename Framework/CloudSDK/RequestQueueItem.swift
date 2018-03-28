//
//  RequestQueueItem.swift
//  CloudSDK
//
//  Created by Victoria Teufel on 29.03.18.
//  Copyright © 2018 PACE. All rights reserved.
//

import Foundation

struct RequestQueueItem {
    let request: URLRequest
    let completion: (Data?, URLResponse?, Error?) -> Void
}
