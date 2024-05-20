//
//  VisualizeRoomViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 12/07/23.
//

import Foundation
import SceneKit
import SwiftUI

class VisualizeRoomViewContainer: UIView {
    var sceneView: SceneView?
    var delegate = RenderDelegate()
    var scene = SCNScene()
    
    func setup(_ cameraNode: SCNNode, _ url: URL) {
        //scene = try! SCNScene(url: Model.shared.usdzURL!)
        scene = try! SCNScene(url: url)
        cameraNode.camera = SCNCamera()
        //scene.rootNode.addChildNode(Origin())
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            })
            /*.forEach{
                //if (orthographicProjection) {$0.geometry?.firstMaterial?.diffuse.contents = Color(.blue)}
                $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
            }*/
        let _wall = scene.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! == "Wall0"
            })[0]
        cameraNode.position = SCNVector3(scene.rootNode.simdPosition.x, 10, scene.rootNode.simdPosition.z)
        /*if (orthographicProjection) {
            cameraNode.camera?.usesOrthographicProjection = true
            cameraNode.camera?.orthographicScale = 10
            cameraNode.rotation.y = wall.rotation.y
            cameraNode.rotation.w = wall.rotation.w
        }*/
        
        
        
        let vConstraint = SCNLookAtConstraint(target: scene.rootNode)
        cameraNode.constraints = [vConstraint]
        sceneView = SceneView(
            scene: scene,
            pointOfView: cameraNode,
            options: [.allowsCameraControl,.autoenablesDefaultLighting],
            //orthographicProjection ? [] : [.allowsCameraControl,.autoenablesDefaultLighting],
            delegate: self.delegate
        )
    }
}

class RenderDelegate: NSObject, SCNSceneRendererDelegate {
    // dummy render delegate to capture renderer
    
    var lastRenderer: SCNSceneRenderer!
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // store the renderer for hit testing
        lastRenderer = renderer
    }
}

