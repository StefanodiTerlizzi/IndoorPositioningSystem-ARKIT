//
//  ContentView.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 08/07/23.
//

import SwiftUI
import RealityKit
import SceneKit
import ARKit
import RoomPlan
import CoreMotion

enum Page: String, CaseIterable {
    case ScanningRoom
    case WorldMap
    case ConvertionLocalGlobal
}

struct ContentView : View {
    
//    @State var page: Page? = nil
//    
//    //var arscnViewContainer = ARSCNViewContainer()
//    //var scnViewContainer = SCNViewContainer()
//    //var delegate = RenderDelegate()
//    var visualizeRoom = VisualizeRoomViewContainer()
//    var exportRoom = SCNViewContainer()
//    var globalView = SCNViewContainer()
//    var singleView = SCNViewContainer()
//    var worldTracking = ARSCNViewContainer()
//    @State var cameraNodeVisualization = SCNNode()
//    @State var cameraNodePlanimetry = SCNNode()
//    
//    
//    @State private var showingAlert = false
//    @State private var showFeedbackExport = false
//    @State private var dimensions: [String] = []
//    
//    
//    
//    //@State var image: UIImage?
//    
//    @State var signDoor = false
//    
//    @State var indexMapLoaded = -1
//    
//    //let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
//    //let url = NSURL(fileURLWithPath: Model.shared.usdzURL!.absoluteString)
//    @State var fileExist = FileManager().fileExists(atPath: Model.shared.usdzURL!.absoluteString)
//    
//    @State var timeLoading: Double = 0.0
//    
//    @State var message = ""
//    @State var message2 = ""
//    @State var message3 = "m3"
//    @State var trackingState = ""
//    
//    let list = listOfFilesURL(path: ["Maps"])
//
//    
//    @State var indexRotoTrasl = -1
//    
//    @State private var selection = "none"
//    
    var containerWidth:CGFloat = UIScreen.main.bounds.width - 32.0
    
//    let colors = [UIColor(red: 0, green: 255, blue: 0, alpha: 0.5), UIColor(red: 255, green: 255, blue: 0, alpha: 0.5)]
//    
//    @State var mapsAvailable: [URL]? = Model.shared.mapsAvailable
//    @State var indexMapLoadedForVisualization = -1
//    @State var simdWorldTransform: [simd_float4x4] = []
//    
//    @State var selectedNode: SCNNode?
//    
    struct MainButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .buttonStyle(.bordered)
                .padding()
                .bold()
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 17)
                        .stroke(Color.white, lineWidth: 3)
                )
                
        }
    }

    
    var body: some View {
        
        
        NavigationView {
            ScrollView{
                VStack{
                    VStack{
                        Text("AUTOMAPPING").font(.largeTitle)
                            .bold()
                        .foregroundColor(.white)
                        Image("roomplan").resizable()
                            .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                            .frame(width: 150, height: 150)
                            .padding(.bottom)
                    }.position(x: 200, y: 120)
                    
                    VStack {
                        NavigationLink(destination: Navigation()) {
                            VStack{
                                
                                Text("NAVIGATION").font(.title).padding()
                                Text("Open the map and use your current location for navigation")//.lineLimit(nil)
                                    //.multilineTextAlignment(.center)
                                    //.fixedSize(horizontal: false, vertical: true).padding().padding()
                            }.modifier(MainButtonStyle())
                        }.padding()//.position(x: 195, y: -40)
                        
//                        NavigationLink(destination: ScanningEnvironment()) {
//                            VStack{
//                                
//                                Text("CHOOSE GLOBAL MAP").font(.title)
//                                Text("Start choosing Global Map")
//                                
//                            }.modifier(MainButtonStyle())
//                        }.padding()
//                        
                        NavigationLink(destination: ScanningEnvironment()) {
                            VStack{
                                
                                Text("CREATE NEW MAP").font(.title)
                                Text("Start the environmental scanning process")
                                
                            }.modifier(MainButtonStyle())
                        }.padding()
                        
                        NavigationLink(destination: ConvertionLocalGlobal()) {
                            VStack{
                                Text("CREATE MATRIX").font(.title2)
                                Text("Create matrix RotoTraslation")
                                
                            }.modifier(MainButtonStyle())
                                .frame(width: containerWidth * 0.90)
                        }.padding()
                        
                        Spacer()
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 11/255, green: 121/255, blue: 157/255))
        }
    }
}





#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, *) {
            ContentView()
        } else {
            // Fallback on earlier versions
        }
    }
}
#endif



final class ImageSaver: NSObject {
    static var error = ""
    func writeToPhotoAlbum(image: UIImage) {
        print(image)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            ImageSaver.error = "\(error)"
            print("error: \(error)")
        } else {
            ImageSaver.error = "Save completed!"
            print("Save completed!")
        }
    }
}
