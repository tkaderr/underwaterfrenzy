//
//  GameScene.swift
//  UnderwaterFrenzy
//
//  Created by Tahim Kader on 6/27/17.
//  Copyright © 2017 Tahim Kader. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion
var gamescore = 0

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    
    //Variables
    
    let player = SKSpriteNode(imageNamed: "ship")
    let scorelabel = SKLabelNode(fontNamed: "LemonMilk")
    var levelNumber = 0
    let tapToStartLabel = SKLabelNode(fontNamed: "LemonMilk")
    let explosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
    let manager = CMMotionManager()
    var gameArea: CGRect
    
    
    enum gameState {
        case preGame
        case inGame
        case afterGame
    }
    
    var currentGameState = gameState.preGame
    
    struct PhysicsCategories {
        
        static let None : UInt32 = 0 //0
        static let Player : UInt32 = 0b1 //1
        static let Coin : UInt32 = 0b10 //2
        static let Enemy : UInt32 = 0b100 //4
        static let Wall: UInt32 = 0b1000
    }
    
    
    func changeScene(){
        
        let sceneToMoveTo = GameOverScene(size: self.size)
        sceneToMoveTo.scaleMode = self.scaleMode //same scaling as game scene
        let myTransition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneToMoveTo, transition: myTransition)
    }
    
    
    //Initialized
    override init(size:CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        
        super.init(size:size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    //Did Move Function
    override func didMove(to view: SKView) {
        
        print(PhysicsCategories.Coin)
        
        
        gamescore = 0 //have to reset the score here even after you set the gamescore globally
        
        var EnemyTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: Selector("spawnEnemy"), userInfo: nil, repeats: true)
        
        
       
//            var CoinTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: Selector("spawnCoin"), userInfo: nil, repeats: false)

        
        self.physicsWorld.contactDelegate = self
        
        //background
        let background = SKSpriteNode(imageNamed: "background")
        background.size = self.size
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        background.zPosition = 0
        background.name = "Backgrounds"
        self.addChild(background)
        
        
        //score label
        
        scorelabel.text  = "Score: 0"
        scorelabel.fontSize = 70
        scorelabel.fontColor = SKColor.white
        scorelabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scorelabel.position = CGPoint(x: self.size.width * 0.15, y: self.size.height + scorelabel.frame.size.height)
        scorelabel.zPosition = 100
        self.addChild(scorelabel)
        
        
        //player
        player.setScale(0.20)
        player.position = CGPoint(x: self.size.width/2, y: 0 - player.size.height)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        //player.physicsBody = SKPhysicsBody(circleOfRadius: <#T##CGFloat#>)
        player.zPosition = 2
        player.physicsBody!.restitution = 0
        player.physicsBody!.angularVelocity = 0
        player.physicsBody!.angularDamping = 1.0
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.affectedByGravity = true
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        //player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Coin | PhysicsCategories.Enemy
        self.addChild(player)
        
        
//        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
//        self.physicsBody = borderBody
//        self.physicsBody?.friction = 0
//        borderBody.contactTestBitMask =  PhysicsCategories.Player
//        borderBody.categoryBitMask = PhysicsCategories.Wall
//        borderBody.collisionBitMask = 0
        
        
//        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
//        self.physicsBody?.isDynamic = false
//        self.physicsBody?.categoryBitMask = PhysicsCategories.Wall
//        self.physicsBody?.contactTestBitMask = PhysicsCategories.Player
//        self.physicsBody?.collisionBitMask = PhysicsCategories.None
        
        let moveOnToScreenAction = SKAction.moveTo(y: self.size.height*0.9, duration: 0.3)
        scorelabel.run(moveOnToScreenAction)
        
        tapToStartLabel.text = "Tap To Start!"
        tapToStartLabel.fontSize = 100
        tapToStartLabel.fontColor = SKColor.white
        tapToStartLabel.zPosition = 1
        tapToStartLabel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        tapToStartLabel.alpha = 0
        self.addChild(tapToStartLabel)
        
        let fadeInAction = SKAction.fadeIn(withDuration: 0.3)
        tapToStartLabel.run(fadeInAction)
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        
        
        tapToStartLabel.run(scaleSequence)
        
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody!.isDynamic = false
        self.physicsBody!.categoryBitMask = PhysicsCategories.Wall
        self.physicsBody!.contactTestBitMask = PhysicsCategories.Player
        self.physicsBody!.collisionBitMask = PhysicsCategories.None
        
        
        //accelerometer
        manager.startAccelerometerUpdates();
        manager.accelerometerUpdateInterval = 0.1;
        manager.startAccelerometerUpdates(to: OperationQueue.main){
            (data,error) in
            
            
            self.physicsWorld.gravity = CGVector(dx:CGFloat(((data?.acceleration.x)! * 25)), dy:CGFloat(((data?.acceleration.y)! * 25)))
            
            if self.player.position.x > self.gameArea.maxX - self.player.size.width / 2 {
                self.player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                self.player.position.x = self.gameArea.maxX - self.player.size.width / 2
                
            }
            else if self.player.position.x < self.gameArea.minX + self.player.size.width / 2 {
                self.player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                self.player.position.x = self.gameArea.minX + self.player.size.width / 2
            }
        }
    }
    
    
    func startGame() {
        print("in start game")
        currentGameState = gameState.inGame
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
        let deleteAction = SKAction.removeFromParent()
        let deleteSequence = SKAction.sequence([fadeOutAction, deleteAction])
        tapToStartLabel.run(deleteSequence)
        
        
        let moveShipOnToScreenAction = SKAction.moveTo(y: self.size.height * 0.2, duration: 0.5)
        let startLevelAction = SKAction.run(startNewLevel)
        let startGameSequence = SKAction.sequence([moveShipOnToScreenAction, startLevelAction])
        player.run(startGameSequence)
        
    }
    
    func GameOver() {
        
        currentGameState = gameState.afterGame
        
        self.removeAllActions()

        self.enumerateChildNodes(withName: "Enemy"){
            enemy, stop in
            enemy.removeAllActions()
        }
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChangeScene = SKAction.wait(forDuration: 1)
        let changeSceneSequence = SKAction.sequence([waitToChangeScene, changeSceneAction])
        self.run(changeSceneSequence)
    }
    
    
    
    //Random Number
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min:CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    //Spawn Enemy
    func spawnEnemy(){
        
        let randomXStart = random(min: gameArea.minY, max: gameArea.maxY)
        let randomXEnd = random(min: gameArea.minX, max: gameArea.maxX)
        
        let endPoint = CGPoint(x: self.size.height * 1.2, y: randomXStart)
        let startPoint = CGPoint(x: -self.size.height * 0.2, y: randomXStart)
        
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "Enemy"
        enemy.setScale(0.15)
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player
        self.addChild(enemy)
        
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 10.0)
        let deleteEnemy = SKAction.removeFromParent()
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy])
        //enemy.run(enemySequence)
        
        if currentGameState == gameState.inGame{
            enemy.run(enemySequence)
        }
        
    }
    
    
    func spawnCoin(){
        
        let minY = (gameArea.minY) * 0.7
        let maxY = (gameArea.maxY) * 0.7
        let minX = (gameArea.minX) * 0.7
        let maxX = (gameArea.maxX) * 0.7
        
        let randomYStart = random(min: minY, max: maxY)
        let randomXStart = random(min: minX, max: maxX)
        
//        let randomYStart = random(min: (gameArea.minY) * 0.7, max: (gameArea.maxY) * 0.7)
//        let randomXStart = random(min: (gameArea.minX) * 0.7, max: (gameArea.maxX) * 0.7)
       
        let startPoint = CGPoint(x: randomXStart, y: randomYStart)
        
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.name = "Coin"
        coin.setScale(0.2)
        coin.position = startPoint
        coin.zPosition = 2
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)
        coin.physicsBody!.affectedByGravity = false
        coin.physicsBody!.categoryBitMask = PhysicsCategories.Coin
        coin.physicsBody!.collisionBitMask = PhysicsCategories.None
        coin.physicsBody!.contactTestBitMask = PhysicsCategories.Player
        self.addChild(coin)
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentGameState == gameState.preGame{
            print("changing to in game")
            print(PhysicsCategories.Coin)
            startGame()
            
//            if currentGameState == gameState.inGame{
//                spawnCoin()
//            }
            
            
            spawnCoin()
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        print("made contact")
        print(body1.categoryBitMask)
        print(body2.categoryBitMask)
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            body1 = contact.bodyA
            body2 = contact.bodyB
        }
        else {
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Coin {
            print("inside coin")
            body2.node?.removeFromParent()
            addScore()
            spawnCoin()
            
        }
        
        
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy {
            
            if body1.node != nil {
                spawnExplosion(spawnPos: body1.node!.position)
            }
            if body2.node != nil {
                spawnExplosion(spawnPos: body2.node!.position)
            }
            print(body1.categoryBitMask)
            print(body2.categoryBitMask)
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            GameOver()
        }
        
        
    }
    
    func spawnExplosion(spawnPos: CGPoint) {
        
        
        let explosion = SKEmitterNode(fileNamed: "Explosion")
        
        explosion?.position = spawnPos
        explosion!.zPosition = 3
        explosion!.setScale(0.5)
        
        self.addChild(explosion!)
        
        let ScaleIn = SKAction.scale(to: 1, duration: 0.1)
        let FadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        
        let explosionSequence = SKAction.sequence([explosionSound, ScaleIn, FadeOut, delete])
        explosion?.run(explosionSequence)
    }
    
    
    
    func addScore () {
        gamescore += 1
        scorelabel.text = "Score: \(gamescore)"
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1, duration: 0.2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        scorelabel.run(scaleSequence)
        
        
        if gamescore == 5 || gamescore == 10 || gamescore == 20 || gamescore == 30 || gamescore == 40 || gamescore == 50 || gamescore == 60{
            startNewLevel()
        }
    }
    
    func startNewLevel () {
        levelNumber += 1
        
        if self.action(forKey: "spawningEnemies") != nil {
            self.removeAction(forKey: "spawningEnemies")
        }
        
        var levelDuration = TimeInterval()
        
        switch levelNumber {
        case 1:
            levelDuration = 20.0
        case 2:
            levelDuration = 18.0
        case 3:
            levelDuration = 15.0
        case 4:
            levelDuration = 12.0
        case 5:
            levelDuration = 10.0
        case 6:
            levelDuration = 0.8
        case 7:
            levelDuration = 0.5
        default:
            levelDuration = 0.2
            print("cant find level info")
        }
        
        
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: levelDuration)
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForever = SKAction.repeatForever(spawnSequence)
        self.run(spawnForever, withKey: "spawningEnemies")
        
    }
    
    

    
    // Update Time Interval
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
