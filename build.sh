#/bin/bash

VERSION="3.0.5"

echo "deb http://in.archive.ubuntu.com/ubuntu/ trusty main" | tee /etc/apt/sources.list.d/trusty.list
apt-get update
apt-get --yes install python-software-properties software-properties-common
add-apt-repository ppa:jonathonf/ffmpeg-3 --yes
add-apt-repository universe --yes
apt-get update
apt-get --yes dist-upgrade
apt-get --yes install libsystemd-dev libarchive-dev curl build-essential autoconf libtool pkg-config patchelf libtasn1-3-dev libtasn1-3-bin libbsd-dev git bison qtbase5-private-dev libqt5svg5-dev automake autopoint gettext cmake wayland-protocols protobuf-compiler libmpg123-dev libgstreamer-plugins-base1.0-dev libsystemd-dev libarchive-dev libopencv-dev

apt-get build-dep vlc --yes

(
  git clone https://github.com/videolabs/libdsm.git
  cd libdsm
  ./bootstrap
  ./configure --prefix=/usr
  make -j$(nproc)
  make -j$(nproc) install
)

(
  git clone https://github.com/sahlberg/libnfs.git
  cd libnfs/
  cmake -DCMAKE_INSTALL_PREFIX=/usr .
  make -j$(nproc)
  make -j$(nproc) install
)

(
  wget http://download.videolan.org/pub/vlc/$VERSION/vlc-$VERSION.tar.xz
  tar xJf vlc-$VERSION.tar.xz
  cd vlc-$VERSION
  ./configure --enable-chromecast=no --prefix=/usr
  make -j$(nproc)
  make -j$(nproc) DESTDIR=$(pwd)/build/ install
  chmod 755 -R ./vlc-$VERSION/build
  cd build
  cp ../../org.videolan.vlc.desktop ./
  cp ./usr/share/icons/hicolor/256x256/apps/vlc.png ./
  mkdir -p ./usr/plugins/iconengines/
  cp /usr/lib/x86_64-linux-gnu/qt5/plugins/iconengines/libqsvgicon.so ./usr/plugins/iconengines/
  mkdir -p ./usr/plugins/platforms/
  cp /usr/lib/x86_64-linux-gnu/qt5/plugins/platforms/libqxcb.so ./usr/plugins/platforms/
  rm usr/lib/vlc/plugins/plugins.dat
  ./vlc-$VERSION/build/usr/lib/vlc/vlc-cache-gen ./vlc-$VERSION/build/usr/lib/vlc/plugins
)

find ./vlc-$VERSION/build/usr/lib/vlc/ -maxdepth 1 -name "lib*.so*" -exec patchelf --set-rpath '$ORIGIN/../' {} \;
find ./vlc-$VERSION/build/usr/lib/vlc/plugins/ -name "lib*.so*" -exec patchelf --set-rpath '$ORIGIN/../../:$ORIGIN/../../../' {} \;

wget "https://github.com/azubieta/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
chmod a+x ./linuxdeployqt-continuous-x86_64.AppImage
LINUX_DEPLOY_QT_EXCLUDE_COPYRIGHTS=true appimage-wrapper linuxdeployqt-continuous-x86_64.AppImage vlc-$VERSION/build/org.videolan.vlc.desktop -bundle-non-qt-libs
LINUX_DEPLOY_QT_EXCLUDE_COPYRIGHTS=true ARCH=x86_64 appimage-wrapper linuxdeployqt-continuous-x86_64.AppImage vlc-$VERSION/build/org.videolan.vlc.desktop -appimage

mkdir -p release

cp ./VLC_media_player*.AppImage release/
md5sum ./VLC_media_player*.AppImage > release/MD5.txt
