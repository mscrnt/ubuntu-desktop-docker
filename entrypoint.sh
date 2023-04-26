#!/bin/bash

LOGFILE="/var/log/entrypoint.log"

exec &> >(tee -a "${LOGFILE}")

echo "======== Starting container ========"

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

# Set proper ownership for user's home directory
echo "Setting ownership for ${USER} home directory"
chown -R ${USER}:${USER} /home/${USER}

# Create .Xauthority file for the user
echo "Creating .Xauthority file for ${USER}"
su - ${USER} -c "touch /home/${USER}/.Xauthority"

# Set default applications for the user
# Update XFCE panel launchers
echo "Updating XFCE panel launchers"
su - ${USER} -c "mkdir -p /home/${USER}/.config/xfce4/panel"
su - ${USER} -c "echo '[Encoding=UTF-8]' > /home/${USER}/.config/xfce4/panel/launcher-1.rc"
su - ${USER} -c "echo 'Name=Terminal' >> /home/${USER}/.config/xfce4/panel/launcher-1.rc"
su - ${USER} -c "echo 'Icon=utilities-terminal' >> /home/${USER}/.config/xfce4/panel/launcher-1.rc"
su - ${USER} -c "echo 'Exec=xfce4-terminal' >> /home/${USER}/.config/xfce4/panel/launcher-1.rc"

su - ${USER} -c "echo '[Encoding=UTF-8]' > /home/${USER}/.config/xfce4/panel/launcher-2.rc"
su - ${USER} -c "echo 'Name=Web Browser' >> /home/${USER}/.config/xfce4/panel/launcher-2.rc"
su - ${USER} -c "echo 'Icon=web-browser' >> /home/${USER}/.config/xfce4/panel/launcher-2.rc"
su - ${USER} -c "echo 'Exec=firefox' >> /home/${USER}/.config/xfce4/panel/launcher-2.rc"

# Start SSH, VNC, and xrdp
echo "Starting SSH server"
service ssh start

echo "Starting VNC server"
su - ${USER} -c "dbus-launch vncserver :1 -geometry 1920x1080 -localhost no"

echo "Starting xrdp server"
service xrdp start

echo "======== Container started ========"

# Keep the container running in the foreground
tail -f /dev/null
