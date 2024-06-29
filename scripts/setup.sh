#!/bin/bash

# Function to decrypt and load GitHub info
load_github_info() {
    gpg --quiet --batch --yes --decrypt --passphrase="$1" --output ~/.git_info/github_info.txt ~/.git_info/github_info.gpg
    source ~/.git_info/github_info.txt
    git config --global user.name "$GITHUB_USERNAME"
    git config --global user.email "$GITHUB_EMAIL"
    export GITHUB_TOKEN="$GITHUB_TOKEN"
    rm ~/.git_info/github_info.txt
}

# Load GitHub info
load_github_info "$1"

# Set up the repository
mkdir -p $HOME/repos
cd $HOME/repos
git clone https://github.com/Epineph/setupt_arch

sudo chown -R $USER $HOME/repos
sudo chmod -R u+rwx $HOME/repos

cd UserScripts/scripts
./clone_main_repos.sh

# Ensure correct permissions
sudo chown -R $USER $HOME/repos
sudo chmod -R u+rwx $HOME/repos

# Copy scripts to /usr/local/bin
sudo cp $HOME/repos/setup_arch/scripts/gen_log.sh /usr/local/bin/gen_log
sudo cp $HOME/repos/setup_arch/scripts/chPerms.sh /usr/local/bin/chPerms
sudo cp $HOME/repos/setup_arch/scripts/build_project.sh /usr/local/bin/build_project

# Update .bashrc
cat << 'EOF' >> ~/.bashrc
export CMAKE_INSTALL_PREFIX=$HOME/bin
export CARGO_BIN=$HOME/.cargo/bin
export VCPKG_BIN=$HOME/repos/vcpkg
export PATH=/usr/local/bin:$CMAKE_INSTALL_PREFIX:$CARGO_BIN:$PATH
EOF

sudo chmod -R o+rwx /usr/local/bin
source ~/.bashrc

cd $HOME/repos/yay
gen_log makepkg -si --noconfirm

cd ..
cd paru
gen_log makepkg -si --noconfirm

sudo pacman -S --needed cmake zsh

touch ~/.zshrc

cd $HOME/repos/vcpkg
sudo pacman -Syu --needed base-devel git curl zip unzip tar cmake ninja
./bootstrap-vcpkg.sh

source ~/.bashrc
vcpkg integrate install

cd $HOME/repos/re2c
build_project

cd $HOME/repos/fzf
./install

cd $HOME/repos/fd
cargo build
cargo install --path .

cd $HOME/repos/bat
cargo build --bins
cargo install --path . --locked

bash assets/create.sh
cargo install --path . --locked --force

sudo pacman -S --needed curl lsd jq

curl "https://gist.githubusercontent.com/Epineph/ea3e6e9544845b4becd9d60f088e56c8/raw/d7549d44cadaabcabc2ff14f7e570260300e0cab/zshrc_new.sh" -o ~/.zshrc

echo "Setup complete. Please restart your shell."

