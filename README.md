# AWS Profile Manager (awsctx)

A `kubectx`-like tool for managing AWS profiles in Zsh. Switch between AWS profiles quickly and efficiently with an interactive menu or direct commands.

## Features

- 🚀 **Fast profile switching** with caching (60-second TTL)
- 🎯 **Interactive menu** with arrow key navigation
- 🔄 **Previous profile support** (`awsctx -` to switch back)
- 📝 **Tab completion** for profile names
- 🎨 **Spaceship ZSH theme integration** with cloud emoji
- 🧠 **Smart profile detection** from both `~/.aws/config` and `~/.aws/credentials`
- ⚡ **Lightweight and fast** - no external dependencies

## Installation

### Oh My Zsh

1. **Clone the plugin to your custom plugins directory:**
   ```bash
   git clone https://github.com/AlmogBaku/zsh-awsctx.git \
     $ZSH_CUSTOM/plugins/awsctx
   ```

2. **Add `awsctx` to your plugins list in `~/.zshrc`:**
   ```bash
   plugins=(
     git
     aws
     awsctx
     # ... your other plugins
   )
   ```

3. **Reload your shell:**
   ```bash
   source ~/.zshrc
   # or restart your terminal
   ```

That's it! The plugin will be automatically loaded by Oh My Zsh.

### Alternative Installation Methods

<details>
<summary>Antidote Plugin Manager</summary>

1. **Local Plugin Installation:**
   ```bash
   # Create local plugin directory
   mkdir -p ~/.config/zsh/plugins/awsctx
   
   # Download the plugin
   curl -o ~/.config/zsh/plugins/awsctx/awsctx.plugin.zsh \
     https://raw.githubusercontent.com/AlmogBaku/zsh-awsctx/main/awsctx.plugin.zsh
   ```

2. **Add to your `.zshrc`:**
   ```bash
   # Add this line to your antidote bundle list
   antidote bundle ~/.config/zsh/plugins/awsctx
   ```

3. **Reload your shell:**
   ```bash
   source ~/.zshrc
   ```

</details>

<details>
<summary>Manual Installation</summary>

1. **Download the script:**
   ```bash
   curl -o ~/.zsh/awsctx.zsh \
     https://raw.githubusercontent.com/AlmogBaku/zsh-awsctx/main/awsctx.plugin.zsh
   ```

2. **Source in your `.zshrc`:**
   ```bash
   source ~/.zsh/awsctx.zsh
   ```

</details>

## Usage

### Interactive Mode

```bash
awsctx
```

Shows an interactive menu with arrow key navigation:
```
Current profile: default
Use ↑/↓ arrows to navigate, Enter to select, Ctrl+C to cancel

Select AWS profile:
  default (current)
→ development
  staging  
  production
```

### Direct Profile Switching

```bash
# Switch to a specific profile
awsctx production

# Switch to previous profile
awsctx -

# Show current profile
awsctx -c
awsctx --current

# Show help
awsctx -h
awsctx --help
```

### Aliases

The plugin provides convenient aliases:
```bash
awsp production     # Same as awsctx production
aws-profile -c      # Same as awsctx -c
```

## Configuration

### AWS Profile Setup

The tool automatically detects profiles from:
- `~/.aws/config` - profiles defined as `[profile name]`
- `~/.aws/credentials` - profiles defined as `[name]`

Example `~/.aws/config`:
```ini
[profile development]
region = us-west-2
output = json

[profile production]
region = us-east-1
output = json
```

Example `~/.aws/credentials`:
```ini
[development]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

[production]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

### Spaceship Theme Integration

If you're using [Spaceship ZSH theme](https://github.com/spaceship-prompt/spaceship-prompt), the plugin automatically integrates and shows your current AWS profile in the prompt.

**Spaceship Configuration Options:**
```bash
# Show/hide AWS section (default: true)
SPACESHIP_AWS_SHOW=true

# Show default profile (default: false)  
SPACESHIP_AWS_SHOW_DEFAULT=false

# Customize the display
SPACESHIP_AWS_PREFIX="using "
SPACESHIP_AWS_SUFFIX=" "
SPACESHIP_AWS_SYMBOL="☁️ "
SPACESHIP_AWS_COLOR="208"
```

### Custom Prompt Integration

For non-Spaceship themes, use the `aws_profile_info()` function:
```bash
# Add to your existing prompt
PS1='%n@%m:%~$(aws_profile_info)$ '
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_CONFIG_FILE` | `~/.aws/config` | Path to AWS config file |
| `AWS_CREDENTIALS_FILE` | `~/.aws/credentials` | Path to AWS credentials file |
| `AWS_PROFILE` | `default` | Current AWS profile |

## Performance

- **Caching:** Profiles are cached for 60 seconds to improve performance
- **Smart Detection:** Only reads AWS files when necessary
- **Minimal Impact:** Lightweight implementation with no external dependencies

## Troubleshooting

### No profiles found
```bash
awsctx
# No AWS profiles found. Check your ~/.aws/config and ~/.aws/credentials files.
```
**Solution:** Ensure your AWS configuration files exist and contain valid profile definitions.

### Profile not found
```bash
awsctx nonexistent
# Profile 'nonexistent' not found.
# Available profiles:
#   default
#   development
#   production
```
**Solution:** Use `awsctx` without arguments to see available profiles, or check your AWS configuration.

### Tab completion not working
**Solution:** Ensure your Zsh completion system is properly initialized:
```bash
autoload -Uz compinit
compinit
```

## Comparison with Other Tools

| Feature | awsctx | aws-vault | aws-profile |
|---------|--------|-----------|-------------|
| Interactive menu | ✅ | ❌ | ❌ |
| Previous profile | ✅ | ❌ | ✅ |
| Tab completion | ✅ | ✅ | ❌ |
| Spaceship integration | ✅ | ❌ | ❌ |
| No external deps | ✅ | ❌ | ✅ |
| Caching | ✅ | ❌ | ❌ |

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [kubectx](https://github.com/ahmetb/kubectx) for Kubernetes context switching
- Compatible with [Spaceship ZSH theme](https://github.com/spaceship-prompt/spaceship-prompt)
- Works great with [Antidote](https://github.com/mattmc3/antidote) plugin manager

## Related Projects

- [kubectx](https://github.com/ahmetb/kubectx) - Switch between Kubernetes contexts
- [aws-vault](https://github.com/99designs/aws-vault) - Secure credential storage
- [spaceship-prompt](https://github.com/spaceship-prompt/spaceship-prompt) - Minimalistic Zsh prompt
- [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) - Framework for managing Zsh configuration
