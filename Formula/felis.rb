class Felis < Formula
  desc "Terminal for your toolkit, not an environment"
  homepage "https://github.com/felis-terminal/felis"
  url "https://github.com/felis-terminal/felis/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "b202f77eb5c9e83dbb1e70da78e5603834f2b9018f4b2de0671b6953f23fa1fa"
  license "Apache-2.0"
  head "https://github.com/felis-terminal/felis.git", branch: "main"

  bottle do
    root_url "https://github.com/felis-terminal/homebrew-tap/releases/download/felis-0.1.2"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "1588dc469a86d6b8d9a0164375024c5f12e9358ef1d0670752e31fa80308d9dc"
    sha256 cellar: :any,                 x86_64_linux:  "10b1419c45e6ec5c86b49cb0d0a4af538f8367ce498711877d9179eecc364819"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "ncurses" => :build
    # dlopen'd at runtime, so they appear in no DT_NEEDED entry.
    depends_on "libx11"
    depends_on "libxcb"
    depends_on "libxcursor"
    depends_on "libxi"
    depends_on "libxkbcommon"
    depends_on "libxrandr"
    depends_on "vulkan-loader"
    depends_on "wayland"
  end

  def install
    # dlopen resolves against the executable's RUNPATH, not the loader's default path.
    ENV.append "RUSTFLAGS", "-C link-arg=-Wl,-rpath,#{HOMEBREW_PREFIX}/lib" if OS.linux?

    root = OS.mac? ? buildpath/"stage" : libexec
    system "cargo", "install", *std_cargo_args(root:, path: "crates/felis-cli")
    system "cargo", "install", *std_cargo_args(root:, path: "crates/felis-daemon")
    client_features = OS.linux? ? %w[--features wayland-clipboard] : []
    system "cargo", "install", *client_features, *std_cargo_args(root:, path: "crates/felis-client")

    system "bash", "nix/compile-terminfo.sh", "share/terminfo/felis.terminfo", share/"terminfo"
    # `${commands[felis]:A:h:h}/share/felis/shell-integration/felis.zsh` in the docs resolves to this copy.
    pkgshare.install "share/felis/shell-integration"

    release = root/"bin"
    if OS.mac?
      system "bash", "nix/make-macos-app.sh",
             "--client", release/"felis-client",
             "--daemon", release/"felis-daemon",
             "--cli", release/"felis",
             "--terminfo", share/"terminfo",
             "--version", version.to_s,
             "--out", prefix
      felis = prefix/"felis.app/Contents/MacOS/felis"
    else
      felis = release/"felis"
      share.install "share/applications"
    end

    # felis-client and felis-daemon stay beside felis: each spawns the other by its own directory.
    (bin/"felis").write_env_script felis,
                                   TERMINFO_DIRS: "#{opt_share}/terminfo:${TERMINFO_DIRS-}"

    generate_completions_from_executable(bin/"felis", "completions")
    system bin/"felis", "__mangen", "man"
    man1.install Dir["man/*.1"]
  end

  def caveats
    s = <<~EOS
      Programs started inside felis find the xterm-felis terminfo entry on their own.
      To reach it elsewhere (ssh, tmux):
        export TERMINFO_DIRS="#{opt_share}/terminfo:${TERMINFO_DIRS-}"
    EOS
    if OS.mac?
      s += <<~EOS

        To launch felis from Finder or the Dock:
          ln -sf #{opt_prefix}/felis.app /Applications/felis.app
      EOS
    end
    s
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/felis --version")
    # tic files the entry under x/ or 78/ depending on the ncurses build.
    refute_empty Dir[share/"terminfo/*/xterm-felis"]
    assert_path_exists pkgshare/"shell-integration/felis.zsh"
    # The daemon inside felis.app hands its sessions this copy; Finder passes no TERMINFO_DIRS.
    refute_empty Dir[prefix/"felis.app/Contents/Resources/terminfo/*/xterm-felis"] if OS.mac?

    # The daemon refuses a socket directory other users can enter.
    (testpath/"run").mkpath
    chmod 0700, testpath/"run"
    ENV.delete "FELIS_SOCKET"
    socket = testpath/"run/felis.sock"
    felis = "#{bin}/felis --socket #{socket}"
    begin
      command = "/bin/sh -c 'echo felis-brew-test; exec sleep 60'"
      spawn = shell_output("#{felis} sessions spawn --format json -- #{command}")
      id = JSON.parse(spawn)["id"]
      screen = ""
      10.times do
        screen = shell_output("#{felis} sessions capture #{id} --format jsonl")
        break if screen.include?("felis-brew-test")

        sleep 1
      end
      assert_match "felis-brew-test", screen

      versions = JSON.parse(shell_output("#{felis} version --format json"))
      assert_equal "ok", versions["client_status"]
      assert_equal "ok", versions["daemon_status"]
      %w[cli client daemon].each { |part| assert_equal version.to_s, versions[part]["version"] }
    ensure
      quiet_system bin/"felis", "--socket", socket, "daemon", "stop", "--force"
    end
  end
end
