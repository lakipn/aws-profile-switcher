# AWS Profile Switcher Wrapper Function
# This function wraps the awsinit script to automatically set environment variables
# Compatible with bash and zsh

# Check if we're in a compatible shell
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then
    awsinit() {
        # Create temp files to store the export command and full output
        local temp_cmd temp_output
        temp_cmd=$(mktemp)
        temp_output=$(mktemp)

        # Run script and capture output to temp file
        "$HOME/bin/awsinit" > "$temp_output"
        local exit_code=$?

        # Process output line by line
        while IFS= read -r line; do
            case "$line" in
                AWSINIT_CMD=*)
                    # Save export command to temp file
                    echo "$line" | sed 's/^AWSINIT_CMD=//' > "$temp_cmd"
                    ;;
                *)
                    # Show all other output
                    echo "$line"
                    ;;
            esac
        done < "$temp_output"

        # Execute the export command if we got one
        if [ -s "$temp_cmd" ]; then
            local cmd
            cmd=$(cat "$temp_cmd")
            eval "$cmd"
            printf '%s\n' "✓ Environment updated: $cmd"
            printf '%s\n' "✓ AWS_PROFILE is now: ${AWS_PROFILE:-"(unset - using default)"}"
        fi

        # Clean up
        rm -f "$temp_cmd" "$temp_output"
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