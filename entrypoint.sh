#!/bin/bash

# Log file for entrypoint operations
LOGFILE="/var/log/entrypoint.log"
exec &> >(tee -a "${LOGFILE}")

echo "======== Starting container ========"

# Create a user
if ! id -u "$USER" &>/dev/null; then
    echo "Creating user $USER..."
    useradd -m -s /bin/bash "$USER"
    echo "$USER:$PASSWORD" | chpasswd
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
else
    echo "User $USER already exists."
fi

# Setup VNC
mkdir -p /home/"$USER"/.vnc

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

# Create VNC service file
cat > /etc/systemd/system/vncserver@.service <<EOF
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=$USER
PAMName=login
PIDFile=/home/$USER/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

# Create .Xauthority file for the user
echo "Creating .Xauthority file for ${USER}"
su - ${USER} -c "touch /home/${USER}/.Xauthority"

echo "Starting VNC server"
su - ${USER} -c "dbus-launch vncserver :1 -geometry 1920x1080 -localhost no"

# Enable VNC and SSH services without starting them immediately
systemctl enable vncserver@:1.service
systemctl enable ssh.service


# Add applications to XFCE panel. Sleep for 5 seconds to allow XFCE to start
sleep 5

# Define the applications to add to the desktop
APPLICATIONS=("google-chrome" "obs" "vlc")

# Ensure the Desktop directory exists
mkdir -p /home/"$USER"/Desktop

for APP in "${APPLICATIONS[@]}"; do
    # Check if the application's .desktop file exists
    if [ -f "/usr/share/applications/${APP}.desktop" ]; then
        # Create a symbolic link to the application's .desktop file on the user's Desktop
        cp "/usr/share/applications/${APP}.desktop" "/home/$USER/Desktop/"
        chmod +x "/home/$USER/Desktop/${APP}.desktop"
    fi
done

# Update ownership of all items on the Desktop
chown -R "$USER":"$USER" /home/"$USER"/Desktop

echo "======== Container setup is complete ========"

# Hand over to the init system
exec /sbin/init
