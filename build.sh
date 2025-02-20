#!/bin/bash
# hello 
# Script to build Termux packages with a custom package list and bootstrap file.

# Telegram Variables (set these in your GitHub Actions workflow or environment variables)
token="${TOKEN}"
chat_id="${CHAT_ID}"

# Function to send Telegram messages
function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
}

# Function to send Telegram documents
function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
}

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
chmod +x termux-packages/scripts/build-bootstrap.sh # Fix: Ensure it is executable

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
# Add more packages here as needed
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
    echo "[!] Failed to build bootstrap. Exiting.";
    post_msg "Error: Failed to build bootstrap. Exiting."
    exit 1;
}

# Step 7: Verify the bootstrap file
echo "[*] Verifying bootstrap file..."
if [ -f "outputs/bootstrap-aarch64.zip" ]; then
    echo "[*] Bootstrap file generated successfully: outputs/bootstrap-aarch64.zip"
    post_msg "Bootstrap file successfully built: bootstrap-aarch64.zip"
    push "outputs/bootstrap-aarch64.zip" "Here is the generated bootstrap-aarch64.zip."
else
    echo "[!] Bootstrap file not found. Check the build process."
    post_msg "Error: Bootstrap file not found. Build failed."
    exit 1;
fi

echo "[*] All done! You can now use the bootstrap-aarch64.zip file for your custom Termux build."
