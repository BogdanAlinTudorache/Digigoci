import SwiftUI

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var n: UInt64 = 0; Scanner(string: s).scanHexInt64(&n)
        self.init(red: Double((n >> 16) & 0xFF)/255, green: Double((n >> 8) & 0xFF)/255, blue: Double(n & 0xFF)/255)
    }
}

// MARK: - Models

struct PetState: Codable {
    var name: String = "Pixel"
    var hunger: Int = 70
    var happiness: Int = 70
    var energy: Int = 70
    var birthDate: Date = Date()
    var isAlive: Bool = true
    var isSleeping: Bool = false
    var totalCareActions: Int = 0
}

enum PetMood: String { case happy, content, hungry, sad, tired, sleeping, dead }

enum PetAge: String {
    case baby, child, adult
    var label: String { rawValue.capitalized }
}

enum ViewMode { case pet, settings }
enum AppTheme: String, CaseIterable { case system, light, dark }

// MARK: - Storage

final class PetStorage {
    static let shared = PetStorage()
    private init() {}
    private var storagePath: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Digigoci")
    }
    private var petFile: URL { storagePath.appendingPathComponent("pet.json") }

    func load() -> PetState? {
        try? FileManager.default.createDirectory(at: storagePath, withIntermediateDirectories: true)
        guard FileManager.default.fileExists(atPath: petFile.path),
              let data = try? Data(contentsOf: petFile),
              let pet = try? JSONDecoder().decode(PetState.self, from: data)
        else { return nil }
        return pet
    }

    func save(_ pet: PetState) {
        try? FileManager.default.createDirectory(at: storagePath, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(pet) else { return }
        try? data.write(to: petFile, options: .atomic)
    }
}

// MARK: - ViewModel

final class PetMonitor: NSObject, ObservableObject {
    @Published var pet: PetState = PetState()
    @Published var currentView: ViewMode = .pet
    @Published var actionFeedback: String? = nil

    @AppStorage("appTheme") var appTheme: String = "system"

    private var decayTimer: Timer?
    private var saveTimer: Timer?
    private var animationTimer: Timer?

    var mood: PetMood {
        if !pet.isAlive { return .dead }
        if pet.isSleeping { return .sleeping }
        if pet.hunger < 20 { return .hungry }
        if pet.energy < 20 { return .tired }
        if pet.happiness < 20 { return .sad }
        if pet.happiness > 70 && pet.hunger > 50 && pet.energy > 50 { return .happy }
        return .content
    }

    var age: PetAge {
        let days = Calendar.current.dateComponents([.day], from: pet.birthDate, to: Date()).day ?? 0
        if days < 3 { return .baby }
        if days < 10 { return .child }
        return .adult
    }

    // Digital art pet faces using box-drawing / ASCII art
    var petFace: String {
        switch mood {
        case .dead:     return "x_x"
        case .sleeping: return "-_-"
        case .happy:    return "^_^"
        case .content:  return "o_o"
        case .hungry:   return "O_o"
        case .sad:      return "T_T"
        case .tired:    return "=_="
        }
    }

    @Published var animationFrame: Int = 0

    var petBody: String {
        let ageStr = age
        let frame = animationFrame % 4

        switch ageStr {
        case .baby:
            return """
              /\\_/\\
             ( \(petFace) )
              > ^ <
            """
        case .child:
            switch frame {
            case 0: return " /\\_/\\\n( \(petFace) )\n/|   |\\\n\\L_/ \\_/"
            case 1: return " /\\_/\\\n( \(petFace) )\n/|   |\\\n/_\\ \\_\\"
            case 2: return " /\\_/\\\n( \(petFace) )\n/|   |\\\n\\__  __/"
            default: return " /\\_/\\\n( \(petFace) )\n/|   |\\\n _\\/_\\ "
            }
        case .adult:
            switch frame {
            case 0: return "  /\\_____/\\\n (  \(petFace)  )\n/|       |\\\n/\\   /\\\n  \\_/  \\_/"
            case 1: return "  /\\_____/\\\n (  \(petFace)  )\n/|       |\\\n_    _ \n\\L__/ /\\__/"
            case 2: return "  /\\_____/\\\n (  \(petFace)  )\n/|       |\\\n\\ \\  / /\n _\\_\\/_\\ "
            default: return "  /\\_____/\\\n (  \(petFace)  )\n/|       |\\\n \\  /\\ \n  \\/  \\__/"
            }
        }
    }

