import SwiftUI

struct ContentView: View {
    @StateObject private var controller = SP105EController.shared
    @State private var red = 255.0
    @State private var green = 0.0
    @State private var blue = 0.0
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    Text(controller.statusText)
                    Button("Connect to SP105E") {
                        Task {
                            do { try await controller.connectIfNeeded(); message = "Connected." }
                            catch { message = error.localizedDescription }
                        }
                    }
                }
                Section("Power") {
                    Button("Lights on") { run { try await controller.turnPowerOn() } }
                    Button("Lights off") { run { try await controller.turnPowerOff() } }
                }
                Section("Static color") {
                    colorSlider("Red", value: $red)
                    colorSlider("Green", value: $green)
                    colorSlider("Blue", value: $blue)
                    Button("Apply color") {
                        run { try await controller.setColor(red: UInt8(red), green: UInt8(green), blue: UInt8(blue)) }
                    }
                }
                if !message.isEmpty { Section("Message") { Text(message) } }
            }
            .navigationTitle("SP105E Lights")
        }
    }

    private func colorSlider(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack { Text(title); Spacer(); Text("\(Int(value.wrappedValue))") }
            Slider(value: value, in: 0...255, step: 1)
        }
    }

    private func run(_ action: @escaping () async throws -> Void) {
        Task {
            do { try await action(); message = "Command sent." }
            catch { message = error.localizedDescription }
        }
    }
}
