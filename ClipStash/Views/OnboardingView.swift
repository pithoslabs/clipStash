import AppKit
import SwiftUI

final class OnboardingWindowController: NSObject, NSWindowDelegate {
    static let shared = OnboardingWindowController()

    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    private var window: NSWindow?
    private var isCompleting = false
    private var titlebarTrackingArea: NSTrackingArea?
    var onFinish: (() -> Void)?

    private override init() {}

    var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: Self.hasCompletedOnboardingKey)
    }

    func showIfNeeded() {
        guard shouldShow else { return }
        show()
    }

    func show() {
        if window?.isVisible == true {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = OnboardingView(
            onQuit: {
                NSApp.terminate(nil)
            },
            onDone: { [weak self] in
                self?.complete()
            }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 806, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Welcome to ClipStash"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.minSize = NSSize(width: 806, height: 650)
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.delegate = self
        setWindowControlsVisible(false, for: window)
        installTitlebarTracking(on: window)

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func complete() {
        isCompleting = true
        UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)
        window?.close()
        onFinish?()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if isCompleting {
            return true
        }

        NSApp.terminate(nil)
        return false
    }

    private func setWindowControlsVisible(_ isVisible: Bool, for window: NSWindow? = nil) {
        let targetWindow = window ?? self.window
        [
            NSWindow.ButtonType.closeButton,
            .miniaturizeButton,
            .zoomButton
        ].forEach { buttonType in
            targetWindow?.standardWindowButton(buttonType)?.alphaValue = isVisible ? 1 : 0
        }
    }

    private func installTitlebarTracking(on window: NSWindow) {
        guard let contentView = window.contentView else { return }

        let titlebarHeight: CGFloat = 48
        let trackingRect = NSRect(
            x: 0,
            y: contentView.bounds.height - titlebarHeight,
            width: contentView.bounds.width,
            height: titlebarHeight
        )

        let trackingArea = NSTrackingArea(
            rect: trackingRect,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )

        contentView.addTrackingArea(trackingArea)
        titlebarTrackingArea = trackingArea
    }

    func mouseEntered(with event: NSEvent) {
        setWindowControlsVisible(true)
    }

    func mouseExited(with event: NSEvent) {
        setWindowControlsVisible(false)
    }
}

struct OnboardingView: View {
    let onQuit: () -> Void
    let onDone: () -> Void

    @State private var page = 0

    private let pageCount = 3
    private let background = Color(red: 253 / 255, green: 251 / 255, blue: 247 / 255)
    private let slateDeep = Color(red: 74 / 255, green: 85 / 255, blue: 104 / 255)
    private let slateMid = Color(red: 133 / 255, green: 146 / 255, blue: 158 / 255)
    private let gold = Color(red: 201 / 255, green: 168 / 255, blue: 97 / 255)

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            SoftPaperBackdrop()

            VStack(spacing: 0) {
                ZStack {
                    switch page {
                    case 0:
                        WelcomeOnboardingPage(
                            slateDeep: slateDeep,
                            slateMid: slateMid,
                            gold: gold
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    case 1:
                        HowItWorksOnboardingPage(
                            slateDeep: slateDeep,
                            slateMid: slateMid,
                            gold: gold
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    default:
                        PermissionsOnboardingPage(
                            slateDeep: slateDeep,
                            slateMid: slateMid,
                            gold: gold
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: page)

                HStack {
                    Button {
                        onQuit()
                    } label: {
                        Label("Quit", systemImage: "power")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 86, height: 34)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(slateMid)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.58))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.82), lineWidth: 1))
                    )

                    Spacer()

                    PageDots(page: page, count: pageCount, activeColor: slateDeep)

                    Spacer()

                    Button {
                        if page < pageCount - 1 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                page += 1
                            }
                        } else {
                            onDone()
                        }
                    } label: {
                        Text(page < pageCount - 1 ? "Continue" : "Done")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 96, height: 36)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(
                        Capsule()
                            .fill(slateDeep)
                            .shadow(color: slateDeep.opacity(0.22), radius: 14, x: 0, y: 8)
                    )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 46)
            }
        }
        .frame(width: 806, height: 650)
    }
}

private struct PermissionsOnboardingPage: View {
    let slateDeep: Color
    let slateMid: Color
    let gold: Color

    @State private var isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled
    private let permissionRefreshTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    private var titleText: String {
        isAccessibilityEnabled ? "You're all set" : "Grant permissions"
    }

    private var descriptionText: String {
        if isAccessibilityEnabled {
            return "Accessibility is enabled. ClipStash can now show your clipboard history when you press Command V."
        }

        return "Allow Accessibility so ClipStash can detect Command V and show your clipboard history."
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 52)

