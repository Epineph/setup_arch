git_push() {
  local commit_message
  local repo_url
  local sanitized_url

  if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set in your environment."
    return 1
  fi

  echo "Enter the commit message:"
  read -r commit_message

  # Add all changes to the repository
  git add .

  # Commit the changes with the provided message
  git commit -m "$commit_message"

  # Get the repository URL and sanitize it
  repo_url=$(git config --get remote.origin.url)
  sanitized_url=$(echo "$repo_url" | sed 's|https://|https://'"$GITHUB_TOKEN"'@|')

  # Push the changes using the personal access token for authentication
  git push "$sanitized_url" main

  echo "Changes committed and pushed successfully."
}

function clone() {
    local repo=$1
    local target_dir=$REPOS

    # Define the build directory for AUR packages
    local build_dir=~/build_src_dir
    mkdir -p "$build_dir"

    # Clone AUR packages
    if [[ $repo == http* ]]; then
        if [[ $repo == *aur.archlinux.org* ]]; then
            # Clone the AUR repository
            git -C "$build_dir" clone "$repo"
            local repo_name=$(basename "$repo" .git)
            pushd "$build_dir/$repo_name" > /dev/null

            # Build or install based on the second argument
            if [[ $target_dir == "build" ]]; then
                makepkg --syncdeps
            elif [[ $target_dir == "install" ]]; then
                makepkg -si
            fi

            popd > /dev/null
        else
            # Clone non-AUR links
            git clone "$repo" "$target_dir"
        fi
    else
        # Clone GitHub repos given in the format username/repository
        # Ensure the target directory for plugins exists
        # mkdir -p "$target_dir"
        git -C "$REPOS" clone "https://github.com/$repo.git" --recurse-submodules
    fi
}

function addalias() {
    echo "alias $1='$2'" | sudo tee -a ~/.zshrc
    freshZsh
}

export host1=$(getip)

function scp_transfer() {
    local direction=$1
    local src_path=$2
    local dest_path=$3
    local host_alias=$4

    # Retrieve the actual host address from the alias
    local host_address=$(eval echo "\$$host_alias")

    if [[ $direction == "TO" ]]; then
        scp $src_path ${host_address}:$dest_path
    elif [[ $direction == "FROM" ]]; then
        scp ${host_address}:$src_path $dest_path
    else
        echo "Invalid direction. Use TO or FROM."
    fi
}

function check_and_install_packages() {
  local missing_packages=()

  # Check which packages are not installed
  for package in "$@"; do
    if ! pacman -Qi "$package" &> /dev/null; then
      missing_packages+=("$package")
    else
      echo "Package '$package' is already installed."
    fi
  done

  # If there are missing packages, ask the user if they want to install them
  if [ ${#missing_packages[@]} -ne 0 ]; then
    echo "The following packages are not installed: ${missing_packages[*]}"
    read -p "Do you want to install them? (Y/n) " -n 1 -r
    echo    # Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
      for package in "${missing_packages[@]}"; do
        yes | sudo pacman -S "$package"
        if [ $? -ne 0 ]; then
          echo "Failed to install $package. Aborting."
          exit 1
        fi
      done
    else
      echo "The following packages are required to continue:\
      ${missing_packages[*]}. Aborting."
      exit 1
    fi
  fi
}

function check_if_pyEnv_exists() {
    local my_zshrc_dir=~/.zshrc
    local my_virtEnv_dir=~/virtualPyEnvs
    local py_env_name=pyEnv
    local pkg1=python-virtualenv
    local pkg2=python-virtualenvwrapper
    sudo pacman -S --needed --noconfirm $pkg1 $pkg2
    # Check if the virtual environment directory exists
    if [ ! -d "$my_virtEnv_dir" ]; then
        echo "Python Virtualenv and directory doesn't exist, creating it ..."
        sleep 1
        mkdir -p $my_virtEnv_dir
        # Use $1 to check if a custom environment name is provided
        local env_name=${1:-$py_env_name}
        echo "Creating virtual environment: $env_name"
        virtualenv $my_virtEnv_dir/$env_name --system-site-packages --symlinks
    echo "alias startEnv='source /home/$USER/'virtualPyEnvs/pyEnv/bin/activate" >> ~/.zshrc
    else
        echo "Python virtualenv directory exists ..."
        # Check if the standard pyEnv exists or if a custom name is provided
        if [ -z "$1" ] && [ -e "$my_virtEnv_dir/$py_env_name/bin/activate" ]; then
            echo "pyenv directory exists, and no argument, exiting.."
            sleep 2
            exit 1
        else
            # Create a virtual environment with the provided name or the default one
            local env_name=${1:-$py_env_name}
            echo "Creating virtual environment: $env_name"
            virtualenv $my_virtEnv_dir/$env_name --system-site-packages --symlinks
        fi
    fi
}

function git_pull_all() {
    # Store the current directory
    local current_dir=$(pwd)

    # Iterate over each directory in the current directory
    for dir in */; do
        # Check if the directory is a git repository
        if [ -d "${dir}/.git" ]; then
            echo "Updating ${dir}..."
            cd "${dir}" || return # Change to the directory or exit on failure
            
            # Optionally, checkout a specific branch. Remove or modify as needed.
            git checkout && git pull
            git config --global --add safe.directory "${dir}"
            # Pull the latest changes
            #git pull

            # Return to the original directory
            cd "${current_dir}" || return
        else
            echo "${dir} is not a git repository."
        fi
    done
}

fzf_edit() {
    local bat_style='--color=always --line-range :500'
    if [[ $1 == "no_line_number" ]]; then
        bat_style+=' --style=grid'
    fi

    local file
    file=$(fd --type f | fzf --preview "bat $bat_style {}" --preview-window=right:60%:wrap)
    if [[ -n $file ]]; then
        sudo vim "$file"
    fi
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source /home/heini/.local/share/lscolors.sh
export GPG_TTY=$(tty)

