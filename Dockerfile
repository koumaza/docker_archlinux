FROM archlinux

USER  root
SHELL ["bash","-c"]
RUN   echo -e 'Build date: '$(date) > /etc/image_version

ENV aur_packages='base base-devel yay-git pkgfile \
    bash bash-completion-git zsh-git fish-git tmux-git neofetch-git tmate \
    w3m vim-git neovim-git vim-edge-git neovim-edge-git less procps-ng p7zip p7zip-zstd-codec zstd zip unzip aria2-git wget \
    ninja-git cmake-git pod2man \
    openssl autogen podman podman-compose-git podman-docker jdk-adoptopenjdk \
    kotlin-native-bin perl-test-harness perl-extutils-makemaker-aur \
    dotnet-sdk-preview \
    github-cli-git fzf-git keybase-bin rar ttf-ms-fonts'

### Will Override to Conflicts Packages
ENV aur_second_packages='wget-git curl-git openssh-git zlib-git docker-git docker-compose-git llvm-git gcc-git powershell-git act-git go-git gcc-objc-git'

### Don't Choice of Provide Package
ENV aur_third_packages='android-platform git rakudo'

### Fish's Plugin Manager
ENV fisher_plugin='jethrokuan/fzf edc/bass jethrokuan/z 0rax/fish-bd sijad/gitignore oh-my-fish/plugin-rvm'

# User
RUN useradd ww -md /ww \
&&  echo 'ww ALL=NOPASSWD:ALL'>>/etc/sudoers
# Pacman
RUN	curl -Ls https://raw.githubusercontent.com/koumaza/docker_archlinux/master/pacman.conf|sed 's/\r//g' > /etc/pacman.conf \
&&	pacman -Syyuu --quiet --needed --noconfirm base base-devel go git ed \
# Yay
&&	su ww -c "cd ~/ && \
            git clone --depth=1 --single-branch https://aur.archlinux.org/yay-git.git yay-git/ && \
            cd yay-git/ && \
            yes|makepkg -si" && \
            cd \
&&	su ww -c "cd ~/ && \
            gpg --keyserver keys.gnupg.net --recv-keys 702353E0F7E48EDB && \
            yay -Syy --quiet --color=always --devel --timeupdate --nopgpfetch --needed --noconfirm --mflags --skipinteg $(echo ${aur_packages}|tr ' ' ' ') && \
            yes|yay -Syy --quiet --color=always --devel --timeupdate --nopgpfetch --needed --mflags --skipinteg  $(echo ${aur_second_packages}|tr ' ' ' ') && \
            yay -Syy --quiet --color=always --devel --timeupdate --nopgpfetch --needed --noconfirm --mflags --skipinteg $(echo ${aur_third_packages}|tr ' ' ' ') && \
            yes|yay -Scccc --quiet" && \
            cd \
# BlackArch
&&  curl -O https://blackarch.org/strap.sh && echo 9c15f5d3d6f3f8ad63a6927ba78ed54f1a52176b strap.sh | sha1sum -c && \
    chmod +x strap.sh && ./strap.sh && \
    pacman -Syyu --quiet --needed --noconfirm && pacman -S --quiet --noconfirm blackman
    
#~ Run At User ~#
USER  ww

# Python
## Pyenv
RUN cd ~/ && \
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv && \
    git clone https://github.com/momo-lab/xxenv-latest.git ~/.pyenv/plugins/xxenv-latest && \
    export PYENV_ROOT="$HOME/.pyenv" && export PATH="$PYENV_ROOT/bin:$PATH" && eval "$(pyenv init -)" && \
    pyenv latest install && pyenv latest global \
## Pipenv
&&  cd ~/ && \
    pip install --user pipx --dev && \
    python3 -m pipx install pipeenv
# Ruby
## Rvm
RUN cd ~/ && \
    curl -sSL https://get.rvm.io | bash -s -- --trace --ignore-dotfiles && \
    source $HOME/.rvm/scripts/rvm && \
    rvm get master
# Node
## Nodenv
RUN cd ~/ && \
    git clone https://github.com/nodenv/nodenv.git ~/.nodenv && \
    cd ~/.nodenv && src/configure && make -C src && \
    mkdir -p ~/.nodenv/plugins && \
    git clone https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build && \
    git clone https://github.com/momo-lab/xxenv-latest.git ~/.nodenv/plugins/xxenv-latest && \
    export PATH="$HOME/.nodenv/bin:$PATH" && ~/.nodenv/bin/nodenv init && \
    nodenv latest install && nodenv latest global \
