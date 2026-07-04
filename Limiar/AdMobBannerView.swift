import SwiftUI
import UIKit
@preconcurrency import GoogleMobileAds

enum LimiarAdMobConfiguration {
    static let appID = "ca-app-pub-7717198050770102~4802998011"

    #if DEBUG
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    static let bannerAdUnitID = "ca-app-pub-7717198050770102/8580637095"
    #endif
}

struct LimiarAdBannerSlot: View {
    var label = "Publicidade"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.softText.opacity(0.7))

            LimiarAdaptiveBannerView(adUnitID: LimiarAdMobConfiguration.bannerAdUnitID)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Publicidade")
    }
}

private struct LimiarAdaptiveBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: 320))
        banner.adUnitID = adUnitID
        banner.backgroundColor = .clear
        banner.rootViewController = UIApplication.shared.limiarRootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        let width = max(banner.bounds.width, UIScreen.main.bounds.width - 44)
        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
        banner.rootViewController = UIApplication.shared.limiarRootViewController
    }
}

private extension UIApplication {
    var limiarRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
