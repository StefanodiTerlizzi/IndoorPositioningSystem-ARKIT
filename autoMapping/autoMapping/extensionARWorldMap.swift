//
//  extensionARWorldMap.swift
//  autoMapping
//
//  Created by stefano on 2023/09/11.
//

import Foundation
import ARKit

extension ARWorldMap: Encodable {
    public func encode(to encoder: Encoder) throws {
        //var container = encoder.container(keyedBy: CodingKeys.self)
        //try container.encode(id, forKey: .id)
        //try container.encode(type.rawValue, forKey: .type)
        //try container.encode(isFavorited, forKey: .isFavorited)
    }
}

struct ARWorldMapCodable: Codable {
    let anchors: [AnchorCodable]
    let center: simd_float3
    let extent: simd_float3
    let rawFeaturesPoints: [simd_float3]
}

struct AnchorCodable: Codable {
    let x: Float
    let y: Float
    let z: Float
}
