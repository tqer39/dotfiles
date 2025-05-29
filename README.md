# Dotfiles

This repository contains my public dotfiles, which are managed using git submodules. These configuration files help maintain a consistent development environment across different machines.

## Repository Structure

- `src/`: Contains all dotfiles
  - `.bash_profile`: Bash profile configuration
  - `.bashrc`: Bash shell configuration
  - `.gitconfig`: Git configuration
  - `.gitignore`: Global gitignore rules
  - `.hyper.js`: Hyper terminal configuration
  - `.zshrc`: Zsh shell configuration
  - `.vscode/`: VS Code settings and extensions
  - `.config/`: Application-specific configurations

## Usage

1. Clone this repository as a submodule in your home directory:

   ```bash
   git submodule add https://github.com/yourusername/dotfiles.git
   ```

## Requirements

- macOS (primary development environment)
- zsh (default shell)
- Git

## Documentation

For detailed documentation in Japanese, please refer to [docs/README.ja.md](docs/README.ja.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
