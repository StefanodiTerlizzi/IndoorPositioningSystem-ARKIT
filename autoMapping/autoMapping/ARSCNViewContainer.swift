//
//  ARSCNViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
//

import SwiftUI
import ARKit
import RoomPlan
import Foundation
import Accelerate

struct ARSCNViewContainer: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    
    var sceneView = ARSCNView(frame: .zero)
    
    var configuration = ARWorldTrackingConfiguration()
    
    var delegate = ARSCNDelegate()
    
    func makeUIView(context: Context) -> ARSCNView {
        sceneView.delegate = delegate
        delegate.setSceneView(sceneView)
        //Set lighting to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        return sceneView
    }
    
    func sceneFromURL(_ url: URL) {
        sceneView.allowsCameraControl = true
        sceneView.scene = try! SCNScene(url: Model.shared.usdzURL!)
        sceneView.session.run(configuration)
    }
    
    func planeDetectorRun() {
        configuration.planeDetection = [/*.horizontal,*/ .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    }
    
    func loadWorldMap(worldMap: ARWorldMap, _ filename: String) {
        
        let startDate = Date()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        var id = 0
        if let data = try? Data(contentsOf: Model.shared.directoryURL.appending(path: "JsonParametric").appending(path: filename)) {
            if let room = try? JSONDecoder().decode(CapturedRoom.self, from: data) {
                for e in room.doors {
                    worldMap.anchors.append(ARAnchor(name: "door\(id)", transform: e.transform))
                    id = id+1
                }
                for e in room.walls {
                    worldMap.anchors.append(ARAnchor(name: "wall\(id)", transform: e.transform))
                    id = id+1
                    
                }
            }
        }
        
        guard let referenceImage = extractReferenceImages() else {
            print("No image retieved.")
            return
        }
        
        configuration.initialWorldMap = worldMap
        configuration.detectionImages = referenceImage
        configuration.maximumNumberOfTrackedImages = referenceImage.count
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(delegate.handleTap(gestureRecognize:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.session.run(configuration, options: options)
        
        if let p = Model.shared.lastKnowPositionInGlobalSpace, let a = Model.shared.actualRoto {
            
            //p.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(90.0), axis: [0,0,1]))
            var originInGlobalSpace = Model.shared.origin.copy() as! SCNNode
            //originInGlobalSpace.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(90.0), axis: [0,0,1]))
            originInGlobalSpace = projectNode(originInGlobalSpace, a)
            
            
            
            let Transl_Rot = PtoO_Pspace(T_P: p.simdWorldTransform, T_O: originInGlobalSpace.simdWorldTransform)
            let newOrig = Model.shared.origin.copy() as! SCNNode
            newOrig.simdPosition = Transl_Rot.0
            //newOrig.simdPosition.z = -2
            newOrig.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(Transl_Rot.1), axis: [0,1,0]))
            sceneView.session.setWorldOrigin(relativeTransform: newOrig.simdWorldTransform)
            
            NotificationCenter.default.post(name: .genericMessage2, object: "translation: \(Transl_Rot.0)\nrotation: \(Transl_Rot.1)")
            
        }
        //if let p = Model.shared.actualPosition {sceneView.session.setWorldOrigin(relativeTransform: worldMap.)}
        print("timeLoading, object: \(fabs(startDate.timeIntervalSinceNow) * 1000))")
        NotificationCenter.default.post(name: .timeLoading, object: fabs(startDate.timeIntervalSinceNow) * 1000)
        //delegate.trState = nil
        NotificationCenter.default.post(name: .trackingState, object: "load new Map")
    }
    
    func getWorldMap(url: URL) -> ARWorldMap? {
        guard let mapData = try? Data(contentsOf: url), let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData) else {
            return nil
        }
        return worldMap
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    
    
}

class ARSCNDelegate: NSObject, ARSCNViewDelegate {
    
    private var sceneView: ARSCNView?
    var trState: ARCamera.TrackingState?
    
    override init(){
        super.init()
    }
    
