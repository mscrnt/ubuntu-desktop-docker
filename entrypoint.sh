#!/bin/bash

LOGFILE="/var/log/entrypoint.log"

exec &> >(tee -a "${LOGFILE}")

echo "======== Starting container ========"

# Prepare /run and /run/lock without needing --tmpfs flags
mount -t tmpfs tmpfs /run -o mode=755
mkdir -p /run/lock
mount -t tmpfs tmpfs /run/lock -o mode=1777

# Check if user exists and create if not
if ! id -u "${USER}" > /dev/null 2>&1; then
    echo "Creating user ${USER}"
    useradd -m -s /bin/bash "${USER}"
else
    echo "User ${USER} already exists"
fi

# Add user to sudo group
echo "Adding ${USER} to sudo group"
usermod -aG sudo "${USER}"

# Set user password
echo "Setting password for ${USER}"
echo "${USER}:${PASSWORD}" | chpasswd

# Set up VNC password and xstartup file
echo "Setting up VNC for ${USER}"
mkdir -p /home/${USER}/.vnc
echo "${VNCPASSWORD}" | vncpasswd -f > /home/${USER}/.vnc/passwd
chmod 600 /home/${USER}/.vnc/passwd
echo 'exec startxfce4' > /home/${USER}/.vnc/xstartup
chmod 755 /home/${USER}/.vnc/xstartup

# Set Chrome as the default browser
mkdir -p /home/${USER}/.local/share/applications
echo -e '[Default Applications]\nx-scheme-handler/http=google-chrome.desktop\nx-scheme-handler/https=google-chrome.desktop\napplication/xhtml+xml=google-chrome.desktop\napplication/xml=google-chrome.desktop\ntext/html=google-chrome.desktop' > /home/${USER}/.local/share/applications/mimeapps.list
chown ${USER}:${USER} /home/${USER}/.local/share/applications/mimeapps.list

# Set proper ownership for user's home directory
echo "Setting ownership for ${USER} home directory"
chown -R ${USER}:${USER} /home/${USER}

# Create .Xauthority file for the user
echo "Creating .Xauthority file for ${USER}"
su - ${USER} -c "touch /home/${USER}/.Xauthority"

# Set default applications for the user
echo "Updating XFCE panel launchers"
su - ${USER} -c "mkdir -p /home/${USER}/.config/xfce4/panel"
su - ${USER} -c "echo '[Encoding=UTF-8]' > /home/${USER}/.config/xfce4/panel/launcher-1.rc"
su - ${USER} -c "echo 'Name=Terminal' >> /home/${USER}/.config/xfce4/panel/launcher-1.rc"
su - ${USER} -c "echo 'Icon=utilities-terminal' >> /home/${USER}/.config/xfce4/panel/launcher-1.rc"
su - ${USER} -c "echo 'Exec=xfce4-terminal' >> /home/${USER}/.config/xfce4/panel/launcher-1.rc"

# Start services using systemctl
echo "Starting SSH server"
systemctl start sshd.service

# Start x2go if enabled
if [ "$ENABLE_X2GO" = "true" ]; then
    echo "Starting x2go server"
    systemctl start x2goserver.service
fi

# Start VNC server if enabled
if [ "$ENABLE_VNC" = "true" ]; then
    echo "Starting VNC server"
    systemctl start vncserver@:1.service
fi

# Start xrdp server
if [ "$ENABLE_XRDP" = "true" ]; then
    echo "Starting xrdp server"
    systemctl start xrdp.service
fi


echo "======== Container started ========"

# Keep the container running in the foreground
exec /sbin/init
