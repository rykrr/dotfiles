#!/bin/bash

local_bin=$HOME/.local/bin


# Install sudo if not installed
################################
if ! which sudo >/dev/null; then
	echo "Installing sudo..."
	su -c "apt install -y sudo ; /sbin/usermod -aG sudo $(whoami)"
	echo "bash $(pwd)/$0" > .bashrc
	echo "Please log out for changes to take effect."
	exit 1
fi

base_install() {
	# Install packages
	###################
	sudo apt install -y $(sed '/^#/d' < packages.txt)
}

bash_setup() {
	# Bash Setup
	#############
	cp {/etc/skel,$HOME}/.bashrc

	cat <<- EOF >> $HOME/.bashrc
	source /usr/share/doc/fzf/examples/key-bindings.bash
	export PATH=\$PATH:\$HOME/.local/bin
	export PS1='\[\e[96m\]\u\[\e[0m\]@\[\e[91m\]\h\[\e[0m\]:\w\\$ '
	EOF
}

neovim_install() {
	# Install neovim
	#################
	echo Installing neovim...
	mkdir -p .cache/nvim
	pushd .cache/nvim >/dev/null

	neovim_target=nvim-linux-x86_64
	neovim_tarball=$neovim_target.tar.gz
	neovim_version=v0.10.4
	neovim_sha256sum=95aaa8e89473f5421114f2787c13ae0ec6e11ebbd1a13a1bd6fcf63420f8073f

	echo -e "${neovim_sha256sum}  ${neovim_tarball}" > ${neovim_tarball}.sha256sum
	wget -nc https://github.com/neovim/neovim/releases/download/$neovim_version/$neovim_tarball

	if ! sha256sum --check $neovim_tarball.sha256sum; then
		echo "Something went wrong while trying to install neovim."
		exit 1
	fi

	mkdir -p /opt
	sudo tar -C /opt -xzf $neovim_tarball

	echo <<- EOF >> $HOME/.bashrc
	export PATH=\$PATH:/opt/$neovim_target/bin
	alias vim=nvim
	EOF

	popd >/dev/null

	cp -r nvim_configs/.* $HOME
}

docker_install() {
	sudo apt-get update
	sudo apt-get install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to apt sources:
	echo \
	  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
	  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
	  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
}

wm_install() {
	sudo apt install -y $(sed '/^#/d' < packages.wm.txt)
	cp -r wm_configs/.* $HOME
}


if [[ ! -e $HOME/.cache/dotfiles_install ]]; then
	base_install
	bash_setup
	mkdir -p $HOME/.cache
	touch $HOME/.cache/dotfiles_install
fi

while true; do
	figlet -f slant "Setup"
	cat <<- EOF
	1) Install neovim
	2) Install docker
	3) Install bspwm
	q) Quit
	EOF

	read -p "> "
	case $REPLY in
		1)
			neovim_install
			;;
		2)
			docker_install
			;;
		3)
			wm_install
			;;
		*)
			exit 0
			;;
	esac
done
