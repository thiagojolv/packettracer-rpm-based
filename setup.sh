#!/bin/bash
#
# setup.sh - Start the Cisco Packet Tracer installer
#
# Autor: Thiago Jack <thiagoojack@gmail.com>
#
#  ----------------------------------------------------------------
#   This program permits you can Install or Uninstall Cisco Packet
#   Tracer in RPM based systems.
#
#   This program looks for Cisco Packet Tracer installer in the
#   HOME directory and provides the user with a list of installers
#   to choose from and install.


# Initialization of variables

BACKTITLE='Cisco Packet Tracer Installer'
DEF_PACKAGE_MANAGER=0
DEPS=(
  'qt5-qtmultimedia.x86_64'   \
  'qt5-qtwebengine.x86_64'    \
  'qt5-qtnetworkauth.x86_64'  \
  'qt5-qtwebsockets.x86_64'   \
  'qt5-qtwebchannel.x86_64'   \
  'qt5-qtscript.x86_64'       \
  'qt5-qtlocation.x86_64'     \
  'qt5-qtsvg.x86_64'          \
  'qt5-qtspeech'              \
)
INSTALLER_BASENAME=''
IS_RHEL_BASED=0
LOCALIZED_VERSIONS=()
OS_VERSION=`sed -n '/^NAME/p' /etc/os-release |\
            cut -f2 -d '=' |\
            sed 's/"// g'`
PACKAGE_MANAGER=''
PATH_TO_PT=''
PTDIR='/opt/pt'
RHEL_LIKE=(
  'Fedora Linux'              \
  'Red Hat Enterprise Linux'  \
  'CentOS Linux'              \
  'Rocky Linux'               \
  'Alma Linux'                \
)
SUSE=(
  'SUSE Linux'            \
  'OpenSUSE Leap'         \
  'OpenSUSE Tumbleweed'   \
)


# The LOCALIZED_VERSIONS variable will be store a list of installers
# versions localized in HOME direcotory.

# Functions

install() {
  if [ -e /opt/pt ]; then
    echo "Removing old version of Packet Tracer from /opt/pt"
    sudo rm -rf /opt/pt
    sudo rm -rf /usr/share/applications/cisco-pt.desktop
    sudo rm -rf /usr/share/applications/cisco-ptsa.desktop
    sudo rm -rf /usr/share/applications/cisco7-pt.desktop
    sudo rm -rf /usr/share/applications/cisco7-ptsa.desktop
    sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-pt.desktop
    sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-ptsa.desktop
    sudo update-mime-database /usr/share/mime
    sudo gtk-update-icon-cache --force /usr/share/icons/gnome

    sudo rm -f /usr/local/bin/packettracer
  fi

  mkdir packettracer
  echo "Extracting files..."
  sleep 2
  ar -x $PATH_TO_PT --output=packettracer
  tar -xvf packettracer/control.tar.xz --directory=packettracer
  tar -xvf packettracer/data.tar.xz --directory=packettracer

  echo "Copying files..."
  sleep 2
  sudo cp -r packettracer/usr packettracer/opt /
  sudo sed -i 's/packettracer/packettracer --no-sandbox args/' /usr/share/applications/cisco-pt.desktop
  sudo ./packettracer/postinst 

  if [ $IS_RHEL_BASED == 1 ]; then
    echo "Installing dependencies for RHEL based..."
    sleep 1
    sudo dnf install -y epel-release compat-openssl11
  fi

  echo "Installing dependecies..."
  sleep 2
  sudo $PACKAGE_MANAGER install -y "${DEPS[@]}"
  sudo rm -rf packettracer

}

locate_installers() {
  c=1
  for installer in $(sudo find /home -type f -name 'CiscoPacketTracer*'); do
    INSTALLER_BASENAME=`basename $installer`
    version=$(cut -f2 -d "_" <<< $INSTALLER_BASENAME)
    LOCALIZED_VERSIONS[$c]=$version
    LOCALIZED_INSTALLERS[$c]=$installer
    ((c++))
  done
}