    override init() {
        super.init()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.startMonitoring()
        }
    }

    func startMonitoring() {
        if let saved = PetStorage.shared.load() {
            pet = saved
            // Apply offline decay
            applyOfflineDecay()
        }

        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.decayStats()
        }

        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            PetStorage.shared.save(self.pet)
        }

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            self?.animationFrame += 1
        }
    }

    private func applyOfflineDecay() {
        guard pet.isAlive, !pet.isSleeping else { return }
        // Simplified: no offline decay to keep things fun
    }

    private func decayStats() {
        guard pet.isAlive else { return }

        if pet.isSleeping {
            pet.energy = min(100, pet.energy + 2)
            if pet.energy >= 90 {
                pet.isSleeping = false
                showFeedback("Woke up refreshed!")
            }
            return
        }

        // Decay rates per minute
        pet.hunger = max(0, pet.hunger - 1)
        pet.happiness = max(0, pet.happiness - 1)
        pet.energy = max(0, pet.energy - 1)

        // Death check
        if pet.hunger == 0 && pet.happiness == 0 && pet.energy == 0 {
            pet.isAlive = false
            showFeedback("Your pet has passed away...")
        }

        PetStorage.shared.save(pet)
    }

    func feed() {
        guard pet.isAlive, !pet.isSleeping else { return }
        pet.hunger = min(100, pet.hunger + 25)
        pet.totalCareActions += 1
        showFeedback("Yum! +25 hunger")
        PetStorage.shared.save(pet)
    }

    func play() {
        guard pet.isAlive, !pet.isSleeping else { return }
        pet.happiness = min(100, pet.happiness + 20)
        pet.energy = max(0, pet.energy - 10)
        pet.totalCareActions += 1
        showFeedback("Fun! +20 happy, -10 energy")
        PetStorage.shared.save(pet)
    }

    func sleep() {
        guard pet.isAlive else { return }
        pet.isSleeping = true
        showFeedback("Zzz... recovering energy")
        PetStorage.shared.save(pet)
    }

    func wake() {
        pet.isSleeping = false
        showFeedback("Good morning!")
        PetStorage.shared.save(pet)
    }

    func revive() {
        pet.hunger = 50
        pet.happiness = 50
        pet.energy = 50
        pet.isAlive = true
        pet.isSleeping = false
        showFeedback("Your pet lives again!")
        PetStorage.shared.save(pet)
    }

    func resetPet(name: String) {
        pet = PetState(name: name)
        PetStorage.shared.save(pet)
    }

    private func showFeedback(_ msg: String) {
        actionFeedback = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.actionFeedback = nil
        }
    }

    deinit {
        decayTimer?.invalidate()
        saveTimer?.invalidate()
        animationTimer?.invalidate()
        PetStorage.shared.save(pet)
    }
}

// MARK: - Stat Bar

struct StatBar: View {
    let label: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).frame(width: 14).font(.caption)
            Text(label).font(.caption).frame(width: 55, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(statColor)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                        .animation(.easeInOut(duration: 0.3), value: value)
                }
            }
            .frame(height: 8)
            Text("\(value)")
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 24, alignment: .trailing)
        }
    }

    private var statColor: Color {
        if value < 20 { return .red }
        if value < 50 { return .orange }
        return color
    }
}

// MARK: - Pet View

