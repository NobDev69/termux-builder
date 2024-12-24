#!/bin/bash
# Script to build Termux packages with a custom package list and bootstrap file.

# Step 1: Clone the termux-packages repository
echo "[*] Cloning Termux packages repository..."
git clone https://github.com/termux/termux-packages.git || {
    echo "[!] Failed to clone the repository. Exiting."; exit 1;
}

# Step 2: Download and move the build-bootstrap.sh script
echo "[*] Downloading build-bootstrap.sh..."
wget -q -O build-bootstrap.sh \
    https://gist.github.com/seeya/a9ce074cf560aa7113043859360b7bfc/raw/206b5f4755b65569cf4af8d92b2481258c134b74/build-bootstrap.sh

echo "[*] Moving build-bootstrap.sh to scripts folder..."
mv build-bootstrap.sh termux-packages/scripts/

# Step 3: Update properties.sh for custom package name
echo "[*] Updating TERMUX_APP_PACKAGE in properties.sh..."
sed -i 's/^TERMUX_APP_PACKAGE=.*/TERMUX_APP_PACKAGE="com.termux.oneshot"/' \
    termux-packages/scripts/properties.sh

# Step 4: Create the packages.list file
echo "[*] Creating custom packages list..."
cat > termux-packages/packages.list <<EOF
apt
bash-completion
bash
bzip2
ca-certificates
clang
command-not-found
coreutils
curl
dash
debianutils
dialog
diffutils
dos2unix
dpkg
ed
findutils
gawk
gdbm
glib
gpgv
grep
gzip
inetutils
iw
less
libandroid-glob
libandroid-posix-semaphore
libandroid-support
libassuan
libbz2
libc++
libcap-ng
libcompiler-rt
libcrypt
libcurl
libevent
libexpat
libffi
libgcrypt
libgmp
libgnutls
libgpg-error
libiconv
libidn2
libllvm
liblz4
liblzma
libmd
libmpfr
libnettle
libnghttp2
libnghttp3
libnl
libnpth
libsmartcols
libsqlite
libssh2
libtirpc
libunbound
libunistring
libxml2
lld
llvm
lsof
make
nano
ncurses-ui-libs
ncurses
ndk-sysroot
net-tools
oneshot
openssl
patch
pcre2
pcre
pixiewps
pkg-config
procps
psmisc
python-ensurepip-wheels
python-pip
python
readline
resolv-conf
root-repo
sed
tar
termux-am-socket
termux-am
termux-exec
termux-keyring
termux-licenses
termux-tools
tsu
unbound
unzip
util-linux
wpa-supplicant
xxhash
xz-utils
zlib
zstd
EOF

# Step 5: Start Docker environment
echo "[*] Starting Docker environment..."
cd termux-packages || {
    echo "[!] Termux packages directory not found. Exiting."; exit 1;
}
./scripts/run-docker.sh || {
    echo "[!] Failed to start Docker. Exiting."; exit 1;
}

# Step 6: Build custom bootstrap file with additional packages
echo "[*] Building bootstrap for architecture: aarch64..."
./scripts/build-bootstrap.sh --architectures aarch64 || {
    echo "[!] Failed to build bootstrap. Exiting."; exit 1;
}

# Step 7: Verify the bootstrap file
echo "[*] Verifying bootstrap file..."
if [ -f "outputs/bootstrap-aarch64.zip" ]; then
    echo "[*] Bootstrap file generated successfully: outputs/bootstrap-aarch64.zip"
else
    echo "[!] Bootstrap file not found. Check the build process."
    exit 1;
fi

echo "[*] All done! You can now use the bootstrap-aarch64.zip file for your custom Termux build."
