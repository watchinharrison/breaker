//
//  GameScene.swift
//  Pong2020
//
//  Created by David Harrison on 27/09/2019.
//  Copyright © 2019 David Harrison. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var paddle: SKSpriteNode!
    private var spinnyNode : SKShapeNode?
    private var paddleTocuhed: Bool = false
    private var startX: CGFloat = 0
    private var originalPaddleX: CGFloat = 0
    private var numberOfTiles = 4
    private var prevPaddlePosition: CGPoint!
    private var points:Int = 0
    
    let PointBlockCategory : UInt32 = 0x1 << 0
    let PowerupBlockCategory : UInt32 = 0x1 << 1
    let BombBlockCategory : UInt32 = 0x1 << 2
    let BallCategory   : UInt32 = 0x1 << 3
    let BottomCategory : UInt32 = 0x1 << 4
    let LitBlockCategory : UInt32 = 0x1 << 5
    let BlockCategory  : UInt32 = 0x1 << 6
    let BrokeBlockCategory  : UInt32 = 0x1 << 7
    let PaddleCategory : UInt32 = 0x1 << 8
    let BorderCategory : UInt32 = 0x1 << 9
    let PlatformCategory  : UInt32 = 0x1 << 10
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
    WaitingForTap(scene: self),
    Playing(scene: self),
    GameOver(scene: self)])
    
    var gameWon : Bool = false {
      didSet {
        let gameOver = childNode(withName: "gameMessage") as! SKSpriteNode
        let textureName = gameWon ? "YouWon" : "GameOver"
        let texture = SKTexture(imageNamed: textureName)
        let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
          SKAction.scale(to: 1.0, duration: 0.25)])
          
        gameOver.run(actionSequence)
      }
    }
    
    override func didMove(to view: SKView) {
        let insets = view.safeAreaInsets
        print(view.safeAreaInsets)
        let borderBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: frame.origin.x + insets.left, y: frame.origin.y - insets.left, width: frame.width - insets.right, height: frame.height))
        borderBody.friction = 0
        self.physicsBody = borderBody
        