remove_old_version() {
  if [ -e /opt/pt ]; then
    echo "Removing old version of Packet Tracer from /opt/pt"
    sudo rm -rf /opt/pt
    sudo rm -rf /usr/share/applications/cisco-pt.desktop
    sudo rm -rf /usr/share/applications/cisco-ptsa.desktop
    sudo rm -rf /usr/share/applications/cisco7-pt.desktop
    sudo rm -rf /usr/share/applications/cisco7-ptsa.desktop
    sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-pt.desktop
    sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-ptsa.desktop
    sudo update-mime-database /usr/share/mime
    sudo gtk-update-icon-cache --force /usr/share/icons/gnome

    sudo rm -f /usr/local/bin/packettracer
  fi
}

show_menu() {
  dialog --stdout \
  --backtitle "$BACKTITLE on $OS_VERSION" \
  --menu 'Select an option:'\
  0 0 0                     \
  $(
    c=1
    for arg in "$@"; do
      echo $c $arg;
      ((c++))
    done
  )
}

uninstall() {
  if [ -e /opt/pt ]; then
    sudo rm -rf /opt/pt
    sudo rm -rf /usr/share/applications/cisco-pt.desktop
    sudo rm -rf /usr/share/applications/cisco-ptsa.desktop
    sudo rm -rf /usr/share/applications/cisco7-pt.desktop
    sudo rm -rf /usr/share/applications/cisco7-ptsa.desktop
    sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-pt.desktop
    sudo xdg-desktop-menu uninstall /usr/share/applications/cisco-ptsa.desktop
    sudo update-mime-database /usr/share/mime
    sudo gtk-update-icon-cache --force /usr/share/icons/gnome

    sudo rm -f /usr/local/bin/packettracer
  fi
}

# Identify Operating System to define package manager
# to be used to install dependencies
for os in "${RHEL_LIKE[@]}"; do
  if [ "$OS_VERSION" == "$os" ]; then
    PACKAGE_MANAGER="dnf"

    if [[ $os == "CentOS Linux" ]] || [[ $os == "Rocky Linux" ]]; then
      IS_RHEL_BASED=1
    fi

  else
    for os in "${SUSE[@]}"; do
      if [ "$OS_VERSION" == "$os" ]; then
        PACKAGE_MANAGER="zypper"
      fi
    done
  fi
done

sudo $PACKAGE_MANAGER install -y dialog

while : ; do

  dialog \
  --backtitle "$BACKTITLE on $OS_VERSION" \
  --msgbox "Welcome to $BACKTITLE!" 6 40
    
  main_menu=`show_menu Install/Upgrade Uninstall`

  [ $? -ne 0 ] && break

  case "$main_menu" in
    1 ) locate_installers
        select_version=`show_menu "${LOCALIZED_INSTALLERS[@]}"`

        [ $? -eq 1 ] && break
        
        PATH_TO_PT="${LOCALIZED_INSTALLERS[$((select_version))]}"

        dialog --backtitle "$BACKTITLE on $OS_VERSION" \
        --yesno "Do you want to install the \
        ${LOCALIZED_VERSIONS[$select_version]} \
        version of Cisco Packet Tracer?" \
        6 60
        
        if [ $? = 0 ]; then
          install       

          dialog --backtitle "$BACKTITLE on $OS_VERSION"\
          --title 'Nice!'\
          --msgbox "Cisco Packet Tracer ${LOCALIZED_VERSIONS[$((select_version))]} was installed." \
          6 40
          break
        fi
      ;;
    2 ) dialog --backtitle "$BACKTITLE on $OS_VERSION" \
        --yesno 'Do you realy want to uninstall Cisco Packet Tracer?'\
        0 0

        if [ $? = 0 ]; then
          uninstall
          dialog --backtitle "$BACKTITLE on $OS_VERSION"\
          --title 'Uninstalled'\
          --msgbox 'Cisco Packet Tracer was uninstalled.' \
          6 40
        fi
        break
      ;;
    0 ) break ;;
  esac
      
done
