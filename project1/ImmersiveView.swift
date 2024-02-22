//
//  ImmersiveView.swift
//  project1
//
//  Created by Ananth Nayak on 2/8/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine
import AVFoundation
var player: AVAudioPlayer?

func playSound() {
    guard let path = Bundle.main.path(forResource: "czt", ofType:"mp3") else {
        return
    }
    let url = URL(fileURLWithPath: path)

    do {
        player = try AVAudioPlayer(contentsOf: url)
        player!.numberOfLoops = -1 // Loop indefinitely
        player?.play()
        
    } catch let error {
        print(error.localizedDescription)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: CGFloat(drand48()),
            green: CGFloat(drand48()),
            blue: CGFloat(drand48()),
            alpha: CGFloat(drand48())
        )
    }
    static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
}

class SequenceViewModel: ObservableObject {
    private var cancellable: AnyCancellable?
    private let numbers = [5,6,7,8,9,20,20] // Example array of numbers
    private let delaySeconds = Float.random(in: 1.0...10.0) // Delay in seconds between each number
    private let randomSize = Float.random(in: 0.02...0.8)

    @Published var particleSystem = ParticleEmitterComponent()
    @Published var durations: [Double] = []
    @Published var loudness: [Double] = []
    @Published var pitches: [[Double]] = [[]]
    
    // Define a callback variable that will be triggered when a number is updated
    // This is triggered from startSequence
    var numberUpdated: ((Int) -> Void)?

    func setupParticleSystem() {
        self.particleSystem.emitterShape = .sphere
        self.particleSystem.birthLocation = .volume
        self.particleSystem.birthDirection = .normal
        self.particleSystem.emitterShapeSize = [10, 10, 10] * Float.random(in: 0.05...0.80)
        
        self.particleSystem.mainEmitter.birthRate = 300
        self.particleSystem.burstCount = 2000
        self.particleSystem.burstCountVariation = 20
        //particles.mainEmitter.BurstCount = 100
        self.particleSystem.mainEmitter.size = randomSize
        self.particleSystem.mainEmitter.lifeSpan = 2
        self.particleSystem.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        self.particleSystem.mainEmitter.spreadingAngle = 1
    }
    
    func generateRandomParameters(randomSeed: Float) -> [String: Any] {
        let parameters: [String: Any] = [
            "randomSeed":  randomSeed,            
            "birthRate": Float.random(in: 50.0...600) * randomSeed,
            "size": Float.random(in: 0.01...0.5),
            "lifeSpan": Double.random(in: 0.1...3.0),
            "emitterShape": Int.random(in: 1...7),
            "acceleration": [
                Float.random(in: 0.005...0.05) * randomSeed,
                Float.random(in: 0.005...0.05) * randomSeed,
                Float.random(in: 0.005...0.05) * randomSeed,
            ], 
            "colorStart": [
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
            ],
            "colorEnd": [
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
                CGFloat.random(in: 10...255),
            ]
            // "emitterShapeSize": [
            //     Float.random(in: 0.8...5) ,
            //     Float.random(in: 0.8...5) ,
            //     Float.random(in: 0.8...5)
            // ],
            // "burstCount": Int.random(in: 1000...3000),
            // "burstCountVariation": Int.random(in: 0...500),

            // "spreadingAngle": Float.random(in: 0...2) * randomSeed,
        ]
        return parameters
    }

    fileprivate func setEmitterShape(_ parameters: [String : Any]) {
        let randomShape = parameters["emitterShape"] as! Int
        switch randomShape {
        case 1:
            self.particleSystem.emitterShape = .cone
        case 2:
            self.particleSystem.emitterShape = .box
        case 3:
            self.particleSystem.emitterShape = .cylinder
        case 4:
            self.particleSystem.emitterShape = .plane
        case 5:
            self.particleSystem.emitterShape = .torus
        case 6:
            self.particleSystem.emitterShape = .point
        default:
            self.particleSystem.emitterShape = .sphere // Default to point if randomShape doesn't match any known shapes
        }
    }
    
    func burst(){
        let randomSeed = 1.0 //Float.random(in: 0.2...2)
        let parameters = generateRandomParameters(randomSeed: Float(randomSeed))
        // original parameters
        self.particleSystem.mainEmitter.birthRate = parameters["birthRate"] as! Float
        self.particleSystem.mainEmitter.size = parameters["size"] as! Float
        self.particleSystem.mainEmitter.lifeSpan = (parameters["lifeSpan"]) as! Double
        let colorStart = parameters["colorStart"] as! [CGFloat]
        let colorEnd = parameters["colorStart"] as! [CGFloat]
        self.particleSystem.mainEmitter.color = .evolving(
            start: .single(UIColor.rgba(colorStart[0], colorStart[1], colorStart[2], 1)),
            end: .single(UIColor.rgba(colorEnd[0], colorEnd[1], colorEnd[2], 1))
        )
        
        // experimental params added 
        let acceleration = parameters["acceleration"] as! [Float]
        self.particleSystem.mainEmitter.acceleration = [acceleration[0], acceleration[1], acceleration[2]]
        setEmitterShape(parameters)


        // params that are not used to maintain some predictability 
//        self.particleSystem.emitterShapeSize = [Float.random(in: 1...10), Float.random(in: 1...10), Float.random(in: 1...10)] * Float.random(in: 0.1...1.0)
//        self.particleSystem.burstCount = parameters["burstCount"] as! Int
//        self.particleSystem.burstCountVariation = parameters["burstCountVariation"] as! Int
//        self.particleSystem.mainEmitter.spreadingAngle = parameters["spreadingAngle"] as! Float


        print("burst updated with parameters:")
        print(parameters)
    }
    
