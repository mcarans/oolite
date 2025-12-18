# --- 1. Global Setup & OS Detection ---
# We detect the OS once at the start to avoid repeating it.

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_FAMILY="${ID} ${ID_LIKE}"
else
    echo "❌ /etc/os-release not found. Cannot detect OS." >&2
    exit 1
fi

if [ -z "${SUDO_COMMAND+set}" ]; then
    if [ "$(id -u)" -eq 0 ]; then
        echo "Running as root - no need for sudo"
        SUDO_CMD = ""
    else
        echo "Not running as root - will sudo when needed"
        SUDO_CMD = "sudo"
    fi
fi

# Determine the Installer Command based on the family
if [[ "$OS_FAMILY" == *"debian"* ]]; then
    # Debian, Ubuntu, Kali, Mint, Pop!_OS
    CURRENT_DISTRO="debian"
    INSTALL_CMD=($SUDO_CMD apt-get install -y)
    UPDATE_CMD=($SUDO_CMD sudo apt-get update)

elif [[ "$OS_FAMILY" == *"fedora"* || "$OS_FAMILY" == *"rhel"* ]]; then
    # Fedora, CentOS, RHEL, AlmaLinux
    CURRENT_DISTRO="redhat"
    INSTALL_CMD=($SUDO_CMD dnf install -y)
    UPDATE_CMD=($SUDO_CMD dnf check-update) # Returns exit code 100 if updates exist, catch that later

elif [[ "$OS_FAMILY" == *"arch"* ]]; then
    # Arch, Manjaro, EndeavourOS
    CURRENT_DISTRO="arch"
    INSTALL_CMD=($SUDO_CMD pacman -S --noconfirm --needed)
    UPDATE_CMD=($SUDO_CMD pacman -Syu)

else
    echo "❌ Unsupported distribution detected." >&2
    exit 1
fi

echo "Detected System: $CURRENT_DISTRO"

