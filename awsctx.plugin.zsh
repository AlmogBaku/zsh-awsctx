# AWS Profile Manager - A kubectx-like tool for AWS profiles with persistence
# Compatible with denysdovhan/spaceship-zsh-theme and Antidote
# Usage:
#   awsctx                    # Interactive menu to select profiles
#   awsctx <profile>          # Switch to a specific profile
#   awsctx -                  # Switch to previous profile
#   awsctx -c                 # Show current profile
#   awsctx -h                 # Show help

# Cache for profiles to improve performance
typeset -g _AWSCTX_PROFILES_CACHE
typeset -g _AWSCTX_CACHE_TIME=0

# File to store current profile for persistence
typeset -g _AWSCTX_CURRENT_PROFILE_FILE="$HOME/.awsctx_current"

# Global helper function to get all available profiles with caching
_awsctx_get_profiles() {
    local aws_config_file="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
    local aws_credentials_file="${AWS_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
    local current_time=$(date +%s)
    local cache_ttl=60  # Cache for 60 seconds
    
    # Check if cache is valid
    if [[ -n "$_AWSCTX_PROFILES_CACHE" ]] && (( current_time - _AWSCTX_CACHE_TIME < cache_ttl )); then
        echo "$_AWSCTX_PROFILES_CACHE"
        return
    fi
    
    local profiles=()
    
    # Get profiles from config file
    if [[ -f "$aws_config_file" ]]; then
        local line
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            
            # Match [profile profile-name] format only
            if [[ "$line" == \[profile\ * ]]; then
                # Extract profile name by removing [profile and ]
                local stripped="${line#\[profile }"
                local profile_name="${stripped%\]}"
                # Only add non-empty profile names
                if [[ -n "$profile_name" ]]; then
                    profiles+=("$profile_name")
                fi
            fi
        done < "$aws_config_file"
    fi
    
    # Get profiles from credentials file
    if [[ -f "$aws_credentials_file" ]]; then
        local line
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            
            # Match [profile-name] format, excluding special sections
            if [[ "$line" =~ ^\[([^]]+)[[:space:]]*\] ]]; then
                local profile_name="${match[1]}"
                # Exclude sso-session and other special sections, and don't duplicate default
                if [[ -n "$profile_name" && "$profile_name" != sso-session* && "$profile_name" != "default" ]]; then
                    profiles+=("$profile_name")
                fi
            fi
        done < "$aws_credentials_file"
    fi
    
    # Add default profile if it exists
    if [[ -f "$aws_credentials_file" ]] && grep -q '^\[default\]' "$aws_credentials_file"; then
        profiles+=("default")
    fi
    
    # Remove duplicates and sort
    local unique_profiles=($(printf '%s\n' "${profiles[@]}" | sort -u))
    
    # Update cache
    _AWSCTX_PROFILES_CACHE="${unique_profiles[*]}"
    _AWSCTX_CACHE_TIME="$current_time"
    
    echo "${unique_profiles[*]}"
}

# Helper function for displaying the interactive menu
_awsctx_display_menu() {
    local selected="$1"
    local current_profile="$2"
    local total="$3"
    shift 3
    local profiles=("$@")
    
    # Move cursor up to the "Select AWS profile:" line and clear from there down
    # We need to go up: 1 line for each profile + 1 for the header = total + 1
    for ((i=0; i<total+1; i++)); do
        printf "\033[1A"  # Move up one line
    done
    printf "\033[1G"  # Move to column 1 (beginning of line)
    printf "\033[J"   # Clear from cursor to end of screen
    
    echo "Select AWS profile:"
    for ((i=1; i<=total; i++)); do
        if [[ $i -eq $selected ]]; then
            if [[ "${profiles[$i]}" == "$current_profile" ]]; then
                echo "→ ${profiles[$i]} (current)"
            else
                echo "→ ${profiles[$i]}"
            fi
        else
            if [[ "${profiles[$i]}" == "$current_profile" ]]; then
                echo "  ${profiles[$i]} (current)"
            else
                echo "  ${profiles[$i]}"
            fi
        fi
    done
}

# Function to load the current profile on shell startup
_awsctx_load_current_profile() {
    if [[ -f "$_AWSCTX_CURRENT_PROFILE_FILE" ]]; then
        local stored_profile=$(cat "$_AWSCTX_CURRENT_PROFILE_FILE" 2>/dev/null)
        if [[ -n "$stored_profile" ]] && [[ -z "$AWS_PROFILE" ]]; then
            export AWS_PROFILE="$stored_profile"
        fi
    fi
}

