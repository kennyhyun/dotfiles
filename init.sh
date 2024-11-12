#!/usr/bin/env bash
if [ "$PRODUCTION" ]; then
  skip_devtools=1
fi

set -e

pushd ~

mkdir -p Projects
mkdir -p Downloads

case $(uname -s) in
Linux)
  ~/dotfiles/scripts/linux.sh
  ;;
esac

# pip packages
pipx install "awscli<2"
export PATH=$PATH:~/.local/bin


if [ -n "$(delta --version)" ]; then
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.side-by-side true
  git config --global merge.conflictstyle zdiff3
else
  # Build git diff-highlight and set as pager
  diff_highlight_dir=`find /usr -name '*diff-highlight' -type d 2>&1 | grep -v "Permission denied"|tail -1`
  echo diff_highlight_dir: $diff_highlight_dir
  if ! [ -z "$diff_highlight_dir" ]; then
    echo Setting up $diff_highlight_dir
    pushd $diff_highlight_dir
    sudo make
    git config --global core.pager "$diff_highlight_dir/diff-highlight | less -F -X"
    git config --global interactive.diffFilter "$diff_highlight_dir/diff-highlight"
    popd
  fi

fi

# zshrc
if [ -z "$(grep "$HOME/dotfiles/.zshrc" ~/.zshrc)" ]; then
  # add source to zshrc
  echo "source $HOME/dotfiles/.zshrc" >> ~/.zshrc
fi

# Node.js with NVM
latest_nvm_version=$(curl -o- https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r .name)
curl -o- https://raw.githubusercontent.com/creationix/nvm/$latest_nvm_version/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 20

# tmux
ln -sf dotfiles/.tmux.conf .tmux.conf
if ! [ -d ~/.tmux/plugins/tpm ]; then
  mkdir -p ~/.tmux/plugins
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

npm i -g yarn cross-env pino-pretty

######## Dev Tools ##########
if [ -z "$skip_devtools" ]; then

npm i -g prettier #@1.18

#ohmyzsh
echo
echo -----------------------------
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh) --unattended" || echo ""
echo "Setting the default shell to $(which zsh)"
sudo chsh -s $(which zsh) $USER

# -- Vim
mkdir -p ~/dotfiles/.vim/swapfiles
if [ -d ~/.vim ]; then mv ~/.vim ~/.vim.org; fi
ln -sf dotfiles/.vim .vim
ln -sf dotfiles/.vimrc .vimrc

## dein.vim
pushd dotfiles
if ! [ -d .vim/dein/repos/github.com/Shougo/dein.vim/.git ]; then
  mkdir -p .vim/dein/repos
  git clone https://github.com/Shougo/dein.vim .vim/dein/repos/github.com/Shougo/dein.vim
fi
popd

# fzf
if ! [ -d dotfiles/.fzf ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git dotfiles/.fzf
  ln -sf dotfiles/.fzf
  ~/.fzf/install --all
fi

# deno
if ! [ -d "$HOME/.deno" ]; then
  deno_install=$(curl -fsSL https://deno.land/x/install/install.sh || exit -1)
  $SHELL -c $deno_install
fi

set +e
name=$(git config --global user.name)
if [ -z "$name" ]; then name=$USER; fi
email=$(git config --global user.email)
set -e
echo
echo -----------------------------
if [ -t 1 ] ; then
  # interactive (in terminal)
  echo "Hello $name, setting up the gitconfig. Please input the name for git committing [$name]"
  read name_input
  if [ "$name_input" ]; then echo "Hello, ${name_input}."; fi
  echo "Please input the email for committing [$email]"
  read email_input
  if [ "$name_input" ]; then name=$name_input; fi
  if [ "$email_input" ]; then email=$email_input; fi
  echo "Setting up $name<$email>"
  git config --replace-all --global user.name "$name"
  git config --replace-all --global user.email "$email"
else
  if [ -z "$name" ] || [ -z "$email" ]; then
    echo "Please don't forget to set git username and email for committing
git config --global user.name <User Name>
git config --global user.email <Email Address>"
  fi
fi

fi
##### Dev tools end ######

## generate id_rsa
if [ -f "$HOME/.ssh/id_rsa" ]; then
  echo "-----
ssh key aleady exists"
else
  echo "-----
Generating ssh key"
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""
fi

# id_rsa_bastion
if ! [ -f "$HOME/.ssh/id_rsa_bastion" ]; then
  if [ -f "$HOME/.ssh/id_rsa" ]; then
    cp ~/.ssh/id_rsa ~/.ssh/id_rsa_bastion
  else
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa_bastion -q -N ""
  fi
fi

# gitconfig
if [ -z "$(grep "$HOME/dotfiles/.gitconfig" ~/.gitconfig)" ]; then
  git config --add --global include.path  ~/dotfiles/.gitconfig
fi
git config --global core.excludesfile ~/dotfiles/.gitignore_global

## configure aws credentials
if [ "$(grep default "$HOME/.aws/credentials" || echo "")" ]; then
  echo "-----
Found default AWS configuration"
else
  echo "-----
Please visit https://console.aws.amazon.com/iam/home?#/security_credentials and prepare the Access Key"
  if [ -t 1 ] ; then
    echo "Configuring AWS credentials"
    # interactive (in terminal)
    aws configure
  else
    echo "Please don't forget to run \`aws configure\`"
  fi
fi
if [ -z "$skip_devtools" ]; then
  if [ "$(grep uat "$HOME/.aws/credentials" || echo "")" ]; then
    echo "-----
  Found uat AWS configuration"
  else
    echo "-----
  Please visit https://console.aws.amazon.com/iam/home?#/security_credentials as UAT ACCOUNT and prepare the Access Key"
    if [ -t 1 ] ; then
      echo "Configuring AWS credentials"
      # interactive (in terminal)
      aws configure --profile uat
    else
      echo "Please don't forget to run \`aws configure\`"
    fi
  fi
fi

echo ---------------------
echo "Don't forget to paste the public key below into Github or Gitlab where required"
echo ---------------------
cat ~/.ssh/id_rsa.pub
echo ---------------------

echo "
----------------------------
Finished to initiate dotfiles, you can run this again if required.
Please log off and log in again, Thanks!!
-----------------------------"

popd
