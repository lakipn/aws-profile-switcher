# AWS Profile Switcher

A simple, interactive AWS profile switcher that automatically handles both MFA-enabled profiles and AWS SSO profiles. No more manually setting environment variables or remembering complex commands!

## Features

- 🔄 **Automatic profile detection** - Discovers all your AWS profiles automatically
- 🔐 **MFA Support** - Integrates with `aws-mfa` for MFA-enabled profiles
- 🚀 **SSO Support** - Handles AWS SSO login/logout seamlessly
- 🎯 **Smart switching** - Automatically logs out when switching between SSO profiles
- ⚡ **Environment variables** - Automatically sets `AWS_PROFILE` in your current shell
- 🔍 **Credential validation** - Checks if credentials are expired before use

## Prerequisites

1. **AWS CLI v2** - [Installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. **Bash or Zsh shell** - Most Unix systems have these by default
3. **aws-mfa** (for MFA profiles) - Install with: `pip install aws-mfa`

### Supported Platforms

- ✅ **Linux** (all distributions)
- ✅ **macOS**
- ✅ **BSD systems** (FreeBSD, OpenBSD, NetBSD)
- ✅ **WSL on Windows**
- ✅ **Unix-like systems** with bash or zsh

### Supported Shells

- ✅ **Bash** (4.0+)
- ✅ **Zsh**
- ✅ **Fish** (with special installer support)
- ⚠️ **Other shells** - basic functionality via direct script execution

## Installation

### Homebrew (Recommended)

```bash
brew tap lakipn/tap
brew install awsinit
```

After installation, add the wrapper function to your shell config:

**For Bash** (`~/.bashrc` or `~/.bash_profile`):
```bash
source /opt/homebrew/opt/awsinit/awsinit-wrapper.sh
```

**For Zsh** (`~/.zshrc`):
```bash
source /opt/homebrew/opt/awsinit/awsinit-wrapper.sh
```

**For Fish** (`~/.config/fish/config.fish`):
See the fish function setup in the installer script or create manually.

### Quick Install (From Source)

```bash
git clone https://github.com/lakipn/aws-profile-switcher.git
cd aws-profile-switcher
./install.sh
```

### Manual Install

1. Copy `awsinit` to `~/bin/` and make it executable:

   ```bash
   mkdir -p ~/bin
   cp awsinit ~/bin/awsinit
   chmod +x ~/bin/awsinit
   ```

2. Add `~/bin` to your PATH in your shell config file (`~/.zshrc` or `~/.bashrc`):

   ```bash
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
   ```

3. Copy the wrapper function:

   ```bash
   cp awsinit-wrapper.sh ~/awsinit-wrapper.sh
   ```

4. Source the wrapper in your shell config:

   ```bash
   echo 'source ~/awsinit-wrapper.sh' >> ~/.zshrc
   ```

5. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

## Usage

Simply run:

```bash
awsinit
```

The tool will:

1. Display all available AWS profiles with their types (SSO/MFA/Keys)
2. Let you select which profile to switch to
3. Handle authentication (MFA code entry or SSO browser login)
4. Set the `AWS_PROFILE` environment variable automatically
5. Show your current AWS identity

### Example Output

```
ℹ Select AWS account to switch to:

1. default (MFA/Keys)
2. company-dev (SSO)
3. company-prod (SSO)
4. personal (MFA/Keys)

Enter your choice (1-4): 2
ℹ Selected profile: company-dev
ℹ Detected SSO profile: company-dev
ℹ Running aws sso login...
✓ SSO login successful for company-dev
✓ SSO credentials verified
✓ Switched to profile: company-dev

ℹ Current AWS identity:
-----------------------------------------
|            GetCallerIdentity          |
+---------+-----------------------------+
| Account | 123456789012                |
| Arn     | arn:aws:sts::123456789012.. |
| UserId  | AROABC123...:john.doe       |
+---------+-----------------------------+

✓ Environment updated: export AWS_PROFILE="company-dev"
✓ AWS_PROFILE is now: company-dev
```

## Configuration

### AWS Profiles Setup

The tool automatically detects your AWS profiles from `~/.aws/config` and `~/.aws/credentials`.

#### For SSO Profiles

Configure SSO profiles in `~/.aws/config`:

```ini
[profile company-dev]
sso_start_url = https://company.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = DeveloperAccess
region = us-east-1
```

#### For MFA Profiles

Configure MFA profiles in `~/.aws/credentials`:

```ini
[default-long-term]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
aws_mfa_device = arn:aws:iam::123456789012:mfa/YourDevice

[default]
# This will be populated by aws-mfa
```

### aws-mfa Setup

For MFA-enabled profiles, install and configure `aws-mfa`:

1. Install: `pip install aws-mfa`
2. Configure your long-term credentials with MFA device ARN (see example above)
3. The tool will automatically call `aws-mfa` when needed

## How It Works

1. **Profile Detection**: Scans `~/.aws/config` for profiles and detects their type
2. **SSO Profiles**: Profiles with `sso_start_url` are treated as SSO profiles
3. **MFA Profiles**: Other profiles are treated as MFA/key-based profiles
4. **Smart Authentication**:
   - SSO: Uses `aws sso login --profile <profile>`
   - MFA: Uses `aws-mfa` for the default profile
   - Keys: Direct credential usage for named profiles
5. **Environment Management**: Automatically sets/unsets `AWS_PROFILE` in your current shell

## Troubleshooting

### Command not found

- Make sure `~/bin` is in your PATH: `echo $PATH | grep "$HOME/bin"`
- Reload your shell or restart terminal
- On some systems, you may need to log out and back in

### Shell-specific issues

#### Bash

- Try: `source ~/.bashrc` or `source ~/.bash_profile`
- On macOS, you may need to use `~/.bash_profile` instead of `~/.bashrc`

#### Zsh

- Try: `source ~/.zshrc`
- If using Oh My Zsh, ensure no conflicts with plugins

#### Fish

- The installer creates a native fish function
- Try: `source ~/.config/fish/config.fish`

### Platform-specific issues

#### macOS

- You may need to restart Terminal.app for PATH changes
- Ensure you have bash installed: `bash --version`

#### Linux

- Different distributions may use different default shells
- Try: `echo $SHELL` to see your current shell

#### WSL

- Make sure you're using a Linux-style path: `/home/user/bin`
- Windows paths won't work with the Unix-style installer

### aws-mfa not found

- Install with: `pip install aws-mfa`
- On some systems: `pip3 install aws-mfa`
- Ensure Python pip is in your PATH

### SSO login fails

- Check your SSO configuration in `~/.aws/config`
- Ensure you have access to the AWS account/role
- Try running `aws sso login --profile <profile>` manually
- Check if your browser is blocking the SSO popup

### Environment variables not set

- Make sure you're using the wrapper function (sourced `awsinit-wrapper.sh`)
- For direct script usage: `~/bin/awsinit` and manually run the export command shown
- Try reloading your shell configuration

### Permission denied

- Ensure the script is executable: `chmod +x ~/bin/awsinit`
- Check file ownership: `ls -la ~/bin/awsinit`

### Colors not working

- Your terminal may not support ANSI colors
- Try a different terminal emulator
- The functionality will work without colors

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details.
