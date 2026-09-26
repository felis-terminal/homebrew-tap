# felis Homebrew tap

Homebrew formulae for [felis](https://github.com/felis-terminal/felis), a GPU-accelerated terminal emulator.

```sh
brew install felis-terminal/tap/felis
```

Bottles cover macOS on Apple silicon and Linux on x86_64; other platforms build from source.

On macOS, link the bundle to launch felis from Finder or the Dock:

```sh
ln -sf "$(brew --prefix felis)/felis.app" /Applications/felis.app
```
