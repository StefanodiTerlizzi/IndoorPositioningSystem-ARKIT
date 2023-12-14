//
//  Model.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
//

import Foundation
import RoomPlan
import RealityKit
import ARKit

class Model: ObservableObject {
    var finalResults: CapturedRoom?
    
    let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let usdzURL: URL?
    let jsonURL: URL?
    let worldMapURL: URL?
    let conversionMatricesURL: URL
    var previousRoto: DictToRototraslation?
    var actualRoto: DictToRototraslation?
    @Published var lastKnowPositionInGlobalSpace: SCNNode?
    var origin = SCNNode()
    var statusLocalSession: ARCamera.TrackingState = .notAvailable
    
    var mapsAvailable: [URL]? = getMapsAvailables()
    
    //@Published var matchingNodesForAPI: [String: (SCNNode, SCNNode)] = [:]
    
    //singleton
    static let shared = Model()
    
    var positionsKnowns: [DictToRototraslation] = []
    
    init(){
        origin.simdWorldTransform = simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
        usdzURL = directoryURL.appending(path: "Room.usdz")
        jsonURL = directoryURL.appending(path: "Room.json")
        worldMapURL = directoryURL.appending(path: "worldMapURL")
        
        conversionMatricesURL = directoryURL.appending(path: "conversionsMatrices.json")
        
        Task{createSupportDirectories()}
    }
    
    func updateRotos(_ prev: DictToRototraslation?, _ actual: DictToRototraslation){
        previousRoto = prev
        actualRoto = actual
        Model.shared.statusLocalSession = .notAvailable
    }
    
    func jsonDataFinalResult() -> Data? {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(finalResults)
            print(String(decoding: jsonData, as: UTF8.self))
            return jsonData
        } catch {
            print("Error = \(error)")
            return nil
        }
    }
    
}
