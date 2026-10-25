# felis-terminal Homebrew tap

Homebrew formulae for the [felis-terminal](https://github.com/felis-terminal) projects:

| Formula   | Description                                                      |
| --------- | ---------------------------------------------------------------- |
| `felis`   | [felis](https://github.com/felis-terminal/felis), a GPU-accelerated terminal emulator |
| `pouncer` | [pouncer](https://github.com/felis-terminal/pouncer), a terminal-agnostic single-keystroke hint picker for scrollback |

```sh
brew install felis-terminal/tap/felis
brew install felis-terminal/tap/pouncer
```

Bottles cover macOS on Apple silicon and Linux on x86_64; other platforms build from source.

On macOS, link the felis bundle to launch it from Finder or the Dock:

```sh
ln -sf "$(brew --prefix felis)/felis.app" /Applications/felis.app
```