//        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.8)
        
        physicsWorld.contactDelegate = self
        
        prevPaddlePosition = CGPoint(x: 0, y: -200)
        updatePaddle()

        let ball = childNode(withName: "ball") as! SKSpriteNode
        
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)
            
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        ball.physicsBody!.affectedByGravity = false
        ball.physicsBody!.collisionBitMask = PaddleCategory | LitBlockCategory | BlockCategory | BrokeBlockCategory | BorderCategory | BottomCategory | PlatformCategory
        borderBody.categoryBitMask = BorderCategory
        
        ball.physicsBody!.contactTestBitMask = BottomCategory | LitBlockCategory | BlockCategory | BrokeBlockCategory
        
        addBlocks()
        
        addPlatforms()
        
        let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
        gameMessage.name = "gameMessage"
        gameMessage.position = CGPoint(x: 0, y: 0)
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
            
        gameState.enter(WaitingForTap.self)
    }
    
    func addBlocks() {
        let numberOfBlocks = 15
        let numberOfRows = 3
        let blockWidth = SKSpriteNode(imageNamed: "litTile").size.width / 2
        let xOffset = CGFloat(-380.0)
        for i in 0..<numberOfBlocks {
            for j in 0..<numberOfRows {
                let block = SKSpriteNode(imageNamed: "litTile")
                
                block.setScale(0.5)
                block.zPosition = 4
                block.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * blockWidth, y: 230.0 - (CGFloat(j) * CGFloat(blockWidth)))

                block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
                block.physicsBody!.allowsRotation = true
                block.physicsBody!.affectedByGravity = false
                block.physicsBody!.friction = 0.0
                block.physicsBody!.affectedByGravity = false
                block.physicsBody!.isDynamic = false
                block.name = "litTile"
                block.physicsBody!.categoryBitMask = LitBlockCategory
                addChild(block)
            }
        }
    }
    
    func addPlatforms() {
        let numberOfPlatforms = 3
        let platformWidth = SKSpriteNode(imageNamed: "boxPurple").size.width / 2
        for _ in 0..<numberOfPlatforms {
            let xOffset = randomFloat(from: -450, to: 450)
            for i in 0..<3 {
                let platform = SKSpriteNode(imageNamed: "boxPurple")
                
                platform.setScale(0.5)
                platform.zPosition = 4
                platform.position = CGPoint(x: xOffset + CGFloat(CGFloat(i) + 0.5) * platformWidth, y:  -100)

                platform.physicsBody = SKPhysicsBody(rectangleOf: platform.frame.size)
                platform.physicsBody!.allowsRotation = true
                platform.physicsBody!.affectedByGravity = false
                platform.physicsBody!.friction = 0.0
                platform.physicsBody!.affectedByGravity = false
                platform.physicsBody!.isDynamic = false
                platform.name = "platform"
                platform.physicsBody!.categoryBitMask = PlatformCategory
                addChild(platform)
            }
        }
    }
    
    func updatePaddle() {
        childNode(withName: "paddle")?.removeFromParent()
        let widthOfPaddle = 58 + (numberOfTiles * 26)
        
        let paddleTexture = GameScene.generateTiledTexture(size: CGSize(width: widthOfPaddle, height: 30), imageNamed: "paddle", numberOfTiles: numberOfTiles)!
        paddle = SKSpriteNode(texture: paddleTexture)
        paddle.position = prevPaddlePosition
        paddle.zPosition = 2
        paddle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: widthOfPaddle, height: 30)) //SKPhysicsBody(texture: paddleTexture, size: paddleTexture.size())
        paddle.physicsBody!.allowsRotation = true
        paddle.physicsBody!.friction = 0.0
        paddle.physicsBody!.affectedByGravity = false
        paddle.physicsBody!.isDynamic = false
        paddle.name = "paddle"
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        paddle.physicsBody!.contactTestBitMask = PowerupBlockCategory
        addChild(paddle)
    }
    
    static func generateTiledTexture(size: CGSize, imageNamed imageName: String, numberOfTiles: Int) -> SKTexture? {
        var texture: SKTexture?

        UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: size.width, y: size.height)
        context?.rotate(by: 3.14159)
        context?.translateBy(x: 0, y: 0)
        if let startImage = UIImage(named: "\(imageName)-start") {
            print(startImage)
            context?.draw(startImage.cgImage!, in: CGRect(origin: CGPoint(x: 0, y: 0), size: startImage.size))
        }
        context?.translateBy(x: 29.0, y: 0)
        for _ in 0..<numberOfTiles {
            if let image = UIImage(named: "\(imageName)-mid") {
                context?.draw(image.cgImage!, in: CGRect(origin: CGPoint(x: 0, y: 0), size: image.size))
            }
            context?.translateBy(x: 26.0, y: 0)
        }
        if let endImage = UIImage(named: "\(imageName)-end") {
            print(endImage)
            context?.draw(endImage.cgImage!, in: CGRect(origin: CGPoint(x: 0, y: 0), size: endImage.size))
        }
        
        if let tiledImage = UIGraphicsGetImageFromCurrentImageContext() {
            print(tiledImage.size)
            texture = SKTexture(image: tiledImage)
        }

        UIGraphicsEndImageContext()

        return texture
    }
    
    func buildBomb(position: CGPoint) {
        let bomb = SKSpriteNode(imageNamed: "bomb")
        bomb.physicsBody = SKPhysicsBody(circleOfRadius: 38)
        bomb.physicsBody!.affectedByGravity = true
        bomb.physicsBody!.linearDamping = 1.0
        bomb.physicsBody!.categoryBitMask = BombBlockCategory
        bomb.physicsBody!.collisionBitMask = PaddleCategory
        bomb.physicsBody!.contactTestBitMask = PaddleCategory
        bomb.position = position
        bomb.zPosition = 5
        bomb.setScale(0.25)
        bomb.name = "bomb"
        addChild(bomb)
    }
    
    func buildPoint(position: CGPoint) {
        let powerupAnimatedAtlas = SKTextureAtlas(named: "Powerup03")
        var walkFrames: [SKTexture] = []

        let numImages = powerupAnimatedAtlas.textureNames.count / 2
        for i in 1...numImages {
            let powerupTextureName = "powerup03_\(i)"
            print(powerupTextureName)
            walkFrames.append(powerupAnimatedAtlas.textureNamed(powerupTextureName))
        }
        let powerupWalkingFrames = walkFrames

        let firstFrameTexture = powerupWalkingFrames[0]
        let point = SKSpriteNode(texture: firstFrameTexture)
        point.physicsBody = SKPhysicsBody(circleOfRadius: 33)
        point.physicsBody!.affectedByGravity = true
        point.physicsBody!.linearDamping = 1.0
        point.physicsBody!.categoryBitMask = PointBlockCategory
        point.physicsBody!.collisionBitMask = PaddleCategory
        point.physicsBody!.contactTestBitMask = PaddleCategory
        point.position = position
        point.zPosition = 5
        point.setScale(0.5)
        point.name = "point"
        point.run(SKAction.repeatForever(
        SKAction.animate(with: powerupWalkingFrames,
                         timePerFrame: 0.1,
                         resize: false,
                         restore: true)),
        withKey:"walkingInPlaceBear")

        addChild(point)
    }

    func buildPowerup(position: CGPoint) {
        let powerupAnimatedAtlas = SKTextureAtlas(named: "Powerup02")
        var walkFrames: [SKTexture] = []

        let numImages = powerupAnimatedAtlas.textureNames.count / 2
        for i in 1...numImages {
            let powerupTextureName = "powerup02_\(i)"
            print(powerupTextureName)
            walkFrames.append(powerupAnimatedAtlas.textureNamed(powerupTextureName))
        }
        let powerupWalkingFrames = walkFrames

        let firstFrameTexture = powerupWalkingFrames[0]
        let powerup = SKSpriteNode(texture: firstFrameTexture)
        powerup.physicsBody = SKPhysicsBody(circleOfRadius: 33)
        powerup.physicsBody!.affectedByGravity = true
        powerup.physicsBody!.linearDamping = 1.0
        powerup.physicsBody!.categoryBitMask = PowerupBlockCategory
        powerup.physicsBody!.collisionBitMask = PaddleCategory
        powerup.physicsBody!.contactTestBitMask = PaddleCategory
        powerup.position = position
        powerup.zPosition = 5
        powerup.setScale(0.5)
        powerup.name = "powerup"
        powerup.run(SKAction.repeatForever(
        SKAction.animate(with: powerupWalkingFrames,
                         timePerFrame: 0.1,
                         resize: false,
                         restore: true)),
        withKey:"walkingInPlaceBear")
        
        print(powerup)
        addChild(powerup)
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
      let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
      return (rand) * (to - from) + from
    }
    
    func knockOutBlock(node: SKNode) {
        let tile = SKSpriteNode(imageNamed: "tile")
        tile.setScale(0.5)
        tile.position = node.position
        tile.zPosition = 5
        tile.physicsBody = SKPhysicsBody(rectangleOf: tile.frame.size)
        tile.physicsBody!.allowsRotation = false
        tile.physicsBody!.friction = 0.0
        tile.physicsBody!.affectedByGravity = false
        tile.physicsBody!.isDynamic = false
        tile.name = "tile"
        tile.physicsBody!.categoryBitMask = BlockCategory
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
           // Code you want to be delayed
           self.addChild(tile)
           node.removeFromParent()
        }
    }
    
    func damageBlock(node: SKNode) {
        let brokeTile = SKSpriteNode(imageNamed: "brokeTile")
        brokeTile.setScale(0.5)
        brokeTile.position = node.position
        brokeTile.zPosition = 5
        brokeTile.physicsBody = SKPhysicsBody(rectangleOf: brokeTile.frame.size)
        brokeTile.physicsBody!.allowsRotation = false
        brokeTile.physicsBody!.friction = 0.0
        brokeTile.physicsBody!.affectedByGravity = false
        brokeTile.physicsBody!.isDynamic = false
        brokeTile.name = "brokeTile"
        brokeTile.physicsBody!.categoryBitMask = BrokeBlockCategory
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
           // Code you want to be delayed
           self.addChild(brokeTile)
           node.removeFromParent()
        }
    }
    
    func breakBlock(node: SKNode) {
        let particles = SKEmitterNode(fileNamed: "Spark")!
        particles.setScale(0.5)
        particles.position = node.position
        particles.zPosition = 5
        // Code you want to be delayed
        self.addChild(particles)
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 0.1), SKAction.removeFromParent()]))
        node.removeFromParent()
        let random = randomFloat(from: 0.0, to: 100.0)
        if random >= 75 {
             self.buildPoint(position: node.position)
        } else if random >= 50 {
            self.buildPowerup(position: node.position)
        } else if random >= 25 {
            self.buildBomb(position: node.position)
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        paddleTocuhed = true
        startX = pos.x
        originalPaddleX = self.paddle.position.x
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if (paddleTocuhed == true) {
            let offset = originalPaddleX + (pos.x - startX)
            if (offset > (self.size.width / 2) || offset < -(self.size.width / 2)) {
                return
            }
            self.paddle.position = CGPoint(x: offset, y: self.paddle.position.y)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        paddleTocuhed = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
            case is WaitingForTap:
              gameState.enter(Playing.self)
                
            case is Playing:
              
              for t in touches {
                  self.touchDown(atPoint: t.location(in: self))
              }
                
            case is GameOver:
                let newScene = GameScene(fileNamed:"GameScene")
                newScene!.scaleMode = .aspectFill
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                self.view?.presentScene(newScene!, transition: reveal)
            default:
              break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchMoved(toPoint: t.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchUp(atPoint: t.location(in: self))
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            self.touchUp(atPoint: t.location(in: self))
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if gameState.currentState is Playing {
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
              firstBody = contact.bodyA
              secondBody = contact.bodyB
            } else {
              firstBody = contact.bodyB
              secondBody = contact.bodyA
            }

            if firstBody.categoryBitMask == BallCategory
                && secondBody.categoryBitMask == BottomCategory {
                    gameState.enter(GameOver.self)
                    gameWon = false
                    print("Hit bottom. First contact has been made.")
            }

            if (firstBody.categoryBitMask == PowerupBlockCategory
                || firstBody.categoryBitMask == BombBlockCategory)
                && secondBody.categoryBitMask == BottomCategory {
                    firstBody.node?.removeFromParent()
            }

            if firstBody.categoryBitMask == BallCategory
                && secondBody.categoryBitMask == PaddleCategory {
                    print("Hit paddle.")
            }

            if firstBody.categoryBitMask == BallCategory
                && secondBody.categoryBitMask == BorderCategory {
                    print("Hit walls/roof.")
            }
                        
            if firstBody.categoryBitMask == BallCategory
                && secondBody.categoryBitMask == BrokeBlockCategory {
                    breakBlock(node: secondBody.node!)
                    if isGameWon() {
                      gameState.enter(GameOver.self)
                      gameWon = true
                    }
            }
            
            if firstBody.categoryBitMask == BallCategory
                && secondBody.categoryBitMask == LitBlockCategory {
                    knockOutBlock(node: secondBody.node!)
            }
            
            if firstBody.categoryBitMask == BallCategory
                && secondBody.categoryBitMask == BlockCategory {
                    damageBlock(node: secondBody.node!)
            }
            
            if firstBody.categoryBitMask == PointBlockCategory
                && secondBody.categoryBitMask == PaddleCategory {
                    firstBody.node?.removeFromParent()
                    print("GOT POINT")
                    points = points + 1
            }
            
            if firstBody.categoryBitMask == PowerupBlockCategory
                && secondBody.categoryBitMask == PaddleCategory {
                    firstBody.node?.removeFromParent()
                    print("GOT POWERUP")
                    numberOfTiles = numberOfTiles + 1
                    prevPaddlePosition = paddle.position
                    updatePaddle()
            }
            
            if firstBody.categoryBitMask == BombBlockCategory
                && secondBody.categoryBitMask == PaddleCategory {
                    firstBody.node?.removeFromParent()
                    print("GOT BOMB")
                    numberOfTiles = numberOfTiles - 1
                    if (numberOfTiles < 0) {
                        gameState.enter(GameOver.self)
                        gameWon = false
                    } else {
                        prevPaddlePosition = paddle.position
                        updatePaddle()
                    }
            }
        }
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodes(withName: "tile") { node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        self.enumerateChildNodes(withName: "brokeTile") { node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        self.enumerateChildNodes(withName: "litTile") { node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
    
    override func update(_ currentTime: TimeInterval) {
      gameState.update(deltaTime: currentTime)
    }
}