struct PetView: View {
    @ObservedObject var monitor: PetMonitor
    @State private var petNameEdit: String = ""
    @State private var showRename: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(monitor.pet.name)
                        .font(.headline)
                    Text("\(monitor.age.label) \(monitor.mood.rawValue)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Button { withAnimation { monitor.currentView = .settings } } label: {
                    Image(systemName: "gearshape").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            // Pet display — digital art style
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "1a1a2e"))
                        .frame(height: 140)

                    VStack(spacing: 4) {
                        Text(monitor.petBody)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(petColor)
                            .multilineTextAlignment(.center)

                        if let feedback = monitor.actionFeedback {
                            Text(feedback)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color(hex: "00ff88"))
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                // Stats
                VStack(spacing: 6) {
                    StatBar(label: "Hunger", value: monitor.pet.hunger, icon: "fork.knife", color: .green)
                    StatBar(label: "Happy", value: monitor.pet.happiness, icon: "heart.fill", color: .pink)
                    StatBar(label: "Energy", value: monitor.pet.energy, icon: "bolt.fill", color: .yellow)
                }
                .padding(.horizontal, 14)
            }

            Spacer()

            // Actions
            if monitor.pet.isAlive {
                HStack(spacing: 12) {
                    if monitor.pet.isSleeping {
                        actionButton("Wake", icon: "sun.max.fill", color: .yellow) {
                            monitor.wake()
                        }
                    } else {
                        actionButton("Feed", icon: "fork.knife", color: .green) {
                            monitor.feed()
                        }
                        actionButton("Play", icon: "gamecontroller.fill", color: .pink) {
                            monitor.play()
                        }
                        actionButton("Sleep", icon: "moon.fill", color: .indigo) {
                            monitor.sleep()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            } else {
                Button {
                    monitor.revive()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Revive Pet")
                    }
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.red))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)
            }

            Divider()

            HStack {
                Text("v2.0 • Care: \(monitor.pet.totalCareActions)")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 320, height: 420)
        .id(monitor.animationFrame)  // Force redraw on animation
    }

    private var petColor: Color {
        switch monitor.mood {
        case .dead: return .gray
        case .sleeping: return Color(hex: "7777aa")
        case .happy: return Color(hex: "00ff88")
        case .content: return Color(hex: "88ccff")
        case .hungry: return Color(hex: "ffaa00")
        case .sad: return Color(hex: "ff6688")
        case .tired: return Color(hex: "aaaacc")
        }
    }

    @ViewBuilder
    private func actionButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.15)))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var monitor: PetMonitor
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { withAnimation { monitor.currentView = .pet } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.callout)
                        Text("Back").font(.callout)
                    }.foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Settings").font(.headline)
                Spacer()
                Text("Back").font(.callout).opacity(0)
            }
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("PET") {
                        HStack {
                            TextField("Pet name", text: $newName)
                                .textFieldStyle(.roundedBorder)
                                .font(.callout)
                                .onAppear { newName = monitor.pet.name }
                            Button("Rename") {
                                guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                monitor.pet.name = newName.trimmingCharacters(in: .whitespaces)
                                PetStorage.shared.save(monitor.pet)
                            }
                            .controlSize(.small)
                        }

                        HStack {
                            Text("Age: \(monitor.age.label)")
                                .font(.callout)
                            Spacer()
                            let days = Calendar.current.dateComponents([.day], from: monitor.pet.birthDate, to: Date()).day ?? 0
                            Text("\(days) days old")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    section("DANGER ZONE") {
                        Button("Reset Pet (New Pet)") {
                            let alert = NSAlert()
                            alert.messageText = "Reset your pet?"
                            alert.informativeText = "This will create a new pet. Your current pet will be lost."
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "Reset")
                            alert.addButton(withTitle: "Cancel")
                            if alert.runModal() == .alertFirstButtonReturn {
                                monitor.resetPet(name: "Pixel")
                                newName = "Pixel"
                            }
                        }
                        .foregroundStyle(.red)
                        .font(.callout)
                    }

                    section("APPEARANCE") {
                        Picker("Theme", selection: $monitor.appTheme) {
                            ForEach(AppTheme.allCases, id: \.rawValue) {
                                Text($0.rawValue.capitalized).tag($0.rawValue)
                            }
                        }
                        .pickerStyle(.segmented).labelsHidden()
                    }

                    section("ABOUT") {
                        Text("Digigoci v1.0").font(.callout)
                        Text("A digital art Tamagotchi living in your menu bar.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit Digigoci") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain).font(.callout).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .frame(width: 320, height: 420)
    }

    @ViewBuilder
    private func section<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
            content()
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @ObservedObject var monitor: PetMonitor

    var body: some View {
        Group {
            switch monitor.currentView {
            case .pet: PetView(monitor: monitor)
            case .settings: SettingsView(monitor: monitor)
            }
        }
        .onAppear { applyTheme() }
        .onChange(of: monitor.appTheme) { _ in applyTheme() }
    }

    private func applyTheme() {
        switch monitor.appTheme {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":  NSApp.appearance = NSAppearance(named: .darkAqua)
        default:      NSApp.appearance = nil
        }
    }
}

// MARK: - App Entry

@main
struct DigigociApp: App {
    @StateObject private var monitor = PetMonitor()

    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: monitor)
        } label: {
            HStack(spacing: 3) {
                Text(menuEmoji)
                Text(monitor.pet.name)
                    .font(.system(.caption))
            }
        }
        .menuBarExtraStyle(.window)
    }

    private var menuEmoji: String {
        switch monitor.mood {
        case .dead: return "💀"
        case .sleeping: return "😴"
        case .happy: return "😸"
        case .content: return "🐱"
        case .hungry: return "😿"
        case .sad: return "😢"
        case .tired: return "🥱"
        }
    }
}