            VStack(spacing: 8) {
                Text(titleText)
                    .font(.system(size: 31, weight: .semibold, design: .rounded))
                    .foregroundStyle(slateDeep)
                    .animation(.easeInOut(duration: 0.18), value: isAccessibilityEnabled)

                Text(descriptionText)
                    .font(.system(size: 15))
                    .foregroundStyle(slateMid)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 560)
                    .animation(.easeInOut(duration: 0.18), value: isAccessibilityEnabled)
            }

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill((isAccessibilityEnabled ? Color(red: 72 / 255, green: 142 / 255, blue: 102 / 255) : gold).opacity(0.14))
                        .frame(width: 130, height: 130)

                    Image(systemName: isAccessibilityEnabled ? "checkmark.shield.fill" : "hand.raised.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isAccessibilityEnabled ? Color(red: 72 / 255, green: 142 / 255, blue: 102 / 255) : gold)
                }

                PermissionStatusRow(
                    title: "Accessibility",
                    subtitle: isAccessibilityEnabled ? "Permission granted" : "Required for the Command V shortcut",
                    isGranted: isAccessibilityEnabled,
                    slateDeep: slateDeep,
                    slateMid: slateMid,
                    gold: gold
                )
                .frame(width: 470)

                Button {
                    AccessibilityHelper.requestPermission()
                    AccessibilityHelper.openAccessibilitySettings()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled
                    }
                } label: {
                    Label(
                        isAccessibilityEnabled ? "Permission Granted" : "Grant Permission",
                        systemImage: isAccessibilityEnabled ? "checkmark.circle.fill" : "lock.open.fill"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 178, height: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isAccessibilityEnabled ? slateDeep : .white)
                .background(
                    Capsule()
                        .fill(isAccessibilityEnabled ? Color.white.opacity(0.82) : slateDeep)
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.88), lineWidth: 1))
                        .shadow(color: slateDeep.opacity(0.16), radius: 14, x: 0, y: 8)
                )
                .disabled(isAccessibilityEnabled)
            }
            .padding(32)
            .background(OnboardingPanelBackground(cornerRadius: 24))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: slateDeep.opacity(0.12), radius: 24, x: 0, y: 14)

            Spacer(minLength: 52)
        }
        .padding(.horizontal, 64)
        .onAppear {
            isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled
        }
        .onReceive(permissionRefreshTimer) { _ in
            isAccessibilityEnabled = AccessibilityHelper.isAccessibilityEnabled
        }
    }
}

private struct PermissionStatusRow: View {
    let title: String
    let subtitle: String
    let isGranted: Bool
    let slateDeep: Color
    let slateMid: Color
    let gold: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isGranted ? Color(red: 72 / 255, green: 142 / 255, blue: 102 / 255) : gold)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(slateDeep)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(slateMid)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 247 / 255, green: 243 / 255, blue: 235 / 255).opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.86), lineWidth: 1)
                )
        )
    }
}

private struct WelcomeOnboardingPage: View {
    let slateDeep: Color
    let slateMid: Color
    let gold: Color

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 30)

            ZStack {
                Circle()
                    .fill(gold.opacity(0.2))
                    .frame(width: 240, height: 240)
                    .blur(radius: 34)

                Circle()
                    .fill(Color(red: 106 / 255, green: 145 / 255, blue: 199 / 255).opacity(0.14))
                    .frame(width: 150, height: 150)
                    .offset(x: -42, y: 22)
                    .blur(radius: 22)

                Circle()
                    .fill(Color(red: 218 / 255, green: 122 / 255, blue: 82 / 255).opacity(0.12))
                    .frame(width: 150, height: 150)
                    .offset(x: 42, y: -18)
                    .blur(radius: 24)

                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .saturation(1.35)
                    .contrast(1.08)
                    .frame(width: 138, height: 138)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.72), lineWidth: 1)
                    )
                    .shadow(color: gold.opacity(0.28), radius: 34, x: 0, y: 12)
                    .shadow(color: slateDeep.opacity(0.2), radius: 28, x: 0, y: 20)
                    .offset(y: isHovering ? -8 : 6)
                    .rotationEffect(.degrees(isHovering ? -2.5 : 2.5))
            }
            .frame(height: 210)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                    isHovering = true
                }
            }

            VStack(spacing: 10) {
                Text("Welcome to ClipStash")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(slateDeep)

                Text("Your clipboard, remembered.")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(slateDeep.opacity(0.82))

                Text("Never lose a copied item again. ClipStash keeps your clipboard history at your fingertips - beautiful, fast, and private.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(slateMid)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 420)
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 48)
    }
}

private struct HowItWorksOnboardingPage: View {
    let slateDeep: Color
    let slateMid: Color
    let gold: Color

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 34)

            VStack(spacing: 8) {
                Text("Paste from history")
                    .font(.system(size: 31, weight: .semibold, design: .rounded))
                    .foregroundStyle(slateDeep)

                Text("Use the menu bar icon, or press Command V to bring up your saved clips.")
                    .font(.system(size: 15))
                    .foregroundStyle(slateMid)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 390)
            }

            HStack(alignment: .center, spacing: 18) {
                MenuBarIconPlaceholder(slateDeep: slateDeep, slateMid: slateMid, gold: gold)
                    .frame(width: 190, height: 230)

                CommandVPreviewPlaceholder(slateDeep: slateDeep, slateMid: slateMid, gold: gold)
                    .frame(width: 300, height: 230)
            }

            Spacer(minLength: 42)
        }
        .padding(.horizontal, 38)
    }
}

