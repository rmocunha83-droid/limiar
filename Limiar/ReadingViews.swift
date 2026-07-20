@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct AIReadingPreparationView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

    private var itemCount: Int {
        model.faithProfile.explanationDepth.readingItemCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.warmGold.opacity(0.10))
                        .frame(width: 58, height: 58)
                        .scaleEffect(reduceMotion ? 1 : (isBreathing ? 1.10 : 0.92))

                    Circle()
                        .stroke(Color.warmGold.opacity(0.26), lineWidth: 1)
                        .frame(width: 58, height: 58)

                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.warmGold)
                        .scaleEffect(reduceMotion ? 1 : (isBreathing ? 1.04 : 0.98))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Criando suas reflexões")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.ivory)

                    Text("Estamos preparando sua travessia bíblica com explicações para este momento.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(0..<itemCount, id: \.self) { index in
                        Capsule()
                            .fill(Color.sageButton.opacity(reduceMotion ? (index == 1 ? 0.72 : 0.36) : (isBreathing ? 0.78 : 0.26)))
                            .frame(height: 5)
                            .shadow(
                                color: reduceMotion ? .clear : Color.sageButton.opacity(isBreathing ? 0.22 : 0.04),
                                radius: isBreathing ? 7 : 1,
                                y: 0
                            )
                            .animation(
                                reduceMotion
                                    ? nil
                                    : .easeInOut(duration: 0.9)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.22),
                                value: isBreathing
                            )
                    }
                }

                Text("Isso costuma levar alguns segundos.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.softText.opacity(0.86))
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .limiarPanel()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

struct AIReadingRetryView: View {
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.warmGold)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Não foi possível preparar sua reflexão agora")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.ivory)

                    Text("Tente novamente em instantes. Confira sua conexão com a internet antes de tentar outra vez.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                }
            }

            Button(action: retry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Tentar novamente")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.deepInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(18)
        .limiarPanel()
    }
}

struct AIReadingLocalSessionNotice: View {
    let isRetrying: Bool
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.warmGold)
                    .frame(width: 28, height: 28)

                Text("Não foi possível preparar as explicações agora. Sua leitura de hoje está aqui — as explicações voltam quando a conexão for restabelecida.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: retry) {
                HStack(spacing: 8) {
                    if isRetrying {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.sageButton)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isRetrying ? "Tentando novamente" : "Tentar novamente")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.sageButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.sageButton.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.sageButton.opacity(0.45), lineWidth: 1)
                )
            }
            .disabled(isRetrying)
            .accessibilityLabel(isRetrying ? "Tentando preparar as explicações" : "Tentar preparar as explicações novamente")
        }
        .padding(16)
        .limiarPanel()
    }
}

struct SpiritualReadingCard: View {
    let item: SpiritualReadingItem
    let isSaved: Bool
    let saveAction: () -> Void
    let listenAction: () -> Void
    let narrationState: PassageNarrationButtonState
    var showsReflection = true
    var showsNarration = true
    var isSaveLocked = false
    var isNarrationLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Label(item.reference, systemImage: "quote.opening")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.warmGold)
                    .lineLimit(2)

                Spacer()

                Button(action: saveAction) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(isSaved ? Color.sageButton : Color.ivory)
                        if isSaveLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Color.deepInk)
                                .padding(4)
                                .background(Color.warmGold, in: Circle())
                                .offset(x: 5, y: 5)
                        }
                    }
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .accessibilityLabel(isSaveLocked ? "Guardar trecho é um recurso Premium" : (isSaved ? "Remover trecho salvo" : "Salvar trecho"))
            }

            Text(item.text)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

            if showsReflection {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Explicação espiritual \(item.reference)")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Color.warmGold)

                    Text(item.homily)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.ivory.opacity(0.92))
                        .lineSpacing(5)

                    Text(item.practicalConclusion)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.softText.opacity(0.92))
                        .lineSpacing(5)
                }
                .padding(14)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            }

            if showsNarration {
                Button(action: listenAction) {
                    HStack(spacing: 8) {
                        if narrationState == .generating {
                            ProgressView()
                                .controlSize(.small)
                                .tint(Color.sageButton)
                        } else {
                            ZStack(alignment: .bottomTrailing) {
                                Image(systemName: narrationState.systemImage)
                                if isNarrationLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(Color.deepInk)
                                        .padding(3)
                                        .background(Color.warmGold, in: Circle())
                                        .offset(x: 5, y: 5)
                                }
                            }
                            .frame(width: 24, height: 24)
                        }

                        Text(narrationState.title)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(ReadingActionButtonStyle(isHighlighted: narrationState.isHighlighted))
                .accessibilityLabel(isNarrationLocked ? "Ouvir este trecho é um recurso Premium" : narrationState.title)
            }
        }
        .padding(18)
        .limiarPanel()
    }
}

