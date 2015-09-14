apt_install_pkg() {
  PKG_NAME=$1

  if [ ! -z $PKG_NAME ]; then
    apt-get install -y $PKG_NAME
  fi
}

apt_uninstall_pkg() {
  PKG_NAME=$1

  if [ ! -z $PKG_NAME ]; then
    apt-get remove -y $PKG_NAME
  fi
}