### Pnpm
&&  cd ~/ && \
    export PATH="$HOME/.nodenv/bin:$PATH" && ~/.nodenv/bin/nodenv init && \
    npm install -g pnpm \
### Yarn
&&  cd ~/ && \
    curl -Ls https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --import && \
    yarn_ver=$(curl -sL https://nightly.yarnpkg.com/latest-tar-version) && \
    aria2c -x16 -s20 -qtrue -oyarn.tar.gz https://nightly.yarnpkg.com/yarn-v${yarn_ver}.tar.gz && \
    aria2c -x16 -s20 -qtrue -oyarn.tar.gz.asc https://nightly.yarnpkg.com/latest.tar.gz.asc && \
    gpg --verify yarn.tar.gz.asc||! echo '[CRIICAL] GPG Verify is Not Valid' ;\
    if [ ! $? = 0 ];then exit 1; fi && \
    rm yarn.tar.gz.asc && \
    tar -axvf yarn.tar.gz && \
    mv yarn-v${yarn_ver}/ ~/.yarn/
# Deno
## Dvm
### Alias become `denovm`
RUN cd ~/ && \
    target="x86_64-unknown-linux-gnu" && \
    mkdir -p ~/.denovm && cd ~/.denovm && \
    aria2c -x16 -s20 -qtrue -odvm-${target}.zip https://cdn.jsdelivr.net/gh/justjavac/dvm_releases/dvm-${target}.zip && \
    7z x dvm-${target}.zip && rm dvm-${target}.zip && \
    mv dvm denovm
# Go
## Goenv
RUN cd ~/ && \
    git clone https://github.com/syndbg/goenv.git ~/.goenv && \
    git clone https://github.com/momo-lab/xxenv-latest.git ~/.goenv/plugins/xxenv-latest && \
    export GOPATH="$HOME/go" && export GOENV_ROOT="$HOME/.goenv" && export PATH="$GOENV_ROOT/bin:$PATH" && eval "$(goenv init -)" && export PATH="$GOROOT/bin:$PATH" && export PATH="$PATH:$GOPATH/bin" && \
    goenv latest install && goenv latest global
# Java
## Jenv
RUN cd ~/ && \
    git clone https://github.com/jenv/jenv.git ~/.jenv && \
    ln -s ~/.jenv/fish/jenv.fish ~/.config/fish/functions/jenv.fish && \
    ln -s ~/.jenv/fish/export.fish ~/.config/fish/functions/export.fish
# Php
## Phpenv
RUN cd ~/ && \
    git clone git://github.com/phpenv/phpenv.git ~/.phpenv && \
    git clone https://github.com/php-build/php-build ~/.phpenv/plugins/php-build && \
    git clone https://github.com/momo-lab/xxenv-latest.git ~/.phpenv/plugins/xxenv-latest && \
    export PATH="$HOME/.phpenv/bin:$PATH" && eval "$(phpenv init -)" && \
    phpenv latest install && phpenv latest global
# Dart
## Dvm
RUN cd ~/ && \
    git clone https://github.com/cbracken/dvm.git ~/.dvm
# Rust
## Rustup
RUN cd ~/ && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y --quiet --default-toolchain nightly --profile default
# Perl
## Plenv
RUN cd ~/ && \
    git clone https://github.com/tokuhirom/plenv.git ~/.plenv && \
    git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
# Other Tools
## Powerline-go and Ghq
RUN cd ~/ && \
    export GOPATH="$HOME/go" && \
    go get -u github.com/justjanne/powerline-go && \
    go get github.com/x-motemen/ghq
# Dot Files
RUN cd ~/ && \
    koumaza_temp_dir=$(mktemp -d) && cd $koumaza_temp_dir && \
    git clone https://github.com/koumaza/dot --depth=1 dot && \
    cd dot/codespace/archlinux && \
    cp -rf $(ls -A|tr '\n' ' ') ~/ && \
    rm -rf $koumaza_temp_dir

# Fish
SHELL ["fish","-c"]
RUN  cd ~/ && \
     curl git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish && \
     fisher add (echo $fisher_plugin|tr ' ' ' ') && \
     cd ~/
