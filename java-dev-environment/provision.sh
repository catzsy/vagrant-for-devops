#!/bin/bash

VAGRANT_DIR=/vagrant
HOME_DIR=~/
HOME_BIN_DIR=$HOME_DIR/bin

installPackage()
{
  local packages=$*
  echo "Installing $packages"
  sudo apt-get install -y $packages >/dev/null 2>&1
}

indent() 
{
  echo -n '    '
}

downloadWithProgress()
{
  local url=$2
  local file=$1
  echo -n "Downloading $file:"
  echo -n "    "
  wget --progress=dot $url 2>&1 | grep --line-buffered "%" | sed -u -e 's/\.//g' | awk '{printf("\b\b\b\b%4s", $2)}'
  echo -ne "\b\b\b\b"
  echo " DONE"
}

download()
{
  local url=$2
  local file=$1
  echo "Downloading $file"
  wget --progress=dot $url >/dev/null 2>&1
}

installMysql() 
{
  #setting non-interactive mode
  echo mysql-server mysql-server/root_password password root | sudo debconf-set-selections
  echo mysql-server mysql-server/root_password_again password root | sudo debconf-set-selections
  indent; installPackage mysql-server
  indent; indent; echo 'Creating /etc/mysql/conf.d/utf8_charset.cnf'
  sudo cp $VAGRANT_DIR/mysql/utf8_charset.cnf /etc/mysql/conf.d/utf8_charset.cnf
  indent; indent; echo 'Restarting mysql'
  sudo service mysql restart >/dev/null 2>&1
}

installPackages()
{
  echo "Installing packages"
  indent; echo 'apt-get update'
  sudo apt-get update >/dev/null 2>&1
  indent; echo 'apt-get upgrade'
  sudo apt-get upgrade >/dev/null 2>&1

  indent; installPackage vim
  indent; installPackage git
  indent; installPackage mc
  indent; installPackage software-properties-common htop

  #dependencies for pyenv
  indent; installPackage make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev
  #dependencies for rbenv
  indent; installPackage autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev
  indent; installPackage apg
  installMysql
}

createDirs()
{
  echo 'Creating directories'
  indent; echo 'Creating bin directory'
  mkdir $HOME_BIN_DIR
}

installJdks()
{
  echo 'Install phyton-software-properties first to enable add-apt-repository'
  installPackage python-software-properties
  echo 'Installing jdks'
  sudo add-apt-repository ppa:webupd8team/java
  
  sudo apt-get -y -q update
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
  installPackage oracle-java8-installer
  sudo apt-get install oracle-java8-set-default
  #sudo update-java-alternatives -s java-8-oracle

}

installEnvManagers()
{
  indent; echo 'Installing nodenv'
  indent; indent; echo 'Clonning from github to ~/.nodenv'
  git clone https://github.com/OiNutter/nodenv.git ~/.nodenv >/dev/null 2>&1
  indent; indent; echo 'Installing plugins that provide nodenv install'
  git clone https://github.com/OiNutter/node-build.git ~/.nodenv/plugins/node-build >/dev/null 2>&1
  indent; indent; echo "Setting environment variables"
  export PATH="$HOME/.nodenv/bin:$PATH"
  eval "$(nodenv init -)"
}

updateBashrc()
{
  echo 'Updating .bashrc'
  cat $VAGRANT_DIR/bashrc.template >> $HOME_DIR/.bashrc
  source $HOME_DIR/.bashrc
}


installRuntimes()
{
  indent; echo 'Install node.js'
  nodenv install 4.2.1 >/dev/null 2>&1
  nodenv global 4.2.1
}


installingApp()
{
  local tool_name=$1
  local file=$2
  local url=$3
  local link_src=$4
  local link_target=$5
  echo "Installing $tool_name"
  indent; download $file $url
  indent; echo -n "Extracting $file"
  if [[ "$file" =~ .*tar.gz$ || "$file" =~ .*tgz$ ]]
  then 
    echo " using tar"
    tar xvzf $file >/dev/null 2>&1
  else
    if [[ "$file" =~ .*zip$ ]]
    then
      echo " using unzip"
      unzip $file >/dev/null 2>&1
    else
      echo
      indent; indent; echo "Can't extract $file. Unknown ext"
    fi
  fi
  indent; echo 'Cleaning'
  rm $file
  indent; echo "Creating symbolic link $link_target"
  ln -s $link_src $link_target
}

installingMvn()
{
  installingApp 'apache-maven' \
    apache-maven-3.3.9-bin.tar.gz \
    http://mirror.rise.ph/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
    'apache-maven*' \
    apache-maven
}

installingTools() 
{
  cd $HOME_BIN_DIR
  installingMvn
}

run() {
  createDirs
  installPackages
  cd $HOME_BIN_DIR  
  installJdks
  installingTools
  installEnvManagers
  updateBashrc
  installRuntimes
}


if [ ! -f "/var/vagrant_provision" ]; then
  sudo touch /var/vagrant_provision
  run
else
  echo "Nothing to do"
fi

