//
//  ExportRoomViewContainer..swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 12/07/23.
//

import Foundation
import SceneKit
import SwiftUI


class ExportRoomViewContainer {
    var sceneView: SceneView?
    var delegate = RenderDelegate()
    var scene = SCNScene()
    
    func setup(_ cameraNode: SCNNode) {
        //scene = try! SCNScene(url: Model.shared.usdzURL!)
        scene = try! SCNScene(named: "Room.usdz")!
        cameraNode.camera = SCNCamera()
        //scene.rootNode.addChildNode(Origin())
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            })
            .forEach{
                //$0.geometry?.firstMaterial?.diffuse.contents = Color(.blue)
                $0.scale.x = $0.scale.x < 1 ? $0.scale.x + 0.3 : $0.scale.x
                $0.scale.z = $0.scale.z < 1 ? $0.scale.z + 0.3 : $0.scale.z
            }
        cameraNode.position = SCNVector3(scene.rootNode.simdPosition.x, 10, scene.rootNode.simdPosition.z)
        
        //cameraNode.camera?.usesOrthographicProjection = true
        //cameraNode.camera?.orthographicScale = 10
        
        
        let vConstraint = SCNLookAtConstraint(target: scene.rootNode)
        cameraNode.constraints = [vConstraint]
        sceneView = SceneView(
            scene: scene,
            pointOfView: cameraNode,
            options: [.allowsCameraControl,.autoenablesDefaultLighting],
            delegate: self.delegate
        )
    }
    
}
