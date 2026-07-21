//
//  HumanBodySceneView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 21/06/26.
//

import SwiftUI
import SceneKit

struct HumanBodySceneView: UIViewRepresentable {
    
    let points: [AcupressurePoint]
    var onPointTapped: (AcupressurePoint) -> Void
    var onReady: ((HumanBodySceneView.Coordinator) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(points: points, onPointTapped: onPointTapped)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false  // 👈 band karo
        scnView.scene = context.coordinator.scene
        
        // Tap
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        scnView.addGestureRecognizer(tap)
        
        // Pan (rotate model)
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        scnView.addGestureRecognizer(pan)
        
        // Pinch (zoom)
        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        scnView.addGestureRecognizer(pinch)
        
        context.coordinator.scnView = scnView
        DispatchQueue.main.async {
            onReady?(context.coordinator)
        }
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    // MARK: - Coordinator
    class Coordinator: NSObject {
        var scene: SCNScene
        var scnView: SCNView?
        let points: [AcupressurePoint]
        let onPointTapped: (AcupressurePoint) -> Void
        var pointNodeMap: [SCNNode: AcupressurePoint] = [:]
        var bodyNode: SCNNode?
        
        init(points: [AcupressurePoint], onPointTapped: @escaping (AcupressurePoint) -> Void) {
            self.points = points
            self.onPointTapped = onPointTapped
            self.scene = SCNScene()
            super.init()
            setupScene()
        }
        
        var lastPanLocation: CGPoint = .zero
        var currentCameraZ: Float = 5.0  // zoom track karne ke liye

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {

            guard let scnView = scnView,
                  let bodyNode = bodyNode else { return }

            let translation = gesture.translation(in: scnView)

            let rotationX = Float(translation.y) * 0.005
            let rotationY = Float(translation.x) * 0.005

            bodyNode.eulerAngles.x += rotationX
            bodyNode.eulerAngles.y += rotationY

            gesture.setTranslation(.zero, in: scnView)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let cameraNode = scene.rootNode.childNode(
                withName: "mainCamera", recursively: false
            ) else { return }
            
            let scale = Float(gesture.scale)
            currentCameraZ /= scale
            currentCameraZ = max(1.5, min(10.0, currentCameraZ))  // limit zoom
            cameraNode.position.z = currentCameraZ
            gesture.scale = 1.0
        }
        
        func setupScene() {
            if let bodyScene = SCNScene(named: "human_body.usdz") {
                let bodyNode = bodyScene.rootNode.clone()

                bodyNode.name = "humanBody"
                bodyNode.scale = SCNVector3(0.01, 0.01, 0.01)
                bodyNode.position = SCNVector3(0, 0, 0)

                self.bodyNode = bodyNode
                scene.rootNode.addChildNode(bodyNode)
            }

            let cameraNode = SCNNode()
            cameraNode.name = "mainCamera"

            let camera = SCNCamera()
            camera.fieldOfView = 28

            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 0, 5)

            scene.rootNode.addChildNode(cameraNode)

            for point in points {
                addPointMarker(point)
            }
        }
        
        func addPointMarker(_ point: AcupressurePoint) {
            let sphere = SCNSphere(radius: 3.0)
            sphere.firstMaterial?.diffuse.contents = UIColor.cyan
            sphere.firstMaterial?.emission.contents = UIColor.cyan.withAlphaComponent(0.5)
            
            let markerNode = SCNNode(geometry: sphere)
            markerNode.position = SCNVector3(
                point.scenePosition.x * 100,
                point.scenePosition.y * 100,
                point.scenePosition.z * 100
            )
            markerNode.name = point.name
            
            bodyNode?.addChildNode(markerNode)
            pointNodeMap[markerNode] = point
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: nil)
            
            // Debug - uncomment to find coordinates
             if let hit = hitResults.first {
                 print("📍 \(hit.worldCoordinates)")
             }
            
            if let hit = hitResults.first,
               let point = pointNodeMap[hit.node] {
                zoomToPoint(point)
                onPointTapped(point)
            }
        }
        
        func resetCamera() {

            guard let cameraNode = scene.rootNode.childNode(
                withName: "mainCamera",
                recursively: false
            ) else { return }

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.8
            SCNTransaction.animationTimingFunction =
                CAMediaTimingFunction(name: .easeInEaseOut)

            cameraNode.position = SCNVector3(0, 0, 5)

            bodyNode?.eulerAngles = SCNVector3Zero
            bodyNode?.position = SCNVector3Zero

            SCNTransaction.commit()

            currentCameraZ = 5.0
        }
        
        func zoomToPoint(_ point: AcupressurePoint) {

            guard let cameraNode = scene.rootNode.childNode(
                withName: "mainCamera",
                recursively: false
            ) else { return }

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.6

            cameraNode.position = point.cameraZoomPosition

            bodyNode?.eulerAngles = SCNVector3Zero

            SCNTransaction.commit()
        }
    }
}
