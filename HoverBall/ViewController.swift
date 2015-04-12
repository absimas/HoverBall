//
//  ViewController.swift
//  HoverBall
//
//  Created by Simas Abramovas on 3/7/15.
//  Copyright (c) 2015 Simas Abramovas. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {
    
    @IBOutlet weak var skView: SKView!
    
    var shapeNode : SKShapeNode?
    var touchHash : Int?
    var scene : SKScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView.showsPhysics = true
        skView.showsFPS = true
        skView.showsDrawCount = true
        skView.showsNodeCount = true
        skView.showsQuadCount = true
        
        let screenWidth = view.frame.size.width
        let screenHeight = view.frame.size.height
        
        // Scene
        let scene = BallScene(size: CGSize(width: screenWidth, height: screenHeight))
        scene.addFloor(SKColor.blackColor(), size: CGSize(width: screenWidth, height: 20))
        scene.addBall(SKColor.blueColor(), radius: 30,
            position: CGPoint(x: screenWidth / 2, y: screenHeight / 2))
        
        // Animate scene entry
        let doorOpenX = SKTransition.doorsOpenHorizontalWithDuration(10.0)
        skView.presentScene(scene, transition: doorOpenX)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
}

