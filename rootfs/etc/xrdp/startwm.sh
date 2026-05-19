#!/bin/sh
# Custom xrdp session start: launch XFCE under dbus.
if [ -r /etc/default/locale ]; then
    . /etc/default/locale
    export LANG LANGUAGE
fi

unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR

exec dbus-launch --exit-with-session startxfce4
