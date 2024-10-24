import SwiftUI
import SceneKit
import ARKit
import Foundation

struct NavChoice: View {
    @State var globalMaps: [URL] = []
    var mapsView: SCNViewContainer = SCNViewContainer()

    init() {
        _globalMaps = State(initialValue: NavChoice.loadGlobalMaps())
    }

    static func loadGlobalMaps() -> [URL] {
        let directoryURL = Model.shared.directoryURL.appendingPathComponent("ExportCombined")
        let fileManager = FileManager.default

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: [])
            print(fileURLs)
            return fileURLs
        } catch {
            print("Error read files: \(error)")
            return []
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                Text("Please select the map you wish to explore:").font(.title3).padding()
                VStack {
                    Button(action: {
                        // Perform action
                    }) {
                        VStack {
                            mapsView
                                .padding()
                                .frame(width: 250, height: 200)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                            Text("MergedRooms").font(.title3).bold().padding().foregroundColor(.black)
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MAP CHOICES").font(.title).bold().padding(.top)
                }
            }
        }
    }
}

struct NavChoice_Previews: PreviewProvider {
    static var previews: some View {
        NavChoice()
    }
}
