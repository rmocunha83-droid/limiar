@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct AIReadingPreparationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isBreathing = false

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

                    Text("Estamos preparando três novas reflexões bíblicas com explicações para este momento.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
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

struct SpiritualReadingCard: View {
    let item: SpiritualReadingItem
    let isSaved: Bool
    let saveAction: () -> Void
    let listenAction: () -> Void
    let narrationState: PassageNarrationButtonState
    var showsReflection = true
    var showsNarration = true
    var isSaveLocked = false

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
                            Image(systemName: narrationState.systemImage)
                        }

                        Text(narrationState.title)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(ReadingActionButtonStyle(isHighlighted: narrationState.isHighlighted))
            }
        }
        .padding(18)
        .limiarPanel()
    }
}

struct ReadingView: View {
    @Environment(LimiarAppModel.self) private var model
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.requestReview) private var requestReview
    @StateObject private var narration = PassageNarrationService()
    @State private var now = Date()
    @State private var showingPaywall = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var model = model

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text(model.currentReadingTitle)
                        .font(.system(size: 42, weight: .regular, design: .serif))
                        .foregroundStyle(Color.ivory)
                        .padding(.top, 18)

                    HStack {
                        Label(model.currentReadingReference, systemImage: "book.closed")
                        Spacer()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.warmGold)

                    readingActions

                    if model.isEssentialMode {
                        ForEach(Array(model.currentSpiritualReadingItems.enumerated()), id: \.element.id) { index, item in
                            SpiritualReadingCard(
                                item: item,
                                isSaved: model.isFavorite(item),
                                saveAction: {
                                    if subscription.canShowPaywall {
                                        showingPaywall = true
                                    }
                                },
                                listenAction: {
                                    if subscription.canShowPaywall {
                                        showingPaywall = true
                                    }
                                },
                                narrationState: .idle,
                                showsReflection: item.hasExplanationContent,
                                showsNarration: true,
                                isSaveLocked: true
                            )

                            LimiarAdBannerSlot(label: "Publicidade")
                        }
                    } else {
                        Text(model.currentReadingText)
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .foregroundStyle(Color.ivory)
                            .lineSpacing(8)
                            .padding(.vertical, 10)
                    }

                    if model.hasPremiumAccess {
                        aiStatusBanner
                        if model.hasVisibleReflection {
                            reflectionSection
                        }
                    } else if model.isEssentialMode {
                        if !model.currentReflection.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            essentialReflectionTeaser
                        }
                        essentialModeReadingNotice
                    }
                    readingGate
                    if model.hasPremiumAccess {
                        disclaimer
                    }
                    completionButton
                }
                .padding(22)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onReceive(timer) { date in
            now = date
            model.updateReadingProgress(at: date)
        }
        .onAppear {
            model.startReadingSession()
        }
        .onDisappear {
            narration.stop()
            model.endReadingSession()
        }
    }

    private var readingActions: some View {
        HStack(spacing: 12) {
            Button {
                if model.isEssentialMode && subscription.canShowPaywall {
                    showingPaywall = true
                } else {
                    model.toggleFavoriteCurrentPassage()
                }
            } label: {
                Label(model.isCurrentPassageFavorite ? "Salvo" : "Salvar", systemImage: model.isEssentialMode ? "lock.fill" : (model.isCurrentPassageFavorite ? "heart.fill" : "heart"))
                    .lineLimit(1)
            }
            .buttonStyle(ReadingActionButtonStyle(isHighlighted: model.isCurrentPassageFavorite))
        }
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Reflexão breve", systemImage: "sparkle")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color.warmGold)
                .padding(.top, 4)
            ReadingBlock(title: "Entenda o significado", text: model.currentReflection.summary)
            ReadingBlock(title: "Sentido espiritual", text: model.currentReflection.spiritualMeaning)
            ReadingBlock(title: "Para levar para o dia", text: model.currentReflection.practicalApplication)
            ReadingBlock(title: "Pergunta para refletir", text: model.currentReflection.meditationQuestion)
        }
    }

    private var essentialReflectionTeaser: some View {
        Button {
            if subscription.canShowPaywall { showingPaywall = true }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Label("Reflexão breve", systemImage: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color.warmGold)
                Text(model.currentReflection.summary)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ivory.opacity(0.58))
                    .lineLimit(1)
                    .blur(radius: 3)
                    .mask(LinearGradient(colors: [.black, .black.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .limiarPanel()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reflexão breve bloqueada. Abrir Limiar completo")
    }

    private var essentialModeReadingNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Modo Essencial", systemImage: "leaf.fill")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(Color.warmGold)

            Text("Você está lendo os trechos principais com explicações essenciais. Narração, maior variedade e experiência sem anúncios ficam no Limiar completo.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.softText)
                .lineSpacing(4)
        }
        .padding(14)
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.ivory.opacity(0.1), lineWidth: 1)
        )
    }

    private var aiStatusBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            if model.aiContentState == .generating {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color.warmGold)
                    .padding(.top, 2)
            } else {
                Image(systemName: model.aiContentState == .remoteReady ? "sparkles" : "sparkle.magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.warmGold)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(model.aiContentState.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.ivory)

                Text(model.aiContentState.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.softText)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.ivory.opacity(0.1), lineWidth: 1)
        )
    }

    private var readingGate: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.canCompleteReading ? "Leitura suficiente para continuar" : "Permaneça mais um pouco no trecho")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.ivory)

            Text(model.canCompleteReading ? "Você já pode concluir e retomar os apps selecionados." : "A barra avança enquanto você lê ou escuta. O objetivo é atravessar com calma.")
                .font(.system(size: 13))
                .foregroundStyle(Color.softText)
                .lineSpacing(4)
        }
        .padding(.top, 4)
    }

    private var disclaimer: some View {
        Text("As reflexões são preparadas para fins de meditação pessoal e não substituem orientação religiosa, pastoral ou rabínica.")
            .font(.system(size: 13))
            .foregroundStyle(Color.softText)
            .lineSpacing(4)
    }

    private var completionButton: some View {
        Button {
            model.finishReading()
            requestReviewIfEligibleAfterCompletion()
        } label: {
            Text(model.canCompleteReading ? "Concluir leitura" : "Siga no seu tempo")
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(model.canCompleteReading ? Color.aqua : Color.warmStone, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(model.canCompleteReading ? .black : Color.ivory.opacity(0.65))
        }
        .disabled(!model.canCompleteReading)
    }

    private func requestReviewIfEligibleAfterCompletion() {
        let history = model.history
        let readingWasHealthy = model.aiContentState != .fallback

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard subscription.claimReviewRequestIfEligible(
                history: history,
                readingWasHealthy: readingWasHealthy
            ) else {
                return
            }

            requestReview()
        }
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

    var title: String {
        switch self {
        case .idle:
            "Ouvir este trecho"
        case .generating:
            "Gerando narração"
        case .playing:
            "Parar narração"
        }
    }

    var systemImage: String {
        switch self {
        case .idle:
            "speaker.wave.2.fill"
        case .generating:
            "waveform"
        case .playing:
            "stop.circle.fill"
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

    private let speechService = RemoteAISpeechService()
    private var player: AVAudioPlayer?
    private var playbackTask: Task<Void, Never>?
    private var activeSpeechText = ""

    func toggle(text: String) {
        if (isSpeaking || isGenerating), activeSpeechText == preparedSpeechText(text) {
            stop()
        } else {
            speak(text)
        }
    }

    func state(for text: String) -> PassageNarrationButtonState {
        guard activeSpeechText == preparedSpeechText(text) else { return .idle }
        if isGenerating { return .generating }
        if isSpeaking { return .playing }
        return .idle
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        player?.stop()
        player = nil
        activeSpeechText = ""
        isSpeaking = false
        isGenerating = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func speak(_ text: String) {
        stop()

        let prepared = preparedSpeechText(text)
        guard !prepared.isEmpty else { return }
        activeSpeechText = prepared
        isGenerating = true
        isSpeaking = false
        let service = speechService

        playbackTask = Task { [weak self] in
            do {
                let audio = try await service.audioData(for: prepared)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.play(audio)
                }
            } catch {
                await MainActor.run {
                    self?.activeSpeechText = ""
                    self?.isGenerating = false
                    self?.isSpeaking = false
                }
            }
        }
    }

    private func play(_ data: Data) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)

            let audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            player = audioPlayer
            isGenerating = false
            isSpeaking = true
            audioPlayer.play()
        } catch {
            activeSpeechText = ""
            isGenerating = false
            isSpeaking = false
        }
    }

    private func preparedSpeechText(_ text: String) -> String {
        var prepared = text
            .replacingOccurrences(of: "APPs", with: "aplicativos")
            .replacingOccurrences(of: "apps", with: "aplicativos")
            .replacingOccurrences(of: " / ", with: ", ")
            .replacingOccurrences(of: "—", with: ", ")
            .replacingOccurrences(of: "–", with: ", ")
            .replacingOccurrences(of: "###", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "“", with: "")
            .replacingOccurrences(of: "”", with: "")

        prepared = prepared.replacingOccurrences(
            of: #"(?m)^\s*[-•]\s*"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"(?m)^\s*#{1,6}\s*"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #""[A-Za-z0-9_]+":\s*"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"\b[a-zA-Z]+_[a-zA-Z0-9_]+\b"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"(?m)^[ \t]+"#,
            with: "",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )
        prepared = prepared.replacingOccurrences(
            of: #"([.!?])\s+"#,
            with: "$1\n\n",
            options: .regularExpression
        )
        return prepared.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            self?.activeSpeechText = ""
            self?.isGenerating = false
            self?.isSpeaking = false
            self?.player = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.player = nil
            self?.activeSpeechText = ""
            self?.isGenerating = false
            self?.isSpeaking = false
        }
    }

    deinit {
        playbackTask?.cancel()
        player?.stop()
        activeSpeechText = ""
    }
}
