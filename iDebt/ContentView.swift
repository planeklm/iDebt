//
//  ContentView.swift
//  iDebt
//
//  Created by klm on 08/09/2024.
//

import Combine
import SwiftUI

struct DebtData: Codable {
    let data: [DebtEntry]
}

struct DebtEntry: Codable {
    let totalPublicDebtOutstanding: String

    enum CodingKeys: String, CodingKey {
        case totalPublicDebtOutstanding = "debt_outstanding_amt"
    }
}

class DebtViewModel: ObservableObject {
    @Published var currentDebt: Double = 0
    private let incrementPerSecond: Double = 46296.2962962963

    func fetchDebtData(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v2/accounting/od/debt_outstanding?sort=-record_date&limit=1") else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(false)
                return
            }

            do {
                let debtData = try JSONDecoder().decode(DebtData.self, from: data)
                if let latestDebt = debtData.data.first?.totalPublicDebtOutstanding,
                   let debtValue = Double(latestDebt) {
                    DispatchQueue.main.async {
                        self.currentDebt = debtValue
                        completion(true)
                    }
                } else {
                    completion(false)
                }
            } catch {
                print("Error decoding JSON: \(error)")
                completion(false)
            }
        }.resume()
    }

    func updateDebt() {
        withAnimation {
            currentDebt += incrementPerSecond
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DebtViewModel()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else {
                VStack {
                    Spacer()
                    Text("United States National Debt 🇺🇸")
                        .bold()
                        .font(.headline)
                    
                    Text("-$\(formattedDebt)")
                        .contentTransition(.numericText(value: viewModel.currentDebt))
                        .frame(alignment: .center)
                        .font(.title)
                        .shadow(color: .gray, radius: 15, x: 5, y: 5)
                        .bold()
                    
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                        Text("-$46,296/s")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.red.opacity(0.2)))
                    .overlay(Capsule().stroke(Color.red.opacity(0.5), lineWidth: 1))
                    
                    Spacer()
                    
                    Text("by planeklm")
                        .font(.footnote)
                        .bold()
                }
            }
        }
        .onAppear {
            viewModel.fetchDebtData { success in
                if success {
                    withAnimation(.smooth(duration: 0.5)) {
                        isLoading = false
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            if !isLoading {
                viewModel.updateDebt()
            }
        }
    }
    
    var formattedDebt: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: viewModel.currentDebt)) ?? ""
    }
}

#Preview {
    ContentView()
}