# Main function
awsctx() {
    local aws_config_file="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
    local aws_credentials_file="${AWS_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
    local previous_profile_file="$HOME/.awsctx_previous"
    
    # Helper function to get all available profiles (use global function)
    _get_aws_profiles() {
        _awsctx_get_profiles
    }
    
    # Helper function to validate profile exists
    _profile_exists() {
        local profile="$1"
        local profiles=($(_get_aws_profiles))
        
        for p in "${profiles[@]}"; do
            if [[ "$p" == "$profile" ]]; then
                return 0
            fi
        done
        return 1
    }
    
    # Helper function to get current profile
    _get_current_profile() {
        echo "${AWS_PROFILE:-default}"
    }
    
    # Helper function to set profile
    _set_profile() {
        local profile="$1"
        local current_profile=$(_get_current_profile)
        
        # Save current profile as previous
        echo "$current_profile" > "$previous_profile_file"
        
        # Set new profile
        export AWS_PROFILE="$profile"
        
        # Save to persistent file
        echo "$profile" > "$_AWSCTX_CURRENT_PROFILE_FILE"
        
        # Clear profile cache to ensure fresh data
        _AWSCTX_PROFILES_CACHE=""
        _AWSCTX_CACHE_TIME=0
        
        echo "Switched to AWS profile: $profile"
    }
    
    # Show help
    _show_help() {
        cat << 'EOF'
AWS Profile Manager - A kubectx-like tool for AWS profiles

Usage:
  awsctx                    Interactive menu to select profiles
  awsctx <profile>          Switch to a specific profile  
  awsctx -                  Switch to previous profile
  awsctx -c, --current      Show current profile
  awsctx -h, --help         Show this help message
  awsctx --clear-persistent Clear persistent profile setting

Examples:
  awsctx                    # Interactive menu
  awsctx production         # Switch to 'production' profile
  awsctx -                  # Switch back to previous profile
  awsctx -c                 # Show current profile
  awsctx --clear-persistent # Clear persistent profile
EOF
    }
    
    # Parse arguments - no arguments means interactive menu
    if [[ $# -eq 0 ]]; then
        local current_profile=$(_get_current_profile)
        local profiles=($(_get_aws_profiles))
        
        if [[ ${#profiles[@]} -eq 0 ]]; then
            echo "No AWS profiles found. Check your ~/.aws/config and ~/.aws/credentials files."
            return 1
        fi
        
        # Single profile case
        if [[ ${#profiles[@]} -eq 1 ]]; then
            local target_profile="${profiles[1]}"
            if [[ "$target_profile" != "$current_profile" ]]; then
                _set_profile "$target_profile"
            else
                echo "Already using profile: $target_profile"
            fi
            return 0
        fi
        
        # Interactive menu
        local selected=1
        local total=${#profiles[@]}
        
        # Find current profile for initial selection
        for ((i=1; i<=total; i++)); do
            if [[ "${profiles[$i]}" == "$current_profile" ]]; then
                selected=$i
                break
            fi
        done
        
        echo "Current profile: $current_profile"
        echo "Use ↑/↓ arrows to navigate, Enter to select, Ctrl+C to cancel"
        echo
        
        # Show initial menu
        echo "Select AWS profile:"
        for ((i=1; i<=total; i++)); do
            if [[ $i -eq $selected ]]; then
                if [[ "${profiles[$i]}" == "$current_profile" ]]; then
                    echo "→ ${profiles[$i]} (current)"
                else
                    echo "→ ${profiles[$i]}"
                fi
            else
                if [[ "${profiles[$i]}" == "$current_profile" ]]; then
                    echo "  ${profiles[$i]} (current)"
                else
                    echo "  ${profiles[$i]}"
                fi
            fi
        done
        
        # Handle input
        local key
        while true; do
            read -s -k key  # Silent read to prevent echo
            if [[ "$key" == $'\x1b' ]]; then
                read -s -k key
                if [[ "$key" == '[' ]]; then
                    read -s -k key
                    if [[ "$key" == 'A' ]]; then
                        # Up arrow
                        ((selected--))
                        if [[ $selected -lt 1 ]]; then
                            selected=$total
                        fi
                        _awsctx_display_menu $selected "$current_profile" $total "${profiles[@]}"
                    elif [[ "$key" == 'B' ]]; then
                        # Down arrow
                        ((selected++))
                        if [[ $selected -gt $total ]]; then
                            selected=1
                        fi
                        _awsctx_display_menu $selected "$current_profile" $total "${profiles[@]}"
                    fi
                fi
            elif [[ "$key" == $'\n' || "$key" == $'\r' ]]; then
                # Enter
                local target_profile="${profiles[$selected]}"
                echo
                if [[ "$target_profile" == "$current_profile" ]]; then
                    echo "Already using profile: $target_profile"
                else
                    _set_profile "$target_profile"
                fi
                break
            elif [[ "$key" == $'\x03' ]]; then
                # Ctrl+C
                echo
                echo "Cancelled."
                return 1
            fi
        done
        
    elif [[ "$1" == "-c" || "$1" == "--current" ]]; then
        echo $(_get_current_profile)
    elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
        _show_help
    elif [[ "$1" == "--clear-persistent" ]]; then
        if [[ -f "$_AWSCTX_CURRENT_PROFILE_FILE" ]]; then
            rm "$_AWSCTX_CURRENT_PROFILE_FILE"
            unset AWS_PROFILE
            echo "Cleared persistent AWS profile setting."
        else
            echo "No persistent profile setting found."
        fi
    elif [[ "$1" == "-" ]]; then
        if [[ -f "$previous_profile_file" ]]; then
            local previous_profile=$(cat "$previous_profile_file")
            if _profile_exists "$previous_profile"; then
                _set_profile "$previous_profile"
            else
                echo "Previous profile '$previous_profile' no longer exists."
                return 1
            fi
        else
            echo "No previous profile found."
            return 1
        fi
    else
        local target_profile="$1"
        if _profile_exists "$target_profile"; then
            _set_profile "$target_profile"
        else
            echo "Profile '$target_profile' not found."
            echo "Available profiles:"
            local profiles=($(_get_aws_profiles))
            for profile in "${profiles[@]}"; do
                echo "  $profile"
            done
            return 1
        fi
    fi
}

# Enhanced completion function
_awsctx() {
    local -a profiles
    
    # Only complete if we're on the first argument
    if [[ $CURRENT -eq 2 ]]; then
        # Get available profiles using the global function
        profiles=($(_awsctx_get_profiles))
        _alternative "profiles:AWS profiles:($profiles)"
    fi
}

# Register completion - compatible with Antidote
if command -v compdef >/dev/null 2>&1; then
    compdef _awsctx awsctx
fi

# Load current profile on shell startup
_awsctx_load_current_profile

# Spaceship ZSH Theme Integration
# This adds AWS profile support to Spaceship prompt
if [[ -n "$SPACESHIP_VERSION" ]] || [[ "$PROMPT" == *"spaceship"* ]]; then
    # Spaceship AWS section
    spaceship_aws() {
        [[ $SPACESHIP_AWS_SHOW == false ]] && return
        
        # Check if AWS profile is set
        [[ -z $AWS_PROFILE ]] && return
        
        # Don't show if profile is 'default'
        [[ $SPACESHIP_AWS_SHOW_DEFAULT == false && $AWS_PROFILE == "default" ]] && return
        
        local aws_profile="$AWS_PROFILE"
        
        # Show AWS profile in prompt
        spaceship::section \
            --color "$SPACESHIP_AWS_COLOR" \
            --prefix "$SPACESHIP_AWS_PREFIX" \
            --suffix "$SPACESHIP_AWS_SUFFIX" \
            --symbol "$SPACESHIP_AWS_SYMBOL" \
            "$aws_profile"
    }
    
    # Spaceship AWS configuration (set defaults if not already set)
    SPACESHIP_AWS_SHOW="${SPACESHIP_AWS_SHOW=true}"
    SPACESHIP_AWS_SHOW_DEFAULT="${SPACESHIP_AWS_SHOW_DEFAULT=false}"
    SPACESHIP_AWS_PREFIX="${SPACESHIP_AWS_PREFIX="using "}"
    SPACESHIP_AWS_SUFFIX="${SPACESHIP_AWS_SUFFIX="$SPACESHIP_PROMPT_DEFAULT_SUFFIX"}"
    SPACESHIP_AWS_SYMBOL="${SPACESHIP_AWS_SYMBOL="☁️ "}"
    SPACESHIP_AWS_COLOR="${SPACESHIP_AWS_COLOR="208"}"
    
    # Add AWS section to Spaceship prompt order if not already present
    if [[ -n "$SPACESHIP_PROMPT_ORDER" ]] && [[ "$SPACESHIP_PROMPT_ORDER" != *"aws"* ]]; then
        # Add AWS section before the line_sep (or at the end if line_sep not found)
        if [[ "$SPACESHIP_PROMPT_ORDER" == *"line_sep"* ]]; then
            SPACESHIP_PROMPT_ORDER="${SPACESHIP_PROMPT_ORDER/line_sep/aws line_sep}"
        else
            SPACESHIP_PROMPT_ORDER+=" aws"
        fi
    elif [[ -z "$SPACESHIP_PROMPT_ORDER" ]]; then
        # If SPACESHIP_PROMPT_ORDER is not set, add aws to a reasonable default position
        SPACESHIP_PROMPT_ORDER="time user dir host git package node ruby python elm elixir xcode swift golang php rust haskell scala java lua dart julia crystal docker aws kubectl terraform line_sep battery jobs exit_code char"
    fi
fi

# Alternative prompt integration for non-Spaceship themes
if [[ -z "$SPACESHIP_VERSION" ]] && [[ "$PROMPT" != *"spaceship"* ]]; then
    # Function to get AWS profile for prompt
    aws_profile_info() {
        if [[ -n "$AWS_PROFILE" ]] && [[ "$AWS_PROFILE" != "default" ]]; then
            echo " %F{208}☁️ $AWS_PROFILE%f"
        fi
    }
    
    # You can add $(aws_profile_info) to your existing prompt
    # Example: PS1='%n@%m:%~$(aws_profile_info)$ '
fi

# Aliases for convenience
alias awsp='awsctx'
alias aws-profile='awsctx'