struct ReadingBlock: View {
    let title: String
    let text: String

    private var cleanedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        if !cleanedText.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Color.gold)
                Text(cleanedText)
                    .font(.system(size: 17))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(5)
            }
            .padding(16)
            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ReadingActionButtonStyle: ButtonStyle {
    let isHighlighted: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                isHighlighted ? Color.sageButton.opacity(0.22) : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? Color.sageButton.opacity(0.7) : Color.white.opacity(0.14), lineWidth: 1)
            )
            .foregroundStyle(isHighlighted ? Color.sageButton : Color.ivory)
            .opacity(configuration.isPressed ? 0.74 : 1)
    }
}

enum PassageNarrationButtonState: Equatable {
    case idle
    case generating
    case playing
    case paused

    var title: String {
        switch self {
        case .idle:
            "Ouvir este trecho"
        case .generating:
            "Gerando narração"
        case .playing:
            "Pausar narração"
        case .paused:
            "Continuar narração"
        }
    }

    var systemImage: String {
        switch self {
        case .idle:
            "speaker.wave.2.fill"
        case .generating:
            "waveform"
        case .playing:
            "pause.circle.fill"
        case .paused:
            "play.circle.fill"
        }
    }

    var isHighlighted: Bool {
        self != .idle
    }
}

@MainActor
final class PassageNarrationService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isSpeaking = false
    @Published var isGenerating = false
    @Published var isPaused = false

    private let speechService = RemoteAISpeechService()
    private var player: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    private var activeSpeechText = ""
    private var queue: [String] = []
    private var currentSegmentIndex = 0
    private var pendingSegmentIndex: Int?
    private var prefetchedAudio: Data?
    private var prefetchedSegmentIndex: Int?

    func toggle(text: String) {
        toggle(segments: [text])
    }

    func toggle(segments: [String]) {
        let preparedSegments = preparedSegments(from: segments)
        let identifier = queueIdentifier(for: preparedSegments)
        if activeSpeechText == identifier, isSpeaking {
            pause()
        } else if activeSpeechText == identifier, isPaused {
            resume()
        } else if activeSpeechText == identifier, isGenerating {
            stop()
        } else {
            speak(preparedSegments)
        }
    }

    func state(for text: String) -> PassageNarrationButtonState {
        state(for: [text])
    }

    func state(for segments: [String]) -> PassageNarrationButtonState {
        guard activeSpeechText == queueIdentifier(for: preparedSegments(from: segments)) else { return .idle }
        if isGenerating { return .generating }
        if isSpeaking { return .playing }
        if isPaused { return .paused }
        return .idle
    }

    func pause() {
        guard isSpeaking else { return }
        if let player {
            player.pause()
        } else if pendingSegmentIndex != nil {
            playbackTask?.cancel()
            playbackTask = nil
        } else {
            return
        }
        isSpeaking = false
        isPaused = true
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func resume() {
        guard isPaused else { return }

        if let pendingSegmentIndex, player == nil {
            isPaused = false
            playPendingSegment(at: pendingSegmentIndex)
            return
        }

        guard let player else {
            finishQueue()
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            guard player.play() else {
                finishQueue()
                return
            }
            isPaused = false
            isSpeaking = true
        } catch {
            finishQueue()
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        prefetchTask?.cancel()
        prefetchTask = nil
        player?.stop()
        player = nil
        queue = []
        currentSegmentIndex = 0
        pendingSegmentIndex = nil
        prefetchedAudio = nil
        prefetchedSegmentIndex = nil
        activeSpeechText = ""
        isSpeaking = false
        isGenerating = false
        isPaused = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speak(_ segments: [String]) {
        stop()

        guard !segments.isEmpty else { return }
        queue = segments
        activeSpeechText = queueIdentifier(for: segments)
        currentSegmentIndex = 0
        isGenerating = true
        isSpeaking = false
        isPaused = false
        loadAndPlaySegment(at: 0)
    }

    private func loadAndPlaySegment(at index: Int) {
        guard queue.indices.contains(index) else {
            finishQueue()
            return
        }

        playbackTask?.cancel()
        let expectedIdentifier = activeSpeechText
        let segment = queue[index]
        isGenerating = true
        isSpeaking = false
        isPaused = false
        let service = speechService

        playbackTask = Task { [weak self] in
            do {
                let audio = try await service.audioData(for: segment)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard self?.activeSpeechText == expectedIdentifier else { return }
                    self?.play(audio, at: index)
                }
            } catch {
                await MainActor.run {
                    guard self?.activeSpeechText == expectedIdentifier else { return }
                    self?.finishQueue()
                }
            }
        }
    }

    private func play(_ data: Data, at index: Int) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            player = audioPlayer
            currentSegmentIndex = index
            pendingSegmentIndex = nil
            isGenerating = false
            isSpeaking = true
            isPaused = false
            audioPlayer.play()
            prefetchSegment(after: index)
        } catch {
            finishQueue()
        }
    }

    private func prefetchSegment(after index: Int) {
        let nextIndex = index + 1
        guard queue.indices.contains(nextIndex) else { return }

        prefetchTask?.cancel()
        let expectedIdentifier = activeSpeechText
        let segment = queue[nextIndex]
        let service = speechService
        prefetchTask = Task { [weak self] in
            do {
                let audio = try await service.audioData(for: segment)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard self?.activeSpeechText == expectedIdentifier else { return }
                    self?.prefetchedAudio = audio
                    self?.prefetchedSegmentIndex = nextIndex
                }
            } catch {
                // A troca de segmento ainda solicita o áudio normalmente.
            }
        }
    }

    private func continueQueue() {
        let nextIndex = currentSegmentIndex + 1
        guard queue.indices.contains(nextIndex) else {
            finishQueue()
            return
        }

        pendingSegmentIndex = nextIndex
        guard !isPaused else {
            isSpeaking = false
            return
        }

        let expectedIdentifier = activeSpeechText
        // Guardada em playbackTask: stop() precisa cancelá-la, senão um
        // reinício da mesma fila em menos de 600ms sobrepõe dois áudios.
        playbackTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.activeSpeechText == expectedIdentifier else { return }
                guard !self.isPaused, self.pendingSegmentIndex == nextIndex else { return }
                self.playPendingSegment(at: nextIndex)
            }
        }
    }

    private func playPendingSegment(at index: Int) {
        guard queue.indices.contains(index) else {
            finishQueue()
            return
        }

        pendingSegmentIndex = index
        if prefetchedSegmentIndex == index, let audio = prefetchedAudio {
            prefetchedAudio = nil
            prefetchedSegmentIndex = nil
            play(audio, at: index)
        } else {
            loadAndPlaySegment(at: index)
        }
    }

    private func preparedSegments(from segments: [String]) -> [String] {
        segments
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func queueIdentifier(for segments: [String]) -> String {
        segments.joined(separator: "\u{001F}")
    }

    private func finishQueue() {
        player?.stop()
        player = nil
        playbackTask?.cancel()
        playbackTask = nil
        prefetchTask?.cancel()
        prefetchTask = nil
        queue = []
        prefetchedAudio = nil
        prefetchedSegmentIndex = nil
        pendingSegmentIndex = nil
        activeSpeechText = ""
        isGenerating = false
        isSpeaking = false
        isPaused = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.player = nil
            if flag {
                self?.continueQueue()
            } else {
                self?.finishQueue()
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.finishQueue()
        }
    }

    deinit {
        playbackTask?.cancel()
        prefetchTask?.cancel()
        player?.stop()
        activeSpeechText = ""
    }
}
