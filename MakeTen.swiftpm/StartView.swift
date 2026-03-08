//
//  ContentView.swift
//  MakeTen
//
//  Created by 梶原景介 on 2025/11/16.
//

import SwiftUI

enum CityType: String, CaseIterable {
    case france = "France"
    case japan = "Japan"
    case america = "America"
    
    var backgroundImageName: String {
            switch self {
            case .japan:
                return "road_tokyo"
            case .france:
                return "road_france"
            case .america:
                return "road_newyork"
            }
        }
}

struct City: Identifiable {
    let id = UUID()
    let name: String
    let difficulty: String
    let digits: String
    let cityType: CityType
}

let cities: [City] = [
    City(name: "France", difficulty: "Easy", digits: "3", cityType: .france),
    City(name: "Japan", difficulty: "Normal", digits: "4", cityType: .japan),
    City(name: "America", difficulty: "Hard", digits: "5", cityType: .america)
]

struct StartView: View {

    @State private var showCountdown = false
    @State private var showConcept = false
    @State private var showCalculate = false
    @State private var selectedCity: City?
    @State private var showTutorial = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("MakeTen with Plate")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)

                        Text("Choose a city you want to play and \n make 10 using the number on the license plate.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 20)

                    VStack(spacing: 20) {
                        ForEach(cities) { city in
                            Button {
                                selectedCity = city
                                showCountdown = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(city.name)
                                            .font(.title2)
                                            .fontWeight(.bold)

                                        Text("Difficulty: \(city.difficulty)  Digits: \(city.digits)")
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(.black)
        

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.headline)
                                        .foregroundColor(.black.opacity(0.7))
                                }
                                .padding(.horizontal, 24)
                                .frame(width: 320, height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.yellow)
                                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                                )
                            }
                        }
                    }

                    Spacer()

                    VStack(spacing: 12) {

                        Button(action: {
                            showCalculate = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.headline)
                                Text("Practice Calculate")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(Color.green)
                            .frame(width: 260, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.black.opacity(0.6))
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                            )
                        }
                        
                        Button(action: {
                            showTutorial = true
                        }) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.headline)
                                Text("Tutorial")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(Color.cyan)
                            .frame(width: 260, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                            )
                        }
                        .padding(.top, 20)
                        
                        Button(action: {
                            showConcept = true
                        }) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .font(.headline)
                                Text("City Concept")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(Color.cyan)
                            .frame(width: 260, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                            )
                        }
                        .padding(.top, 10)
                    }
                    
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
            .navigationDestination(isPresented: $showCountdown) {
                if let city = selectedCity {
                    CountdownView(selectedCity: city.cityType)
                }
            }

            .navigationDestination(isPresented: $showCalculate) {
                CalculateQuizView()
            }
            .navigationDestination(isPresented: $showConcept) {
                ConceptView()
            }
            .navigationDestination(isPresented: $showTutorial) {
                TutorialView()
            }
        }
    }
}

#Preview {
    StartView()
}
