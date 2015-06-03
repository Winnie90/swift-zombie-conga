//
//  GameScene.swift
//  ZombieConga
//
//  Created by Christopher Winstanley on 30/01/2015.
//  Copyright (c) 2015 Games. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    let catMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPointZero
    let playableRect: CGRect
    var lastTouchLocation: CGPoint
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed( "hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed( "hitCatLady.wav", waitForCompletion: false)
    var invincible: Bool = false
    var lives = 5
    var gameOver = false
    let backgroundMovePointsPerSec: CGFloat = 200.0
    let backgroundLayer = SKNode()
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        lastTouchLocation = CGPointZero
        
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.repeatActionForever( SKAction.animateWithTextures(textures, timePerFrame: 0.1))
        
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor();
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    override func didMoveToView(view: SKView) {
        playBackgoundMusic("backgroundMusic.mp3")
        
        //initial setup
        backgroundColor = SKColor.whiteColor()
        
        backgroundLayer.zPosition = -1
        addChild(backgroundLayer)
    
        // set background add it to screen
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPointZero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y:0)
            background.name = "background"
            backgroundLayer.addChild(background)
        }
        
        // setup zombie
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
        backgroundLayer.addChild(zombie)
        
        // setup enemies
        runAction(SKAction.repeatActionForever( SKAction.sequence([SKAction.runBlock(spawnEnemy), SKAction.waitForDuration(4.0)])))
        
        // setup cats
        runAction(SKAction.repeatActionForever( SKAction.sequence([SKAction.runBlock(spawnCat), SKAction.waitForDuration(1.0)])))
        
        //debugDrawPlayableArea()
    }
    
    func backgroundNode() -> SKSpriteNode{
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPointZero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPointZero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPointZero
        background2.position = CGPoint(x: background1.size.width, y:0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width+background2.size.width,
            height: background1.size.height+background2.size.height
        )
        
        return backgroundNode
    }
    
    func moveBackground(){
        let backgroundVelocity = CGPoint(x: -self.backgroundMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(self.dt)
        backgroundLayer.position += amountToMove
        backgroundLayer.enumerateChildNodesWithName("background") { node, _ in
            let background = node as? SKSpriteNode
            let backgroundScreenPos = self.backgroundLayer.convertPoint(
                background!.position, toNode: self
            )
            if backgroundScreenPos.x <= -background!.size.width {
                background!.position = CGPoint(
                    x: background!.position.x + background!.size.width*2,
                    y: background!.position.y
                )
            }
        }
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
    #if os(iOS)
        override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
            let touch = touches.first as! UITouch
            let touchLocation = touch.locationInNode(backgroundLayer)
            sceneTouched(touchLocation)
        }
    
        override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
            let touch = touches.first as! UITouch
            let touchLocation = touch.locationInNode(backgroundLayer)
            sceneTouched(touchLocation)
        }
    #else
        override func mouseDown(theEvent:NSEvent){
            let touchLocation = theEvent.locationInNode(backgroundLayer)
            sceneTouched(touchLocation)
        }
        
        override func mouseDragged(theEvent:NSEvent){
            let touchLocation = theEvent.locationInNode(backgroundLayer)
            sceneTouched(touchLocation)
        }
    #endif
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        let offset = lastTouchLocation - zombie.position
        let speed = zombieMovePointsPerSec * CGFloat(dt)
        /*if offset.length() <= speed{
            zombie.position = lastTouchLocation
            velocity = CGPointZero
            stopZombieAnimation()
        } else {*/
        moveSprite(zombie, velocity: velocity)
        rotateSprite(zombie, direction: velocity, rotateRadiansPerSec:zombieRotateRadiansPerSec)
        //}
        boundsCheckZombie()
        moveTrain()
        moveBackground()
        
        if lives <= 0 && !gameOver{
            gameOver = true
            println("You Lose!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        // find the difference between the touched location and the zombies current position
        let offset = location - zombie.position
        // find the hypoteneuse
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        // normalize the vector
        let direction = offset / CGFloat(length)
        velocity = direction * zombieMovePointsPerSec
        startZombieAnimation()
    }
    
    func boundsCheckZombie() {
        let bottomLeft = backgroundLayer.convertPoint(
            CGPoint(x:0, y: CGRectGetMinY(playableRect)), fromNode:self
        )
        let topRight = backgroundLayer.convertPoint(
            CGPoint(x: size.width, y: CGRectGetMaxY(playableRect)), fromNode:self
        )
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(sprite.zRotation, velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        let enemyScenePos = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(min: CGRectGetMinY(playableRect) + enemy.size.height/2, max: CGRectGetMaxY(playableRect) - enemy.size.height/2)
        )
        enemy.position = backgroundLayer.convertPoint(enemyScenePos, fromNode: self)
        backgroundLayer.addChild(enemy)
        let enemyDestination = CGPoint(
            x: -enemy.size.width/2,
            y: enemyScenePos.y
        )
        let actionMove = SKAction.moveTo(backgroundLayer.convertPoint(enemyDestination, fromNode: self), duration: 3.0)
        //let actionMove = SKAction.moveToX(-enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startZombieAnimation() {
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(SKAction.repeatActionForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeActionForKey("animation")
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        let catScenePos = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect), max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect), max: CGRectGetMaxY(playableRect)))
        cat.position = backgroundLayer.convertPoint(catScenePos, fromNode: self)
        cat.setScale(0)
        backgroundLayer.addChild(cat)
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }
    
    func zombieHitCat(cat: SKSpriteNode) {
        //cat.removeFromParent()
        runAction(catCollisionSound)
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1)
        cat.zRotation = 0
        cat.runAction(
            SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
        )
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        runAction(enemyCollisionSound)
        
        invincible = true
        
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration) {
            zombie, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            zombie.hidden = remainder > slice / 2
        }
        let setHidden = SKAction.runBlock() {
            self.zombie.hidden = false
            self.invincible = false
        }
        zombie.runAction(SKAction.sequence([blinkAction, setHidden]))
        loseCats()
        lives--
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        backgroundLayer.enumerateChildNodesWithName("cat"){ node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHitCat(cat)
        }
        if invincible == false{
            var hitEnemies: [SKSpriteNode] = []
            backgroundLayer.enumerateChildNodesWithName("enemy") { node, _ in
                let enemy = node as! SKSpriteNode
                if CGRectIntersectsRect(CGRectInset(node.frame, 20, 20), self.zombie.frame) {
                    hitEnemies.append(enemy)
                }
            }
            for enemy in hitEnemies {
                zombieHitEnemy(enemy)
            }
        }
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        backgroundLayer.enumerateChildNodesWithName("train") { node, _ in
            trainCount++
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
        }
        if trainCount >= 30 && !gameOver {
            gameOver = true
            println("You win")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won:true)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseCats(){
        //how many we have lost so far
        var loseCount = 0
        backgroundLayer.enumerateChildNodesWithName("train") { node, stop in
            //random offset
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min:-100, max:100)
            randomSpot.y -= CGFloat.random(min:-100, max:100)
            
            node.name = ""
            node.runAction(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotateByAngle(π*4, duration:1.0),
                        SKAction.moveTo(randomSpot, duration:1.0),
                        SKAction.scaleTo(0, duration:1.0)
                    ]),
                    SKAction.removeFromParent()
                ])
            )
            loseCount++
            if loseCount >= 2{
                stop.memory = true
            }
        }
    }
}