private struct MenuBarIconPlaceholder: View {
    let slateDeep: Color
    let slateMid: Color
    let gold: Color

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 9) {
                Circle().fill(Color(red: 215 / 255, green: 226 / 255, blue: 222 / 255)).frame(width: 8, height: 8)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(slateMid.opacity(0.18))
                    .frame(width: 48, height: 6)
                Spacer()
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(slateDeep)
                    .padding(7)
                    .background(Capsule().fill(Color.white.opacity(0.92)))
            }
            .padding(.horizontal, 13)
            .frame(height: 34)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.76))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.9), lineWidth: 0.8))
            )

            VStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 25, weight: .regular))
                    .foregroundStyle(gold)

                Text("Menu bar icon")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(slateDeep)

                Text("Open ClipStash from the top bar")
                    .font(.system(size: 11))
                    .foregroundStyle(slateMid)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 247 / 255, green: 243 / 255, blue: 235 / 255).opacity(0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.92), lineWidth: 1)
                    )
            )
        }
        .padding(12)
        .background(OnboardingPanelBackground(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: slateDeep.opacity(0.12), radius: 24, x: 0, y: 14)
    }
}

private struct CommandVPreviewPlaceholder: View {
    let slateDeep: Color
    let slateMid: Color
    let gold: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(slateMid)
                Text("Search clipboard...")
                    .font(.system(size: 13))
                    .foregroundStyle(slateMid.opacity(0.82))
                Spacer()
                Keycap("⌘", slateDeep: slateDeep)
                Keycap("V", slateDeep: slateDeep)
            }
            .padding(.horizontal, 14)
            .frame(height: 45)

            Divider().opacity(0.28)

            VStack(spacing: 7) {
                PreviewRow(icon: "doc.text", title: "Project brief", isSelected: true, slateDeep: slateDeep, slateMid: slateMid, gold: gold)
                PreviewRow(icon: "link", title: "https://clipstash.app", isSelected: false, slateDeep: slateDeep, slateMid: slateMid, gold: gold)
                PreviewRow(icon: "text.quote", title: "Never lose a copied item again", isSelected: false, slateDeep: slateDeep, slateMid: slateMid, gold: gold)
            }
            .padding(10)

            Spacer(minLength: 0)

            HStack {
                Label("Paste", systemImage: "return")
                Spacer()
                Label("Cancel", systemImage: "escape")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(slateMid.opacity(0.8))
            .padding(.horizontal, 14)
            .frame(height: 34)
        }
        .background(OnboardingPanelBackground(cornerRadius: 22))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: slateDeep.opacity(0.16), radius: 26, x: 0, y: 16)
    }
}

private struct PreviewRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let slateDeep: Color
    let slateMid: Color
    let gold: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? slateDeep : slateMid)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? slateDeep : slateMid)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? gold.opacity(0.2) : Color.white.opacity(0.58))
        )
    }
}

private struct Keycap: View {
    let value: String
    let slateDeep: Color

    init(_ value: String, slateDeep: Color) {
        self.value = value
        self.slateDeep = slateDeep
    }

    var body: some View {
        Text(value)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(slateDeep)
            .frame(minWidth: 24, minHeight: 24)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
            )
    }
}

private struct PageDots: View {
    let page: Int
    let count: Int
    let activeColor: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? activeColor : activeColor.opacity(0.2))
                    .frame(width: index == page ? 18 : 7, height: 7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: page)
            }
        }
    }
}

private struct SoftPaperBackdrop: View {
    var body: some View {
        ZStack {
            PaperShape(color: Color(red: 212 / 255, green: 233 / 255, blue: 226 / 255), rotation: -10)
                .frame(width: 94, height: 124)
                .offset(x: -230, y: -118)

            PaperShape(color: Color(red: 245 / 255, green: 213 / 255, blue: 200 / 255), rotation: 8)
                .frame(width: 82, height: 108)
                .offset(x: 240, y: 120)

            PaperShape(color: Color(red: 228 / 255, green: 220 / 255, blue: 240 / 255), rotation: -6)
                .frame(width: 68, height: 92)
                .offset(x: 235, y: -120)
        }
        .opacity(0.55)
    }
}

private struct PaperShape: View {
    let color: Color
    let rotation: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(color)
            .rotationEffect(.degrees(rotation))
            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 8)
    }
}

private struct OnboardingPanelBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.78))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.88), lineWidth: 1)
            )
    }
}
