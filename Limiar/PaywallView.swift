import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    var continueEssential: (() -> Void)? = nil

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://limiar-five.vercel.app/privacy.html")!

    var body: some View {
        @Bindable var subscription = subscription

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ConversionHeader(
                        eyebrow: "LIMIAR PREMIUM",
                        title: "Ontem, sua travessia ficou menor.",
                        subtitle: "Sua pausa continua — mas desde ontem ela vem sem a parte que fazia a diferença."
                    )

                    ConversionContrastLine(text: "Você continua com a pausa, o bloqueio e os 3 trechos.")

                    ConversionLossBlock(
                        title: "Desde ontem, você está sem:",
                        finalItem: "Pausa limpa — anúncios nos trechos e no dashboard"
                    )

                    ConversionTestimonials(startingIndex: 1)

                    ConversionPlanPicker(selection: $subscription.selectedPlan)

                    ConversionPurchaseSection(
                        buttonTitle: "Voltar ao Limiar completo",
                        escapeTitle: "Continuar no Essencial",
                        escapeAction: {
                            if let continueEssential {
                                continueEssential()
                            } else {
                                dismiss()
                            }
                        }
                    )

                    ConversionLegalLinks(termsURL: termsURL, privacyURL: privacyURL)
                }
                .padding(.horizontal, 30)
                .padding(.top, 52)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .task { subscription.start() }
    }
}

struct ConversionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color.warmGold)

            Text(title)
                .font(.system(size: 27, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(Color.softText)
                .lineSpacing(4)
        }
    }
}

struct ConversionContrastLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.sageButton)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.softText)
        }
    }
}

struct ConversionLossBlock: View {
    let title: String
    let finalItem: String

    private var items: [String] {
        [
            "Reflexão completa: significado, aplicação e pergunta",
            "Narração com voz natural",
            "Tradição, profundidade e livros do seu jeito",
            "Histórico e lista de trechos salvos",
            finalItem
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ivory)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    ConversionListRow(symbol: "xmark", color: Color.conversionCoral, text: item)
                    if index < items.count - 1 {
                        Divider().overlay(Color.conversionDivider)
                    }
                }
            }
            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
        }
    }
}

struct ConversionListRow: View {
    let symbol: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color(red: 0.79, green: 0.81, blue: 0.79))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

struct ConversionTestimonials: View {
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    struct Testimonial: Identifiable {
        let id: Int
        let quote: String
        let name: String
    }

    private static let placeholders = [
        Testimonial(id: 0, quote: "Eu abria o Instagram antes mesmo de levantar da cama. Agora a primeira coisa que leio todo dia é a Palavra. Mudou minhas manhãs.", name: "Mariana S."),
        Testimonial(id: 1, quote: "Voltei a ler a Bíblia todos os dias depois de anos tentando criar o hábito. O ‘Entenda o significado’ faz o texto conversar comigo.", name: "Carlos E."),
        Testimonial(id: 2, quote: "As distrações diminuíram muito. O bloqueio me dá aquele segundo de consciência antes de cair no automático.", name: "Patrícia R."),
        Testimonial(id: 3, quote: "Faço a travessia no café da manhã ouvindo os trechos. A narração parece alguém lendo para mim, com calma.", name: "João P."),
        Testimonial(id: 4, quote: "Cada dia vem um trecho diferente, nos temas que eu escolhi. Sinto que o app respeita a minha fé.", name: "Ana L.")
    ]

    @State private var selectedIndex: Int

    init(startingIndex: Int = 0) {
        _selectedIndex = State(initialValue: startingIndex)
    }

    var body: some View {
        VStack(spacing: 10) {
            TabView(selection: $selectedIndex) {
                ForEach(Self.placeholders) { testimonial in
                    TestimonialCard(testimonial: testimonial)
                        .tag(testimonial.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 176)

            HStack(spacing: 7) {
                ForEach(Self.placeholders) { testimonial in
                    Capsule()
                        .fill(testimonial.id == selectedIndex ? Color.sageButton : Color(red: 0.23, green: 0.28, blue: 0.26))
                        .frame(width: testimonial.id == selectedIndex ? 16 : 5, height: 5)
                        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                }
            }
        }
        .task(id: selectedIndex) {
            guard !voiceOverEnabled else { return }
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                selectedIndex = (selectedIndex + 1) % Self.placeholders.count
            }
        }
    }
}

private struct TestimonialCard: View {
    let testimonial: ConversionTestimonials.Testimonial

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("★★★★★")
                .font(.system(size: 15, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color(red: 0.89, green: 0.70, blue: 0.30))

            Text("“\(testimonial.quote)”")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.ivory)
                .lineSpacing(3)
                .lineLimit(5)

