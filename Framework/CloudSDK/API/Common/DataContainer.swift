//
//  DataContainer.swift
//  CloudSDK
//
//  Created by Martin Dinh on 22.05.19.
//  Copyright © 2019 PACE. All rights reserved.
//

import Foundation

public extension ApiRequest {
    class DataContainer<A: Codable, R: Codable, I: Codable, M: Codable>: Codable {
        public let data: DataObject<A, R, M>
        public let included: [I]?

        // swiftlint:disable nesting
        private enum CodingKeys: String, CodingKey {
            case data
            case included
        }

        init(id: String, type: String, attributes: A?, relationships: R?, included: I?, meta: M?) {
            self.data = DataObject<A, R, M>(id: id, type: type, attributes: attributes, relationships: relationships, meta: meta)
            self.included = [I]()
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            data = try container.decode(DataObject.self, forKey: .data)
            included = try? container.decode([I].self, forKey: .included)
        }
    }

    class DataArrayContainer<A: Codable, R: Codable, I: Codable, M: Codable>: Codable {
        public let data: [DataObject<A, R, M>]
        public let included: [I]?

        // swiftlint:disable nesting
        private enum CodingKeys: String, CodingKey {
            case data
            case included
        }

        init(attributes: A?, relationships: R?, included: I?, meta: M?) {
            self.data = []
            self.included = [I]()
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            data = try container.decode([DataObject<A, R, M>].self, forKey: .data)
            included = try? container.decode([I].self, forKey: .included)
        }
    }

    struct DataObject<A: Codable, R: Codable, M: Codable>: Codable {
        public let id: String
        public let type: String
        public let attributes: A?
        public let relationships: R?
        public let meta: M?
    }
}
