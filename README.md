# UserScripts

This repository contains scripts to set up a development environment on an Arch Linux system.

## Scripts

- `setup.sh`: Main script to set up the environment.
- `clone_main_repos.sh`: Script to clone main repositories.
- `gen_log.sh`: Script to generate logs.
- `generate_install_command.sh`: Script to generate install commands.
- `build_project.sh`: Script to build projects.
- `chPerms.sh`: Script to change permissions.

## Zsh Configuration

The Zsh configuration is split into multiple files for better organization:

- `aliases.zsh`: Contains aliases.
- `env_vars.zsh`: Contains environment variables.
- `history.zsh`: Contains history settings.

## Usage

To set up the environment, run the `setup.sh` script with your GPG passphrase:

```bash
./setup.sh your_passphrase
```

### .gitignore

Create a `.gitignore` file to exclude unnecessary files:

```gitignore
# Compiled source
*.com
*.class
*.dll
*.exe
*.o
*.so

# Packages
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.tar
*.zip

# Logs and databases
*.log
*.sql
*.sqlite

# OS generated files
.DS_Store
Thumbs.db

# Encrypted files
.git_info/*.gpg
```