    // The `startSequence` function takes an array of time intervals and creates a sequence of actions.
    // Each action is delayed by the corresponding time interval in the input array.
    // When each time interval elapses, the `burst` function is called to trigger a color update to the particles in the particle system.
    func startSequence(times : [Double]) {
        cancellable = Publishers.Sequence(sequence: times)
        // flatMap is used to transform the elements emitted by an upstream publisher into a new publisher. The new publishers are then merged into a single publisher.
            .flatMap { number in
                // Deferred waits until it receives a subscriber before it creates its upstream publisher.
                // Deferred is used to create a new Future publisher each time a value is emitted by the Publishers.Sequence publisher.
                Deferred {
                    // The Future publisher emits a single value after a delay.
                    // By using Deferred, the Future publisher and the delay are not created until a subscriber is attached. This ensures that the delay starts at the time of subscription,
                    // not at the time of creation of the Future publisher.
                    // The Future initializer takes a closure that takes a Promise as its parameter.
                    Future<Int, Never> { promise in
                        // The DispatchQueue.main.asyncAfter function is a part of Grand Central Dispatch (GCD) in Swift.
                        // This function schedules a block of code to be executed on the main queue after a certain period of time.
                        // The deadline: .now() + number parameter specifies when the block of code should be executed. .now() + number calculates a date that is number seconds from now.
                        DispatchQueue.main.asyncAfter(deadline: .now() + number) {
                            promise(.success(Int(number)))
                        }
                    }
                }
                // It's used to erase the type of a publisher and return it as an AnyPublisher instance.
                // In Combine, publishers are often chained together, with each operator in the chain potentially
                // changing the publisher's output type, failure type, or both. This can lead to complex, hard-to-read type signatures.
                // The eraseToAnyPublisher method erases all type information about the publisher's output type and failure type, and returns an
                // AnyPublisher that publishes the same output type and has the same failure type. This can make your code easier to read and write,
                // especially when dealing with complex publisher chains. In the context of the startSequence(times:) function in the SequenceViewModel class,
                // eraseToAnyPublisher is used to erase the type of the publisher created by the flatMap operator.
                // This allows the flatMap operator to return a single type of publisher, regardless of the types of the publishers created inside the flatMap closure.
                .eraseToAnyPublisher()
            }
            .sink(receiveValue: { [weak self] number in
                self?.numberUpdated?(number) // Call numberUpdated which has been set up as a callback in onAppear of the ImmersiveView
            })
    }
    
    func fetchDataFromEndpoint(urlString: String) {
        let networkManager = NetworkManager()
        networkManager.fetchData(from: urlString) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    do {
                        let decodedData = try JSONDecoder().decode(EndpointData.self, from: data)
                        // Update the model with fetched data
                        self?.durations = decodedData.durations
                        self?.loudness = decodedData.loudness
                        self?.pitches = decodedData.pitches
                        let value = decodedData.loudness.enumerated().map{ (index, element) in
                            if(element > -10){
                                return decodedData.durations[index]
                            }else{
                                return nil
                            }
                        }.compactMap{$0}
                       print(value)
                        
                        // Optionally, trigger actions based on the fetched data
                        self?.startSequence(times: value)
                    } catch {
                        print("Failed to decode data: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("Failed to fetch data: \(error.localizedDescription)")
                }
            }
        }
    }
    
   func initSequence(randomSeed: Float) {
       let values = [
           1.5, 1.0, 0.5, 0.2
       ]
       // multiply each value by the randomSeed
       let scaledValues = values.map { $0 * Double(randomSeed) }
       // let value = [18.04871, 22.22698, 25.87306, 27.67265, 28.7059, 33.62753, 33.82517, 33.97646, 34.13338, 34.22082, 34.3946, 34.66798, 34.7878,
           // 34.91025, 35.02127, 35.17823, 35.3702, 35.5673, 35.68857, 35.81052, 36.07796, 36.21152, 40.0849,]
       print("scaledValues: \(scaledValues) ssed: \(randomSeed)")
       self.startSequence(times: scaledValues)
   }

    // Add a new method to start a sequence based on fetched data
    func startSequence() {
        // Example: Use `durations` to control the delay between actions
        // This is just a placeholder to demonstrate how you might proceed
        print("Starting sequence with fetched durations: \(durations)")
        print("Starting sequence with fetched loudness: \(loudness)")
        print("Starting sequence with fetched pitches: \(pitches)")
    }
    
    deinit {
        cancellable?.cancel()
    }
}

struct EndpointData: Decodable {
    let durations: [Double]
    let loudness: [Double]
    let pitches: [[Double]]
}

struct ImmersiveView: View {
    @StateObject private var viewModel = SequenceViewModel()
    @State private var particleModel = ModelEntity()

    var body: some View {
        RealityView { content in
            viewModel.setupParticleSystem()
            particleModel.components.set(viewModel.particleSystem)
            content.add(particleModel)
        }
        .onAppear {
            playSound()
            let urlString = "https://synesthesia-tau.vercel.app/analyze?track_id=4ozN7LaIUodj1ADWdempuv"
            viewModel.fetchDataFromEndpoint(urlString: urlString)
//            viewModel.initSequence(randomSeed: Float.random(in: 0.7...2))
            viewModel.numberUpdated = { number in
                // Reassign the updated particleSystem to the ModelEntity
                particleModel.components.set(viewModel.particleSystem)
                // Trigger a burst of particles afer model is updated
                viewModel.burst()
                viewModel.initSequence(randomSeed: Float.random(in: 0.7...2))
            }
        }
        .onDisappear() {
            player?.stop()
        }
    }
    
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
