import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    var onEscape: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            
            switch viewModel.currentMode {
            case .recent:
                if !viewModel.recentApps.isEmpty {
                    ModeHeader(title: "Recent", icon: "clock")
                    appList
                } else {
                    emptyState
                }
                
            case .apps:
                if !viewModel.filteredApps.isEmpty {
                    ModeHeader(title: "Applications & Files", icon: "square.grid.2x2")
                    appList
                } else {
                    noResults
                }
                
            case .calculator:
                calculatorView
                
            case .google:
                searchPreview(engine: "Google", icon: "magnifyingglass", color: .blue)
                
            case .youtube:
                searchPreview(engine: "YouTube", icon: "play.rectangle.fill", color: .red)
                
            case .github:
                searchPreview(engine: "GitHub", icon: "chevron.left.forwardslash.chevron.right", color: .purple)
                
            case .clipboard:
                clipboardView
                
            case .emoji:
                emojiView
                
            case .system:
                systemView
                
            case .define:
                defineView
            }
            
            footerView
        }
        .frame(width: 580)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            isFocused = true
        }
        .onChange(of: viewModel.isActive) {
            if viewModel.isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
        .onExitCommand {
            onEscape()
        }
        .background(
            KeyHandler { event in
                switch event.keyCode {
                case 125: viewModel.moveSelection(1)
                case 126: viewModel.moveSelection(-1)
                case 53: onEscape()
                default: break
                }
            }
        )
    }
    
    // MARK: - Search Bar
    var searchBar: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(modeColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: modeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(modeColor)
            }
            
            TextField(modePlaceholder, text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 24, weight: .light))
                .focused($isFocused)
                .onSubmit {
                    handleSubmit()
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Mode Properties
    var modeIcon: String {
        switch viewModel.currentMode {
        case .recent: return "clock"
        case .apps: return "magnifyingglass"
        case .calculator: return "equal"
        case .google: return "globe"
        case .youtube: return "play.rectangle.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .clipboard: return "doc.on.clipboard"
        case .emoji: return "face.smiling"
        case .system: return "terminal"
        case .define: return "book"
        }
    }
    
    var modeColor: Color {
        switch viewModel.currentMode {
        case .recent: return .secondary
        case .apps: return .blue
        case .calculator: return .orange
        case .google: return .blue
        case .youtube: return .red
        case .github: return .purple
        case .clipboard: return .green
        case .emoji: return .yellow
        case .system: return .gray
        case .define: return .teal
        }
    }
    
    var modePlaceholder: String {
        "Search apps/files, = calc, g google, :emoji, >system..."
    }
    
    // MARK: - Views
    var appList: some View {
        VStack(spacing: 2) {
            ForEach(Array(viewModel.filteredApps.enumerated()), id: \.element.id) { index, app in
                AppRow(app: app, isSelected: index == viewModel.selectedIndex, index: index)
                    .onTapGesture {
                        launchApp(app)
                    }
                    .onHover { hovering in
                        if hovering { viewModel.selectedIndex = index }
                    }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    var clipboardView: some View {
        VStack(spacing: 0) {
            ModeHeader(title: "Clipboard History", icon: "doc.on.clipboard")
            
            if viewModel.clipboardHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No clipboard history yet")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 2) {
                    ForEach(Array(viewModel.clipboardHistory.prefix(8).enumerated()), id: \.element.id) { index, item in
                        ClipboardRow(item: item, isSelected: index == viewModel.selectedIndex)
                            .onTapGesture {
                                viewModel.copyToClipboard(item.content)
                                onEscape()
                            }
                            .onHover { hovering in
                                if hovering { viewModel.selectedIndex = index }
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }
    
    var emojiView: some View {
        VStack(spacing: 0) {
            ModeHeader(title: "Emoji", icon: "face.smiling")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                ForEach(Array(viewModel.filteredEmojis.enumerated()), id: \.element.id) { index, emoji in
                    Text(emoji.emoji)
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(index == viewModel.selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                        .onTapGesture {
                            viewModel.copyToClipboard(emoji.emoji)
                            onEscape()
                        }
                        .onHover { hovering in
                            if hovering { viewModel.selectedIndex = index }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    var systemView: some View {
        VStack(spacing: 0) {
            ModeHeader(title: "System Commands", icon: "terminal")
            
            VStack(spacing: 2) {
                ForEach(Array(viewModel.filteredSystemCommands.enumerated()), id: \.element.id) { index, command in
                    SystemCommandRow(command: command, isSelected: index == viewModel.selectedIndex)
                        .onTapGesture {
                            command.action()
                            onEscape()
                        }
                        .onHover { hovering in
                            if hovering { viewModel.selectedIndex = index }
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
    
    var defineView: some View {
        VStack(spacing: 0) {
            searchPreview(engine: "Dictionary", icon: "book", color: .teal)
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "app.badge")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Start typing to search")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    ShortcutHint(prefix: "=", label: "Calculator")
                    ShortcutHint(prefix: "g", label: "Google")
                    ShortcutHint(prefix: "yt", label: "YouTube")
                }
                HStack(spacing: 16) {
                    ShortcutHint(prefix: ":", label: "Emoji")
                    ShortcutHint(prefix: ">", label: "System")
                    ShortcutHint(prefix: "cb", label: "Clipboard")
                }
            }
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
    }
    
    var noResults: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No apps or files found")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }
    
    var calculatorView: some View {
        VStack(spacing: 12) {
            if let result = viewModel.calculatorResult {
                HStack {
                    Text("=")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(result)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.copyToClipboard(result)
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "function")
                        .font(.system(size: 28))
                        .foregroundColor(.orange.opacity(0.6))
                    
                    Text("Type a math expression")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("Examples: =2+2, =100*0.15, =sqrt(16)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    func searchPreview(engine: String, icon: String, color: Color) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search \(engine)")
                        .font(.system(size: 15, weight: .medium))
                    
                    Text(viewModel.searchQuery.isEmpty ? "Type your search..." : "\"\(viewModel.searchQuery)\"")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text("↵")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.05))
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
    }
    
    var footerView: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 10))
                Text("Navigate")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary.opacity(0.7))
            
            HStack(spacing: 6) {
                Text("↵")
                    .font(.system(size: 11, weight: .medium))
                Text("Select")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary.opacity(0.7))
            
            HStack(spacing: 6) {
                Text("esc")
                    .font(.system(size: 10, weight: .medium))
                Text("Close")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary.opacity(0.7))
            
            Spacer()
            
            Text("\(viewModel.apps.count) cached • spotlight enabled")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.03))
    }
    
    // MARK: - Actions
    func handleSubmit() {
        switch viewModel.currentMode {
        case .apps, .recent:
            if viewModel.filteredApps.indices.contains(viewModel.selectedIndex) {
                launchApp(viewModel.filteredApps[viewModel.selectedIndex])
            }
        case .calculator:
            if let result = viewModel.calculatorResult {
                viewModel.copyToClipboard(result)
                onEscape()
            }
        case .clipboard:
            if viewModel.clipboardHistory.indices.contains(viewModel.selectedIndex) {
                viewModel.copyToClipboard(viewModel.clipboardHistory[viewModel.selectedIndex].content)
                onEscape()
            }
        case .emoji:
            if viewModel.filteredEmojis.indices.contains(viewModel.selectedIndex) {
                viewModel.copyToClipboard(viewModel.filteredEmojis[viewModel.selectedIndex].emoji)
                onEscape()
            }
        case .system:
            if viewModel.filteredSystemCommands.indices.contains(viewModel.selectedIndex) {
                viewModel.filteredSystemCommands[viewModel.selectedIndex].action()
                onEscape()
            }
        case .google:
            openURL("https://www.google.com/search?q=")
        case .youtube:
            openURL("https://www.youtube.com/results?search_query=")
        case .github:
            openURL("https://github.com/search?q=")
        case .define:
            openURL("https://www.google.com/search?q=define+")
        }
    }
    
    func openURL(_ base: String) {
        if !viewModel.searchQuery.isEmpty {
            let query = viewModel.searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: base + query) {
                NSWorkspace.shared.open(url)
                onEscape()
            }
        }
    }
    
    func launchApp(_ app: AppInfo) {
        viewModel.addToRecent(app)
        
        if app.isFile {
            // For executable files (.command, scripts, etc), open them directly
            // .command files will open in Terminal automatically on macOS
            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        } else {
            // For .app bundles, open normally
            NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
        }
        
        onEscape()
    }
}
