//
//  BallScene.swift
//  HoverBall2
//
//  Created by Simas Abramovas on 04/07/15.
//  Copyright (c) 2015 Simas Abramovas. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class BallScene: SKScene, SKPhysicsContactDelegate {
    
    enum Direction {
        case North
        case South
        case East
        case West
    }
    
    let MOVEMENT_STEP = 50 as CGFloat
    let MOVEMENT_TIME = 0.2
    let OBSTACLE_WIDTH = 20 as CGFloat
    let COLLISION_SCALE = 0.7 as CGFloat
    let COLLISION_SCALE_DURATION = 0.2
    
    var mainNode: SKNode?
    
    enum ContactCategory: UInt32 {
        case Floor    = 1
        case Scene    = 2
        case Ball     = 4
        case Obstacle = 8
    }
    
    // Limitations
    let maxScaleBy = CGFloat(4/5.0)
    let maxImpulse = CGFloat(900)
    let minImpulse = CGFloat(100)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .ResizeFill
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsBody?.categoryBitMask = ContactCategory.Scene.rawValue
        physicsBody?.contactTestBitMask = ContactCategory.Scene.rawValue | ContactCategory.Ball.rawValue
        physicsBody?.collisionBitMask = ContactCategory.Scene.rawValue | ContactCategory.Ball.rawValue
        physicsWorld.contactDelegate = self
    }
    
    override func didMoveToView(view: SKView) {
        // Scene now visible, start adding obstacles every second
        let action = SKAction.runBlock(addRandomObstacle)
        let delay = SKAction.waitForDuration(1)
        let sequence = SKAction.sequence([action, delay])
        runAction(SKAction.repeatActionForever(sequence))
        
        // Keep increasing the mainNode
    }
    
    func randRange (lower: Int , upper: Int) -> CGFloat {
        return CGFloat(lower + Int(arc4random_uniform(UInt32(upper - lower + 1))))
    }
    
    // Contact delegate
    func didBeginContact(contact: SKPhysicsContact) {
        let bitMaskA = contact.bodyA.categoryBitMask
        let bitMaskB = contact.bodyB.categoryBitMask
        let ballCat = ContactCategory.Ball.rawValue
        let obstacleCat = ContactCategory.Obstacle.rawValue
        
        // Make sure the minimum impulse was reached
//        if contact.collisionImpulse > minImpulse {
            // Make sure a ball and an obstacle collided
            if (bitMaskA == ballCat && bitMaskB == obstacleCat) {
                contact.bodyA.node?.runAction(SKAction.scaleBy(COLLISION_SCALE, duration: COLLISION_SCALE_DURATION))
            } else if (bitMaskA == obstacleCat && bitMaskB == ballCat) {
                contact.bodyB.node?.runAction(SKAction.scaleBy(COLLISION_SCALE, duration: COLLISION_SCALE_DURATION))
            }
//        }
    }
    
    // ToDo anchor on the bottom of the ball? so it move up when Y axis is scaled
    func squashNode(node: SKNode, collisionImpulse: CGFloat) {
        if collisionImpulse < minImpulse {
            return
        }
        var impulse = max(collisionImpulse, maxImpulse)
        
        let xTo = 1 + (impulse / 9000)
        let yTo = 1 - (impulse / 9000)
        let interval = 0.2 - (impulse / 9000)
        
        var actions = Array<SKAction>();
        actions.append(SKAction.scaleXBy(xTo, y: yTo, duration: NSTimeInterval(interval)))
        actions.append(SKAction.scaleXBy(1/xTo, y: 1/yTo, duration: NSTimeInterval(interval)))
        let sequence = SKAction.sequence(actions);
        
        node.runAction(sequence)
    }
    
    func addRandomObstacle() {
        let obstacleMinHeight = Int(frame.height / 15)
        let obstacleMaxHeight = Int(frame.height / 5)
        let randHeight = randRange(obstacleMinHeight, upper: obstacleMaxHeight)
        let size = CGSize(width: OBSTACLE_WIDTH, height: randHeight)
        
        // Physics
        let physicsBody = SKPhysicsBody(rectangleOfSize: size)
        physicsBody.categoryBitMask = ContactCategory.Obstacle.rawValue
        physicsBody.contactTestBitMask = ContactCategory.Obstacle.rawValue | ContactCategory.Ball.rawValue
        physicsBody.collisionBitMask = ContactCategory.Obstacle.rawValue | ContactCategory.Ball.rawValue
        
        let obstacle = SKSpriteNode(color: SKColor.blackColor(), size: size)
        obstacle.position = CGPoint(x: frame.size.width, y: randRange(50, upper: Int(frame.size.height - 50)))
        obstacle.physicsBody = physicsBody
        
        let moveAction = SKAction.moveByX(-50, y: 0, duration: MOVEMENT_TIME)
        let repetitionCount = (frame.size.width - position.x) / 50
        obstacle.runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock({
                    self.shiftObstacle(obstacle)
                }),
                SKAction.waitForDuration(MOVEMENT_TIME)
            ])
        ))
        
        addChild(obstacle)
    }
    
    func shiftObstacle(obstacle: SKNode) {
        if (obstacle.position.x + obstacle.frame.width < 0) {
            obstacle.removeAllActions()
            obstacle.removeFromParent()
        } else {
            obstacle.runAction(SKAction.moveByX(-MOVEMENT_STEP, y: 0, duration: MOVEMENT_TIME))
        }
    }
    
    func addFloor(color: SKColor, size: CGSize) {
        let floor = SKSpriteNode(color: color, size: size)
        floor.anchorPoint = CGPoint(x: 0, y: 0)
        
        // Physics
        let physicsBody = SKPhysicsBody(edgeLoopFromRect: frame) // use scene frame edges
        physicsBody.dynamic = false
        physicsBody.categoryBitMask = ContactCategory.Floor.rawValue
        physicsBody.contactTestBitMask = ContactCategory.Floor.rawValue | ContactCategory.Ball.rawValue
        physicsBody.collisionBitMask = ContactCategory.Floor.rawValue | ContactCategory.Ball.rawValue
        floor.physicsBody = physicsBody
        
        addChild(floor)
    }
    
    func addBall(color: SKColor, radius: Int, position: CGPoint) {
        let ball = SKShapeNode(circleOfRadius: CGFloat(radius))
        ball.name = name
        // Physics
        let physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(radius))
        physicsBody.restitution = 0.7 // bounciness
        physicsBody.mass = 0
        physicsBody.friction = 1
        physicsBody.dynamic = true
        physicsBody.categoryBitMask = ContactCategory.Ball.rawValue
        physicsBody.contactTestBitMask = ContactCategory.Ball.rawValue | ContactCategory.Floor.rawValue | ContactCategory.Scene.rawValue
        physicsBody.collisionBitMask = ContactCategory.Ball.rawValue | ContactCategory.Floor.rawValue | ContactCategory.Scene.rawValue
        ball.physicsBody = physicsBody
        
        ball.position = position
        ball.fillColor = color
        addChild(ball)
        
        // Set the main node!
        mainNode = ball
        
        
        mainNode!.runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock({
                    self.increase(self.mainNode!)
                }),
                SKAction.waitForDuration(MOVEMENT_TIME)
                ])
            ))
    }
    
    func increase(node: SKNode) {
        node.runAction(SKAction.scaleBy(1.04, duration: MOVEMENT_TIME))
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        // Select 1st touch
        var touch = touches.allObjects[0] as UITouch
        
        // Find the direction (the furthest point from the mainNode)
        let direction = findDirection(mainNode!.position, touchPos: touch.locationInNode(self))
        
        var action: SKAction?
        switch (direction) {
        case .North:
            action = SKAction.moveByX(0, y: MOVEMENT_STEP, duration: MOVEMENT_TIME)
        case .South:
            action = SKAction.moveByX(0, y: -MOVEMENT_STEP, duration: MOVEMENT_TIME)
        case .East:
            action = SKAction.moveByX(-MOVEMENT_STEP, y: 0, duration: MOVEMENT_TIME)
        case .West:
            action = SKAction.moveByX(MOVEMENT_STEP, y: 0, duration: MOVEMENT_TIME)
        default:
            fatalError("Unrecognized direction!")
        }
        if let myAction = action {
            // ToDo runAction(action, withKey: String) -- save the action name to remove it specifically later
            mainNode!.runAction(SKAction.repeatActionForever(myAction))
        }
    }
    
    func findDirection(mainPos: CGPoint, touchPos: CGPoint) -> Direction {
        if (abs(touchPos.x - mainPos.x) > abs(touchPos.y - mainPos.y)) {
            // East or West
            let diff = touchPos.x - mainPos.x
            if (abs(diff) != diff) {
                // touchPos.x < nodePos.x => East
                return Direction.East
            } else {
                return Direction.West
            }
        } else {
            // North or South
            let diff = touchPos.y - mainPos.y
            if (abs(diff) != diff) {
                // touchPos.y < nodePos.y => South
                return Direction.South
            } else {
                return Direction.North
            }
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        mainNode!.removeAllActions()
    }
    
    override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        touchesEnded(touches, withEvent: event)
    }

}