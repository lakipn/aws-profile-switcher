# AWS Profile Switcher Wrapper Function
# This function wraps the awsinit script to automatically set environment variables
# Compatible with bash and zsh

# Check if we're in a compatible shell
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
    awsinit() {
        # Create temp file to store the export command
        local temp_cmd
        temp_cmd=$(mktemp)
        
        # Run script and process output line by line in real-time
        "$HOME/bin/awsinit" | while IFS= read -r line; do
            case "$line" in
                AWSINIT_CMD=*)
                    # Save export command to temp file
                    echo "$line" | sed 's/^AWSINIT_CMD=//' > "$temp_cmd"
                    ;;
                *)
                    # Show all other output immediately
                    echo "$line"
                    ;;
            esac
        done
        
        # Get the exit code from the pipeline
        local exit_code=${PIPESTATUS[0]:-$?}
        
        # Execute the export command if we got one
        if [ -s "$temp_cmd" ]; then
            local cmd
            cmd=$(cat "$temp_cmd")
            eval "$cmd"
            printf '%s\n' "✓ Environment updated: $cmd"
            printf '%s\n' "✓ AWS_PROFILE is now: ${AWS_PROFILE:-"(unset - using default)"}"
        fi
        
        # Clean up
        rm -f "$temp_cmd"
        return $exit_code
    }
else
    # Fallback function for unsupported shells
    awsinit() {
        echo "Error: awsinit wrapper requires bash or zsh"
        echo "Run directly: $HOME/bin/awsinit"
        return 1
    }
fi