#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo_error "Cannot detect OS"
    exit 1
fi

echo_info "Detected OS: $OS"

# Update package manager
echo_info "Updating package manager..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt-get update
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
    sudo yum update -y
elif [[ "$OS" == "arch" ]]; then
    sudo pacman -Syu --noconfirm
fi

# Install core dependencies
echo_info "Installing core dependencies..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt-get install -y git curl wget build-essential xclip ripgrep fd-find unzip
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
    sudo yum install -y git curl wget gcc make xclip ripgrep fd-find unzip
elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --noconfirm git curl wget base-devel xclip ripgrep fd unzip
fi

# Install tmux
echo_info "Installing tmux..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt-get install -y tmux
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
    sudo yum install -y tmux
elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --noconfirm tmux
fi

# Install neovim (latest stable)
echo_info "Installing neovim..."
if command -v nvim &> /dev/null; then
    echo_warn "Neovim already installed"
else
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        # Use snap for Ubuntu/Debian (most reliable)
        sudo snap install nvim --classic
    elif [[ "$OS" == "arch" ]]; then
        sudo pacman -S --noconfirm neovim
    else
        # Fallback to AppImage for other distros
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
        chmod u+x nvim.appimage
        sudo mv nvim.appimage /usr/local/bin/nvim
    fi
    echo_info "Neovim installed"
fi

# Install zsh
echo_info "Installing zsh..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt-get install -y zsh
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
    sudo yum install -y zsh
elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --noconfirm zsh
fi

# Install fzf
echo_info "Installing fzf..."
if [ ! -d ~/.fzf ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-fish
else
    echo_warn "fzf already installed"
fi

# Install zoxide
echo_info "Installing zoxide..."
if ! command -v zoxide &> /dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
    echo_warn "zoxide already installed"
fi

# Install bat
echo_info "Installing bat..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt-get install -y bat
    # Debian/Ubuntu uses 'batcat' instead of 'bat'
    mkdir -p ~/.local/bin
    ln -sf /usr/bin/batcat ~/.local/bin/bat 2>/dev/null || true
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "fedora" ]]; then
    sudo yum install -y bat
elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --noconfirm bat
fi

# Install eza (modern ls replacement)
echo_info "Installing eza..."
if ! command -v eza &> /dev/null; then
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        sudo apt-get install -y eza
    else
        echo_warn "eza installation not automated for $OS, install manually if needed"
    fi
else
    echo_warn "eza already installed"
fi

# Setup NvChad
echo_info "Setting up NvChad..."
if [ -d ~/.config/nvim ]; then
    echo_warn "Neovim config already exists, backing up to ~/.config/nvim.backup"
    mv ~/.config/nvim ~/.config/nvim.backup.$(date +%s)
fi
git clone https://github.com/NvChad/starter ~/.config/nvim

# Create custom nvim config for clipboard
mkdir -p ~/.config/nvim/lua/custom
cat > ~/.config/nvim/lua/custom/init.lua << 'EOF'
-- Custom configuration
vim.opt.clipboard = "unnamedplus"
EOF

# Setup tmux config
echo_info "Creating tmux config..."
cat > ~/.tmux.conf << 'EOF'
# Change prefix from C-b to C-a
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse mode
set -g mouse on

# Start window numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback buffer
set -g history-limit 10000

# Better split bindings
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Vim-like pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Vim-like pane resizing
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Enable clipboard (OSC 52)
set -g set-clipboard on

# Vi mode for copy mode
setw -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# Better colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Status bar styling
set -g status-style bg=black,fg=white
set -g status-left-length 40
set -g status-left "#[fg=green]Session: #S #[fg=yellow]#I #[fg=cyan]#P"
set -g status-right "#[fg=cyan]%d %b %R"
set -g status-interval 60
set -g status-justify centre

# Pane border colors
set -g pane-border-style fg=colour240
set -g pane-active-border-style fg=colour33
EOF

# Install oh-my-zsh
echo_info "Installing oh-my-zsh..."
if [ ! -d ~/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo_warn "oh-my-zsh already installed"
fi

# Install powerlevel10k
echo_info "Installing powerlevel10k..."
if [ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo_warn "powerlevel10k already installed"
fi

# Apply p10k config
echo_info "Applying p10k config..."
curl -fsSL https://raw.githubusercontent.com/go-johnnyhe/dotfiles/main/.p10k.zsh -o ~/.p10k.zsh

# Setup .zshrc
echo_info "Configuring .zshrc..."
cat > ~/.zshrc << 'EOF'
# Add local bin to PATH (must be before oh-my-zsh loads)
export PATH="$HOME/.local/bin:$PATH"

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set powerlevel10k theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git fzf zoxide)

source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR='nvim'
export VISUAL='nvim'

# Aliases
alias vim='nvim'
alias vi='nvim'
alias n='nvim'
alias ls='eza --icons'
alias ll='eza -lh --icons'
alias la='eza -lah --icons'
alias cat='bat'

# fzf configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# zoxide
eval "$(zoxide init zsh)"
EOF

# Change default shell to zsh
echo_info "Changing default shell to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
    echo_info "Shell changed to zsh. Please log out and log back in for it to take effect."
fi

echo_info "============================================"
echo_info "Installation complete!"
echo_info "============================================"
echo_info "Next steps:"
echo_info "1. Log out and log back in (or run 'exec zsh')"
echo_info "2. Run 'p10k configure' to set up powerlevel10k"
echo_info "3. Open nvim and let NvChad finish installing"
echo_info "4. Tmux prefix is now Ctrl+A"
echo_info ""
echo_info "Quick reference:"
echo_info "- Tmux: prefix | (vertical split), prefix - (horizontal split)"
echo_info "- Tmux: prefix h/j/k/l (navigate panes)"
echo_info "- zoxide: z <dir> (jump to directory)"
echo_info "- fzf: Ctrl+R (history search), Ctrl+T (file search)"