    func setSceneView(_ scnV: ARSCNView) {
        sceneView = scnV
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async{
            
            guard let imageAnchor = anchor as? ARImageAnchor else{return}
            let referenceImage = imageAnchor.referenceImage
            let refeenceImageName = referenceImage.name
            
            let position = SCNVector3(
                x: imageAnchor.transform.columns.3.x,
                y: imageAnchor.transform.columns.3.y,
                z: imageAnchor.transform.columns.3.z
            )
            let width = referenceImage.physicalSize.width
            let height = referenceImage.physicalSize.height
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.red
            
            let box = SCNBox(width: width, height: height, length: 0.02, chamferRadius: 0)
            box.materials = [material]
            let boxNode = SCNNode(geometry: box)
            let orientation = SCNMatrix4(imageAnchor.transform)
            
            boxNode.transform = orientation
            boxNode.position = position
            boxNode.name = refeenceImageName
            
            node.addChildNode(boxNode)
            
        }
        /*guard !(anchor is ARPlaneAnchor) else { return }
        var color = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0)
        if let n = anchor.name, n.hasPrefix("door") {color = UIColor(red: 255, green: 0, blue: 0, alpha: 1.0)}
        if let n = anchor.name, n.hasPrefix("wall") {color = UIColor(red: 0, green: 255, blue: 0, alpha: 1.0)}
        
        let sphereNode = generateSphereNode(color, 0.05)
        DispatchQueue.main.async {
            node.addChildNode(sphereNode)
        }*/
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        if let camera = self.sceneView?.session.currentFrame?.camera {
            DispatchQueue.main.async {NotificationCenter.default.post(name: .trackingPosition, object:
                                                                        camera.transform)}
        }
        
        if trState == self.sceneView?.session.currentFrame?.camera.trackingState{return}
        
        trState = self.sceneView?.session.currentFrame?.camera.trackingState
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .trackingState, object: self.trState)
        }
        
    }
    
    @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
        let sceneViewTappedOn = gestureRecognize.view as! ARSCNView
        let touchLocation = gestureRecognize.location(in: sceneViewTappedOn)
        
        let hitTestResults = sceneViewTappedOn.hitTest(touchLocation, options: nil)
        
        if let result = hitTestResults.first {
            let tappedNode = result.node
            if tappedNode.geometry is SCNBox {
                showInfoPanel(for: tappedNode)
            }
        }
    }
    
    func showInfoPanel(for node: SCNNode){
        let position = node.position
        let panelWidth: CGFloat = 0.3
        let panelHeight: CGFloat = 0.4
        let panel = SCNPlane(width: panelWidth, height: panelHeight)
        
        let material = SCNMaterial()
        let infoItem: Item? = CoreDataManager.shared.fetchItemByName(name: node.name ?? "Unknown image")
        let infoView = createInfoView(infoItem: infoItem)
        material.diffuse.contents = infoView.asImage()
        let panelNode = SCNNode(geometry: panel)
        panelNode.position = SCNVector3(position.x, position.y + 0.3, position.z)
        
    }
    
    func createInfoView(infoItem: Item?) -> UIView{
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        
        let nameLabel = UILabel(frame: CGRect(x: 10, y: 10, width: 280, height: 20))
        nameLabel.text = "Work Name: \(String(describing: infoItem?.name))"
        view.addSubview(nameLabel)
        
        let descriptionLabel = UILabel(frame: CGRect(x: 10, y: 40, width: 280, height: 40))
        descriptionLabel.text = "Description: \(String(describing: infoItem?.comment))"
        view.addSubview(descriptionLabel)
        
        let imageView = UIImageView(frame: CGRect(x: 10, y: 90, width: 100, height: 100))
        if let imageData = infoItem?.imageData, let uiImage = UIImage(data: imageData){
            imageView.image = uiImage
        }
        view.addSubview(imageView)
        
        let dimensionLabel = UILabel(frame: CGRect(x: 10, y: 200, width: 280, height: 20))
        dimensionLabel.text = "Dimension: \(String(describing: infoItem?.x_size)) x \(String(describing: infoItem?.y_size))."
        
        
        return view
    }
    
    
}


struct ARSCNViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        ARSCNViewContainer()
    }
}

func fetchDataItem() -> [Item]{
    let items: [Item] = CoreDataManager.shared.fetchAllItem()
    return items
}

func extractReferenceImages() -> Set<ARReferenceImage>? {
    let items = fetchDataItem()
    var referenceImages = Set<ARReferenceImage>()
    
    for item in items {
        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
            guard let cgImage = uiImage.cgImage else {
                print("Error in converision from UIImage to CGImage")
                continue
            }
            
            let imageSizeInMeters: CGFloat = CGFloat(item.x_size)
            let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: imageSizeInMeters)
            
            arImage.name = item.name ?? "Unknown Image"
            referenceImages.insert(arImage)
            
        }
    }
    return referenceImages.isEmpty ? nil : referenceImages
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image {
            rendererContext in layer.render(in: rendererContext.cgContext)
        }
    }
}
