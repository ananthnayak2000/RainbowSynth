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
    guard let path = Bundle.main.path(forResource: "czt", ofType:"wav") else {
        return
    }
    let url = URL(fileURLWithPath: path)

    do {
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
        
    } catch let error {
        print(error.localizedDescription)
    }
}

class SequenceViewModel: ObservableObject {
    private var cancellable: AnyCancellable?
    private let numbers = [5,6,7,8,9,20,20] // Example array of numbers
    private let delaySeconds = 10.0 // Delay in seconds between each number

    @Published var particleSystem = ParticleEmitterComponent()
    @Published var durations: [Double] = []
    @Published var loudness: [Double] = []
    @Published var pitches: [[Double]] = [[]]
    
    // Define a callback variable
    var numberUpdated: ((Int) -> Void)?
    func setupParticleSystem() {
//        self.particleSystem.timing = .repeating(warmUp: 0, emit:ParticleEmitterComponent.Timing.VariableDuration(duration:1), idle: ParticleEmitterComponent.Timing.VariableDuration(duration: 1))
        self.particleSystem.emitterShape = .sphere
        self.particleSystem.birthLocation = .volume
        self.particleSystem.birthDirection = .normal
        self.particleSystem.emitterShapeSize = [10, 10, 10] * 0.05
        
        self.particleSystem.mainEmitter.birthRate = 300
        self.particleSystem.burstCount = 2000
        self.particleSystem.burstCountVariation = 0
        //particles.mainEmitter.BurstCount = 100
        self.particleSystem.mainEmitter.size = 0.02
        self.particleSystem.mainEmitter.lifeSpan = 5
        self.particleSystem.mainEmitter.color = .evolving(start: .single(.orange), end: .single(.blue))
        self.particleSystem.mainEmitter.spreadingAngle = 1
        
        
    }
    
    func burst(){
        self.particleSystem.mainEmitter.color = .evolving(start: .single(.red), end: .single(.green))
        print("bursted")
    }
    func startSequence(times : [Double]) {
        cancellable = Publishers.Sequence(sequence: times)
            .flatMap { number in
                Just(number)
                    .delay(for: .seconds(number), scheduler: RunLoop.main)
            }
            .sink(receiveValue: { [weak self] number in
                self?.burst()
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

    // Add a new method to start a sequence based on fetched data
    func startSequenceBasedOnFetchedData() {
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

    var body: some View {
        RealityView { content in
            let particleModel = ModelEntity()
           
            
            viewModel.setupParticleSystem()
            particleModel.components.set(viewModel.particleSystem)
            content.add(particleModel)
            //viewModel.startSequence()
        }.onAppear {
            playSound()// Setup the callback
            let urlString = "https://synesthesia-tau.vercel.app/analyze?track_id=4ozN7LaIUodj1ADWdempuv"
            viewModel.fetchDataFromEndpoint(urlString: urlString)
            // Setup the callback
            viewModel.setupParticleSystem()
            viewModel.numberUpdated = { number in
                viewModel.burst()            }
        }
    }
    
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
