class Pouncer < Formula
  desc "Terminal-agnostic single-keystroke hint picker for scrollback"
  homepage "https://github.com/felis-terminal/pouncer"
  url "https://github.com/felis-terminal/pouncer/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "782c24ff8f87ed05181f0f1273e14f004f1c0934a8c736dfe764d7489fcc74d7"
  license "Apache-2.0"
  head "https://github.com/felis-terminal/pouncer.git", branch: "main"

  bottle do
    root_url "https://github.com/felis-terminal/homebrew-tap/releases/download/pouncer-0.1.1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "5ed231538f099faaacb4f943fcf9730ef917a53d6edab65de4fbe1794014cd3d"
    sha256 cellar: :any,                 x86_64_linux:  "1f1369a4efab5b15f4489c1257160afa6f9c0118dc4ad51afbe015ce94ad3439"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"pouncer", "--generate", shell_parameter_format: "complete-")
    (man1/"pouncer.1").write Utils.safe_popen_read(bin/"pouncer", "--generate", "man")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pouncer --version")
    # A single match is picked without the overlay, so no terminal is needed.
    assert_equal "https://example.com/x\n",
                 pipe_output("#{bin}/pouncer --preset url", "see https://example.com/x here\n", 0)
    pipe_output("#{bin}/pouncer --preset url", "nothing\n", 1)
  end
end