            Spacer(minLength: 0)

            Text(testimonial.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.softText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(19)
        .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
        .padding(.horizontal, 1)
    }
}

struct ConversionPlanPicker: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Binding var selection: SubscriptionPlan

    var body: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionPlan.allCases.sorted { $0.sortOrder < $1.sortOrder }) { plan in
                Button {
                    selection = plan
                } label: {
                    VStack(alignment: .leading, spacing: 7) {
                        if plan == .yearly {
                            Text("MAIS ESCOLHIDO")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.deepInk)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.sageButton, in: Capsule())
                        }

                        HStack {
                            Image(systemName: selection == plan ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selection == plan ? Color.sageButton : Color.softText)
                            Text(plan.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.ivory)
                            Spacer()
                            Text(mainPrice(for: plan))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.ivory)
                        }

                        Text(detail(for: plan))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.softText)
                            .padding(.leading, 31)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(selection == plan ? Color(red: 0.086, green: 0.13, blue: 0.12) : Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(selection == plan ? Color.sageButton : Color.conversionBorder, lineWidth: selection == plan ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func mainPrice(for plan: SubscriptionPlan) -> String {
        if plan == .yearly, let monthly = subscription.monthlyEquivalentPrice(for: plan) {
            return "\(monthly)/mês"
        }
        return subscription.displayPrice(for: plan)
    }

    private func detail(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .yearly:
            return "\(subscription.displayPrice(for: plan)) por ano · menos de R$ 0,25 por dia"
        case .monthly:
            return "Renovação mensal · cancele quando quiser"
        }
    }
}

struct ConversionPurchaseSection: View {
    @Environment(SubscriptionManager.self) private var subscription
    let buttonTitle: String
    let escapeTitle: String
    var escapeAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Button {
                Task { await subscription.purchaseSelectedPlan() }
            } label: {
                HStack(spacing: 10) {
                    if subscription.state == .purchasing {
                        ProgressView().tint(Color.deepInk)
                    }
                    Text(buttonTitle)
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.deepInk)
            }
            .disabled(!subscription.canPurchase(subscription.selectedPlan))
            .opacity(subscription.canPurchase(subscription.selectedPlan) ? 1 : 0.62)

            Button(escapeTitle) { escapeAction?() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.softText)
                .frame(maxWidth: .infinity)

            Text("Cancele quando quiser · A App Store confirma antes de cobrar")
                .font(.system(size: 11))
                .foregroundStyle(Color.softText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(subscription.renewalDisclosure(for: subscription.selectedPlan))
                .font(.system(size: 11))
                .foregroundStyle(Color.softText.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !subscription.statusText.isEmpty {
                Text(subscription.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.softText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct ConversionLegalLinks: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(\.openURL) private var openURL
    let termsURL: URL
    let privacyURL: URL

    var body: some View {
        VStack(spacing: 12) {
            Button {
                Task { await subscription.restorePurchases() }
            } label: {
                Label("Restaurar compra", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
            }
            .disabled(subscription.isBusy)

            HStack(spacing: 18) {
                Button("Termos de Uso") { openURL(termsURL) }
                Button("Política de Privacidade") { openURL(privacyURL) }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.sageButton)
            .frame(maxWidth: .infinity)
        }
    }
}

extension Color {
    static let conversionPanel = Color(red: 0.067, green: 0.106, blue: 0.11)
    static let conversionBorder = Color(red: 0.141, green: 0.192, blue: 0.184)
    static let conversionDivider = Color(red: 0.114, green: 0.157, blue: 0.153)
    static let conversionCoral = Color(red: 0.847, green: 0.541, blue: 0.478)
}

#Preview {
    PaywallView()
        .environment(LimiarAppModel())
        .environment(SubscriptionManager())
}
