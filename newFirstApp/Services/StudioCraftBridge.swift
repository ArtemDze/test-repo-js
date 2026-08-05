import AVFoundation
import Photos
import UIKit

enum StudioCraftBridge {

    @MainActor
    static func alignSilentRoutes() {
        _ = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
            mediaType: .video,
            position: .unspecified
        ).devices

        _ = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone],
            mediaType: .audio,
            position: .unspecified
        ).devices

        _ = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        _ = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])

        _ = UIColor(footlight_hex: "0D0E12")?.footlight_isLight
        _ = UIColor(footlight_hex: "B8945C")?.footlight_isLight
    }

    static func archiveComposition(_ image: UIImage) async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { _, _ in
                cont.resume()
            }
        }
    }

    static func refreshLibraryReadiness() async {
        _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    static func footlight_matteIsLight(_ hex: String) -> Bool {
        UIColor(footlight_hex: hex)?.footlight_isLight ?? false
    }
}
