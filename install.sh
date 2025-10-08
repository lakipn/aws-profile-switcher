#!/bin/sh

# AWS Profile Switcher Installation Script
# Compatible with bash, zsh, and POSIX shells on all Unix systems

set -e

# Colors for output (with fallback for systems without color support)
if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
    RED=$(tput setaf 1 2>/dev/null || echo '')
    GREEN=$(tput setaf 2 2>/dev/null || echo '')
    YELLOW=$(tput setaf 3 2>/dev/null || echo '')
    BLUE=$(tput setaf 4 2>/dev/null || echo '')
    BOLD=$(tput bold 2>/dev/null || echo '')
    NC=$(tput sgr0 2>/dev/null || echo '')
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

print_info() { printf "%s%s %s%s\n" "$BLUE" "ℹ" "$1" "$NC"; }
print_success() { printf "%s%s %s%s\n" "$GREEN" "✓" "$1" "$NC"; }
print_warning() { printf "%s%s %s%s\n" "$YELLOW" "⚠" "$1" "$NC"; }
print_error() { printf "%s%s %s%s\n" "$RED" "✗" "$1" "$NC"; }

echo ""
print_info "Installing AWS Profile Switcher..."
echo ""

# Detect OS and shell
OS=$(uname -s)
SHELL_NAME=$(basename "${SHELL:-/bin/sh}")

print_info "Detected OS: $OS"
print_info "Detected shell: $SHELL_NAME"

# Check prerequisites
if ! command -v aws >/dev/null 2>&1; then
    print_error "AWS CLI is not installed. Please install it first:"
    print_error "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Create ~/bin directory if it doesn't exist
mkdir -p "$HOME/bin"

# Copy the main script
cp awsinit "$HOME/bin/awsinit"
chmod +x "$HOME/bin/awsinit"
print_success "Installed awsinit to ~/bin/awsinit"

# Determine shell configuration files to update
SHELL_CONFIGS=""
DETECTED_SHELL=""

# Check current shell first
case "$SHELL_NAME" in
    zsh)
        DETECTED_SHELL="zsh"
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIGS="$HOME/.zshrc"
        else
            touch "$HOME/.zshrc"
            SHELL_CONFIGS="$HOME/.zshrc"
        fi
        ;;
    bash)
        DETECTED_SHELL="bash"
        # Try multiple bash config files in order of preference
        for config in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
            if [ -f "$config" ]; then
                SHELL_CONFIGS="$config"
                break
            fi
        done
        # If none exist, create .bashrc
        if [ -z "$SHELL_CONFIGS" ]; then
            touch "$HOME/.bashrc"
            SHELL_CONFIGS="$HOME/.bashrc"
        fi
        ;;
    fish)
        DETECTED_SHELL="fish"
        mkdir -p "$HOME/.config/fish"
        if [ -f "$HOME/.config/fish/config.fish" ]; then
            SHELL_CONFIGS="$HOME/.config/fish/config.fish"
        else
            touch "$HOME/.config/fish/config.fish"
            SHELL_CONFIGS="$HOME/.config/fish/config.fish"
        fi
        ;;
    *)
        # Fallback to .profile for unknown shells
        DETECTED_SHELL="unknown"
        if [ -f "$HOME/.profile" ]; then
            SHELL_CONFIGS="$HOME/.profile"
        else
            touch "$HOME/.profile"
            SHELL_CONFIGS="$HOME/.profile"
        fi
        print_warning "Unknown shell detected. Using ~/.profile"
        ;;
esac

# Add to shell configuration
if [ -n "$SHELL_CONFIGS" ]; then
    for config in $SHELL_CONFIGS; do
        # Add PATH export if not present
        if ! grep -q 'export PATH.*HOME/bin.*PATH' "$config" 2>/dev/null; then
            echo "" >> "$config"
            echo "# Added by AWS Profile Switcher installer" >> "$config"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$config"
            print_success "Added ~/bin to PATH in $config"
        else
            print_info "~/bin already in PATH in $config"
        fi
        
        # Add wrapper function source for bash/zsh
        if [ "$DETECTED_SHELL" != "fish" ]; then
            if ! grep -q "source.*awsinit-wrapper.sh" "$config" 2>/dev/null; then
                echo 'source "$HOME/awsinit-wrapper.sh"' >> "$config"
                print_success "Added wrapper function to $config"
            else
                print_info "Wrapper function already configured in $config"
            fi
        fi
    done
else
    print_warning "Could not detect shell configuration file."
    print_warning "Please manually add the following to your shell configuration:"
    print_warning '  export PATH="$HOME/bin:$PATH"'
    print_warning '  source "$HOME/awsinit-wrapper.sh"'
fi

# Copy wrapper function
cp awsinit-wrapper.sh "$HOME/awsinit-wrapper.sh"
print_success "Installed wrapper function to ~/awsinit-wrapper.sh"

# Special handling for fish shell
if [ "$DETECTED_SHELL" = "fish" ]; then
    print_warning "Fish shell detected. Creating fish-compatible function..."
    cat > "$HOME/.config/fish/functions/awsinit.fish" << 'EOF'
function awsinit
    set temp_file (mktemp)
    $HOME/bin/awsinit | while read -l line
        if string match -q "AWSINIT_CMD=*" -- $line
            string replace "AWSINIT_CMD=" "" -- $line > $temp_file
        else
            echo $line
        end
    end
    
    if test -s $temp_file
        set cmd (cat $temp_file)
        eval $cmd
        echo "✓ Environment updated: $cmd"
        if set -q AWS_PROFILE
            echo "✓ AWS_PROFILE is now: $AWS_PROFILE"
        else
            echo "✓ AWS_PROFILE is now: (unset - using default)"
        end
    end
    
    rm -f $temp_file
end
EOF
    print_success "Created fish function at ~/.config/fish/functions/awsinit.fish"
fi

echo ""
print_success "Installation complete!"
echo ""
print_info "${BOLD}To start using awsinit:${NC}"

case "$DETECTED_SHELL" in
    zsh)
        print_info "1. Reload your shell: source ~/.zshrc"
        ;;
    bash)
        print_info "1. Reload your shell: source ~/.bashrc (or restart terminal)"
        ;;
    fish)
        print_info "1. Reload your shell: source ~/.config/fish/config.fish (or restart terminal)"
        ;;
    *)
        print_info "1. Reload your shell: source ~/.profile (or restart terminal)"
        ;;
esac

print_info "2. Run: awsinit"
echo ""
print_info "For MFA profiles, install aws-mfa:"
print_info "  pip install aws-mfa"
echo ""
print_info "Supported platforms:"
print_info "  • Linux (all distributions)"
print_info "  • macOS"
print_info "  • BSD systems"
print_info "  • WSL on Windows"
echo ""

# OS-specific notes
case "$OS" in
    Darwin)
        print_info "macOS detected - you may need to restart Terminal.app for PATH changes"
        ;;
    Linux)
        if command -v systemd >/dev/null 2>&1; then
            print_info "Linux with systemd detected - PATH should be available in new terminals"
        fi
        ;;
    *BSD)
        print_info "BSD system detected - you may need to restart your terminal"
        ;;
esac