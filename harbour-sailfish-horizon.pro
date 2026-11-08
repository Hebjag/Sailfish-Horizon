TARGET = harbour-sailfish-horizon

CONFIG += sailfishapp

QT += dbus

HEADERS += src/notificationmanager.h

SOURCES += src/main.cpp \
    src/notificationmanager.cpp

OTHER_FILES += qml/harbour-sailfish-horizon.qml \
    qml/pages/*.qml \
    qml/cover/*.qml \
    rpm/harbour-sailfish-horizon.spec \
    harbour-sailfish-horizon.desktop \
    systemd/* \
    .github/workflows/* \
    icons/scalable/*.svg

systemd_unit.files = systemd/harbour-sailfish-horizon.service \
                     systemd/harbour-sailfish-horizon.timer
systemd_unit.path = /usr/lib/systemd/user

icon_scalable.files = icons/scalable/harbour-sailfish-horizon.svg
icon_scalable.path = /usr/share/icons/hicolor/scalable/apps

INSTALLS += systemd_unit icon_scalable

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172 256x256
