@preconcurrency import AVFoundation
import FamilyControls
import ManagedSettings
import SwiftUI

struct EssentialModeIntroView: View {
    @Environment(SubscriptionManager.self) private var subscription
    let continueEssential: () -> Void

    var body: some View {
        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ConversionHeader(
                        eyebrow: "ATENÇÃO!",
                        title: "Seu acesso inicial terminou.",
                        subtitle: "Sua pausa diária continua funcionando, gratuita. Veja o que fica com você:"
                    )

                    VStack(spacing: 0) {
                        ConversionListRow(symbol: "checkmark", color: Color.sageButton, text: "Pausa diária e bloqueio dos seus apps")
                        Divider().overlay(Color.conversionDivider)
                        ConversionListRow(symbol: "checkmark", color: Color.sageButton, text: "3 trechos por leitura, com explicações essenciais")
                        Divider().overlay(Color.conversionDivider)
                        ConversionListRow(symbol: "checkmark", color: Color.sageButton, text: "Sua travessia de cada manhã, sempre gratuita")
                    }
                    .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))

                    Text("O Essencial exibe anúncios e não inclui narração, a reflexão completa nem personalização. Você pode voltar ao completo quando quiser.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(3)

                    Button("Entendi, continuar") {
                        continueEssential()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.deepInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))

                    NavigationLink {
                        PaywallView()
                    } label: {
                        Text("Quero o Limiar completo")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.sageButton)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.sageButton.opacity(0.75), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 52)
                .padding(.bottom, 30)
            }
        }
    }
}

struct FreeTrialStartView: View {
    @Environment(SubscriptionManager.self) private var subscription

    var body: some View {
        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Image("LimiarLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUA JORNADA COMEÇA")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.3)
                            .foregroundStyle(Color.warmGold)

                        Text("Comece com 7 dias de acesso completo")
                            .font(.system(size: 44, weight: .regular, design: .serif))
                            .foregroundStyle(Color.ivory)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Sete dias com tudo: leituras personalizadas, narração e reflexões. Sem pagamento, sem cartão — é só começar.")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.softText)
                            .lineSpacing(5)
                    }

                    VStack(alignment: .leading, spacing: 13) {
                        TrialDisclosureRow(icon: "calendar.badge.clock", text: "7 dias de acesso completo, grátis")
                        TrialDisclosureRow(icon: "checkmark.shield", text: "Nada é cobrado — nenhuma assinatura começa agora")
                        TrialDisclosureRow(icon: "leaf", text: "Depois, você escolhe: continuar completo ou seguir no Essencial gratuito")
                    }
                    .padding(16)
                    .limiarPanel()

                    Button {
                        subscription.startFreeTrial()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Começar minha travessia")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.sageButton, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.deepInk)
                    }

                    Text("Você não está assinando nada agora. Ao fim dos 7 dias, o Limiar mostra as opções e você decide.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.softText)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 30)
                .padding(.top, 58)
                .padding(.bottom, 30)
            }
        }
    }
}

struct TrialConversionView: View {
    @Environment(SubscriptionManager.self) private var subscription
    @Environment(LimiarAppModel.self) private var model
    let continueTrial: () -> Void

    var body: some View {
        @Bindable var subscription = subscription

        ZStack {
            LimiarBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ConversionHeader(
                        eyebrow: "ATENÇÃO!",
                        title: "Continue sem interrupção.",
                        subtitle: "Você não precisa perder nada do que construiu nestes 7 dias."
                    )

                    TrialRhythmPanel(readings: model.history.count)

                    ConversionLossBlock(
                        title: "Amanhã, sem o Premium, você perde:",
                        finalItem: "Pausa limpa — passará a ver anúncios"
                    )

                    ConversionTestimonials(startingIndex: 0)

                    ConversionPlanPicker(selection: $subscription.selectedPlan)

                    ConversionPurchaseSection(
                        buttonTitle: "Continuar minha travessia",
                        escapeTitle: "Decidir amanhã",
                        escapeAction: continueTrial
                    )
                }
                .padding(.horizontal, 30)
                .padding(.top, 52)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct TrialRhythmPanel: View {
    let readings: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.warmGold)
                .frame(width: 24)

            Text("7 dias, **\(readings) travessias**, **\(readings * 3) trechos**. Seu ritmo está no melhor momento.")
                .font(.system(size: 13))
                .foregroundStyle(Color.ivory)
                .lineSpacing(3)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.conversionPanel, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.conversionBorder, lineWidth: 1))
    }
}

struct TrialDisclosureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.warmGold)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.ivory)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TrialMetricsPanel: View {
    @Environment(LimiarAppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Seu progresso até aqui")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.ivory)

            TrialMetricRow(
                icon: "book.closed",
                value: "\(model.history.count)",
                label: model.history.count == 1 ? "leitura concluída" : "leituras concluídas"
            )
            TrialMetricRow(
                icon: "sunrise",
                value: model.estimatedFocusTimeText,
                label: model.history.count == 1 ? "travessia matinal" : "travessias matinais"
            )
            TrialMetricRow(
                icon: "lock.open",
                value: "\(model.history.count)",
                label: model.history.count == 1 ? "pausa consciente" : "pausas conscientes"
            )
        }
        .padding(16)
        .limiarPanel()
    }
}

struct TrialMetricRow: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.warmGold)
                .frame(width: 24)

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color.ivory)
                .frame(minWidth: 46, alignment: .leading)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.softText)
        }
    }
}
