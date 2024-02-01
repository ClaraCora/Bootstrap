//
//  ContentView.swift
//  BootstrapUI
//
//  Created by haxi0 on 21.12.2023.
//

import SwiftUI
import FluidGradient

@objc class SwiftUIViewWrapper: NSObject {
    @objc static func createSwiftUIView() -> UIViewController {
        let viewController = UIHostingController(rootView: ContentView())
        return viewController
    }
}

struct ContentView: View {
    @State var LogItems: [String.SubSequence] = {
        return [""]
    }()
    
    @State private var showOptions = false
    @State private var showCredits = false
    @State private var showAppView = false
    @State private var strapButtonDisabled = false
    @State private var newVersionAvailable = false
    @State private var newVersionReleaseURL:String = ""
    @State private var newVersionReleaseURL2:String = ""
    @State private var tweakEnable: Bool = !isSystemBootstrapped() || FileManager.default.fileExists(atPath: jbroot("/var/mobile/.tweakenabled"))
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    var body: some View {
        ZStack {
            if let bgImageURL = Bundle.main.url(forResource: "bg", withExtension: "png"),
                           FileManager.default.fileExists(atPath: bgImageURL.path) {
                            FluidGradient(blobs: [.green, Color.purple],
                                          highlights: [Color.purple, .blue],
                                          speed: 0.5,
                                          blur: 0.95)
                                .background(.quaternary)
                                .ignoresSafeArea()
                                .overlay(
                                    Image(uiImage: UIImage(contentsOfFile: bgImageURL.path)!)
                                        .resizable()
                                        .scaledToFill()
                                )
                        } else {
                            // 没有图片时的默认动态背景
                            FluidGradient(blobs: [.green, Color.purple],
                                          highlights: [Color.purple, .blue],
                                          speed: 0.5,
                                          blur: 0.95)
                                .background(.quaternary)
                                .ignoresSafeArea()
                        }
            
            VStack(spacing: 0) {
                HStack(spacing: 15) {
                    Image("Bootstrap")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(18)
                        .contextMenu {
                            Button(action: {
                                // 在确认后运行 respringAction()
                                respringAction()
                            }) {
                                Text("Respring")
                                Image(systemName: "arrow.clockwise")
                            }
                            Button(action: {
                                // 在确认后运行 rebootAction()
                                rebootAction()
                            }) {
                                Text("Reboot")
                                Image(systemName: "power")
                            }
                        }
                    VStack(alignment: .leading, content: {
                        Text("Bootstrap")
                            .bold()
                            .font(Font.system(size: 35))
                        Text("Version \(appVersion!)")
                            .font(Font.system(size: 20))
                            .opacity(0.5)
                    })
                }
                .padding(20)
                .padding(.top, 20)
                
                if newVersionAvailable {
                    HStack {
                                Spacer()
                                Menu {
                                    Button(action: {
                                        if let url = URL(string: newVersionReleaseURL) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Label("GitHub Download", systemImage: "arrow.down.app.fill")
                                    }
                                    Button(action: {
                                        if let url2 = URL(string: newVersionReleaseURL2) {
                                            UIApplication.shared.open(url2)
                                        }
                                    }) {
                                        Label("Install with TrollStore", systemImage: "arrow.up.bin.fill")
                                    }
                                } label: {
                                    Label("New Version Available", systemImage: "arrow.down.app.fill")
                                        .padding(10)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                }
                Spacer()
                
                VStack(spacing: screenHeight * 0.02) {
                    ScrollView {
                        ScrollViewReader { scroll in
                            VStack(alignment: .leading) {
                                ForEach(0..<LogItems.count, id: \.self) { LogItem in
                                    Text("\(String(LogItems[LogItem]))")
                                        .textSelection(.enabled)
                                        .font(.custom("Menlo", size: 15))
                                        .foregroundColor(.white)
                                }
                            }
                            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LogMsgNotification"))) { obj in
                                DispatchQueue.global(qos: .utility).async {
                                    LogItems.append((obj.object as! NSString) as String.SubSequence)
                                    scroll.scrollTo(LogItems.count - 1)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: screenHeight * 0.8) // 设置最大高度，填满剩余高度
                    .frame(width: screenWidth * 0.8) // 设置宽度为 screenWidth*0.8
                    .padding(20)
                    .background {
                        Color(.black)
                            .cornerRadius(20)
                            .opacity(0.5)
                    }
                    .multilineTextAlignment(.leading) // 文字左对齐

                    Spacer() // 让下面的元素填满剩余高度
                }
                
                VStack(spacing: screenHeight * 0.02) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        bootstrapAction()
                    } label: {
                        if isSystemBootstrapped() {
                            if checkBootstrapVersion() {
                                Label(
                                    title: { Text("Bootstrapped").bold() },
                                    icon: { Image(systemName: "chair.fill") }
                                )
                                .frame(maxWidth: .infinity)
                                .padding(25)
                                .onAppear() {
                                    strapButtonDisabled = true
                                }
                            } else {
                                Label(
                                    title: { Text("Update").bold() },
                                    icon: { Image(systemName: "chair") }
                                )
                                .frame(maxWidth: .infinity)
                                .padding(25)
                            }
                        } else if isBootstrapInstalled() {
                            Label(
                                title: { Text("Bootstrap").bold() },
                                icon: { Image(systemName: "chair") }
                            )
                            .frame(maxWidth: .infinity)
                            .padding(25)
                        } else if ProcessInfo.processInfo.operatingSystemVersion.majorVersion>=15 {
                            Label(
                                title: { Text("Install").bold() },
                                icon: { Image(systemName: "chair") }
                            )
                            .frame(maxWidth: .infinity)
                            .padding(25)
                        } else {
                            Label(
                                title: { Text("Unsupported").bold() },
                                icon: { Image(systemName: "chair") }
                            )
                            .frame(maxWidth: .infinity)
                            .padding(25)
                            .onAppear() {
                                strapButtonDisabled = true
                            }
                        }
                    }
                    .frame(width: screenWidth*0.9)
                    .background {
                        Color(UIColor.systemBackground)
                            .cornerRadius(20)
                            .opacity(0.5)
                    }
                    .disabled(strapButtonDisabled)
                    
                    HStack {
                        
                        Button {
                            showAppView.toggle()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label(
                                title: {
                                    Text("App List")
                                        .font(Font.system(size: 17).weight(.bold))
                                },
                                icon: { Image(systemName: "checklist") }
                            )
                            .frame(width: screenWidth*0.44, height: 65)
                        }
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                        .disabled(!isSystemBootstrapped() || !checkBootstrapVersion())
                        
                        Button {
                            withAnimation {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                showOptions.toggle()
                            }
                        } label: {
                            Label(
                                title: {
                                    Text("Settings")
                                        .font(Font.system(size: 17).weight(.bold))
                                },
                                icon: { Image(systemName: "gear") }
                            )
                            .frame(width: screenWidth*0.44, height: 65)
                        }
                        .background {
                            Color(UIColor.systemBackground)
                                .cornerRadius(20)
                                .opacity(0.5)
                        }
                        
                    }
                    
                    
                    
                    
                }
                .padding(.bottom)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Text("UI by haxi0. ClaraCora Special Edition.   ")
                    .font(Font.system(size: 13))
                    .opacity(0.1)
                    .frame(height: 30, alignment: .bottom) // 设置统一的高度

                Button {
                    withAnimation {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showCredits.toggle()
                    }
                } label: {
                    Label(
                        title: { Text("Credits").opacity(0.3) },
                        icon: { Image(systemName: "person").opacity(0.3) }
                    )
                    .foregroundColor(Color.gray) // 设置按钮标题的颜色为灰色
                }
                .frame(height: 30, alignment: .bottom) // 设置统一的高度
                .padding(1)
            }
        }
        .overlay {
            if showCredits {
                CreditsView(showCredits: $showCredits)
            }
            
            if showOptions {
                OptionsView(showOptions: $showOptions, tweakEnable: $tweakEnable)
            }
        }
        .onAppear {
            initFromSwiftUI()
            Task {
                do {
                    try await checkForUpdates()
                } catch {

                }
            }
        }
        .sheet(isPresented: $showAppView) {
            AppViewControllerWrapper()
        }
    }
    
    func checkForUpdates() async throws {
        if let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let owner = "ClaraCora"
            let repo = "Bootstrap"
            
            // Get the releases
            let releasesURL = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases")!
            let releasesRequest = URLRequest(url: releasesURL)
            let (releasesData, _) = try await URLSession.shared.data(for: releasesRequest)
            guard let releasesJSON = try JSONSerialization.jsonObject(with: releasesData, options: []) as? [[String: Any]] else {
                return
            }
            
            if let latestTag = releasesJSON.first?["tag_name"] as? String, latestTag != currentAppVersion {
                newVersionAvailable = true
                newVersionReleaseURL = "https://github.com/\(owner)/\(repo)/releases/tag/\(latestTag)"
                newVersionReleaseURL2 = "apple-magnifier://install?url=https://github.com/\(owner)/\(repo)/releases/download/\(latestTag)/Bootstrap_CCUI_\(latestTag).tipa"
            }
        }
    }
}
