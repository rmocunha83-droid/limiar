import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
final class ProfileImageStore {
    private(set) var image: UIImage?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let fileManager: FileManager
    private let defaults: UserDefaults
    private let storedFilenameKey = "limiar.profileImage.filename"
    private let imageFilename = "profile-avatar.jpg"

    init(
        fileManager: FileManager = .default,
        defaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.defaults = defaults
        loadStoredImage()
    }

    func importImage(from item: PhotosPickerItem) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let selectedImage = UIImage(data: data) else {
                throw ProfileImageError.invalidImage
            }

            let preparedImage = resizedImage(selectedImage, maximumDimension: 1_024)
            guard let compressedData = preparedImage.jpegData(compressionQuality: 0.82) else {
                throw ProfileImageError.encodingFailed
            }

            let directoryURL = try profileDirectoryURL()
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            )
            let fileURL = directoryURL.appendingPathComponent(imageFilename)
            try compressedData.write(to: fileURL, options: .atomic)
            try? (fileURL as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)

            defaults.set(imageFilename, forKey: storedFilenameKey)
            image = preparedImage
        } catch {
            errorMessage = "Não foi possível usar essa foto. Escolha outra imagem e tente novamente."
        }
    }

    func removeImage() {
        errorMessage = nil

        do {
            if let storedFilename = defaults.string(forKey: storedFilenameKey) {
                let fileURL = try profileDirectoryURL().appendingPathComponent(storedFilename)
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
            }
            defaults.removeObject(forKey: storedFilenameKey)
            image = nil
        } catch {
            errorMessage = "Não foi possível remover a foto agora. Tente novamente."
        }
    }

    private func loadStoredImage() {
        guard let storedFilename = defaults.string(forKey: storedFilenameKey),
              let directoryURL = try? profileDirectoryURL() else {
            return
        }

        let fileURL = directoryURL.appendingPathComponent(storedFilename)
        guard let storedImage = UIImage(contentsOfFile: fileURL.path) else {
            defaults.removeObject(forKey: storedFilenameKey)
            return
        }
        image = storedImage
    }

    private func profileDirectoryURL() throws -> URL {
        guard let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw ProfileImageError.missingApplicationSupportDirectory
        }
        return applicationSupportURL.appendingPathComponent("Profile", isDirectory: true)
    }

    private func resizedImage(_ source: UIImage, maximumDimension: CGFloat) -> UIImage {
        let longestSide = max(source.size.width, source.size.height)
        guard longestSide > maximumDimension else { return source }

        let scale = maximumDimension / longestSide
        let targetSize = CGSize(
            width: max(1, (source.size.width * scale).rounded()),
            height: max(1, (source.size.height * scale).rounded())
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            UIColor(red: 0.02, green: 0.04, blue: 0.045, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

private enum ProfileImageError: Error {
    case invalidImage
    case encodingFailed
    case missingApplicationSupportDirectory
}

struct ProfileAvatarView: View {
    let store: ProfileImageStore
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.deepInk.opacity(0.78))

            if let image = store.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if store.isLoading {
                ProgressView()
                    .tint(Color.sageButton)
            } else {
                Image(systemName: "person")
                    .font(.system(size: size * 0.38, weight: .medium))
                    .foregroundStyle(Color.aquaMist)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.sageButton.opacity(store.image == nil ? 0.34 : 0.72), lineWidth: size > 60 ? 2 : 1)
        )
        .contentShape(Circle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.image == nil ? "Perfil sem foto" : "Foto do perfil")
    }
}
