# =================================
# first make sure system uses en_US.UTF-8

echo "LC_ALL=en_US.UTF-8" | sudo tee -a /etc/environment
echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf
sudo locale-gen en_US.UTF-8

# =================================
# install required packages

# common tools
sudo apt install zsh zip pipx direnv zoxide git curl wget

# packages needed for building ruby from source
sudo apt build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libncurses5-dev libffi-dev libgdbm-dev 

# =================================
# install oh-my-zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# =================================
# install ssh keys

# manually download ssh from bitbucket first, keep it in ~/Downloads on windows
cp /mnt/c/Users/ball6/Downloads/ball6847-ssh-cfbd1d92729e.zip . 
unzip ball6847-ssh-cfbd1d92729e.zip
rm ball6847-ssh-cfbd1d92729e.zip
mv ball6847-ssh-cfbd1d92729e .ssh
cd ~/.ssh || exit
./perm
cd ~ || exit

# clone and swap actual ssh files
git clone git@bitbucket.org:ball6847/ssh.git
rm -rf .ssh
mv ssh .ssh
cd ~/.ssh || exit
./perm

# =================================
# install dotfiles

cd ~ || exit
git clone git@github.com:ball6847/ball6847-dotfiles.git ~/.dotfiles --recursive
./install.sh


# =================================
# install asdf

mkdir -p ~/.local/bin

# go to https://github.com/asdf-vm/asdf/releases for list of recent versions
wget https://github.com/asdf-vm/asdf/releases/download/v0.16.7/asdf-v0.16.7-linux-amd64.tar.gz 
tar -zxf asdf-v0.16.7-linux-amd64.tar.gz
rm asdf-v0.16.7-linux-amd64.tar.gz

# =================================
# install asdf plugins as prepared in ~/.dotfiles

cd "$HOME" || exit
asdf-install.sh

# =================================
# install tools via npm

npm install -g typescript typescript-language-server svelte-language-server @fsouza/prettierd nodemon @bufbuild/buf 

# =================================
# install tools via go install

go install github.com/vektra/mockery/v2@latest
go install github.com/mitranim/gow@latest
go install golang.org/x/tools/gopls@latest

# =================================
# install code spell

pipx install codespell

# =================================
# install nvim deps

nvim +MasonInstallAll +qall 

# =================================
# What's next ?

# start copilot setup for nvim, run the command and follow the instruction
nvim +Copilot setup

# setup waka time api, go to https://wakatime.com/settings/account and copy the api key, run the command then paste the key
nvim +WakaTimeApiKey
