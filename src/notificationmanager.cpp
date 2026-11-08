#include "notificationmanager.h"
#include <QDBusMessage>
#include <QDBusConnection>

NotificationManager::NotificationManager(QObject *parent)
    : QObject(parent),
      m_dBusInterface(new QDBusInterface(
          QStringLiteral("org.freedesktop.Notifications"),
          QStringLiteral("/org/freedesktop/Notifications"),
          QStringLiteral("org.freedesktop.Notifications"),
          QDBusConnection::sessionBus(),
          this))
{
}

uint NotificationManager::sendNotification(const QString &summary, const QString &body, const QString &category)
{
    if (!m_dBusInterface || !m_dBusInterface->isValid()) {
        qWarning() << "DBus Notification interface is not valid";
        return 0;
    }

    const QString appName = QStringLiteral("Outlook 365");
    const uint replacesId = 0;
    const QString icon = QStringLiteral("/usr/share/icons/hicolor/86x86/apps/harbour-sailfish-horizon.png");
    const QStringList actions;
    
    QVariantMap hints;
    hints.insert(QStringLiteral("category"), category.isEmpty() ? QStringLiteral("email") : category);
    hints.insert(QStringLiteral("x-nemo-preview-summary"), summary);
    hints.insert(QStringLiteral("x-nemo-preview-body"), body);
    hints.insert(QStringLiteral("x-nemo-icon"), icon);
    // Trigger Sailfish OS email sound & haptics
    hints.insert(QStringLiteral("x-nemo-feedback"), QStringLiteral("email_exists"));
    hints.insert(QStringLiteral("urgency"), 1); // Normal priority

    const int expireTimeout = 5000; // 5 seconds display timeout

    QDBusReply<uint> reply = m_dBusInterface->call(
        QStringLiteral("Notify"),
        appName,
        replacesId,
        icon,
        summary,
        body,
        actions,
        hints,
        expireTimeout
    );

    if (reply.isValid()) {
        qDebug() << "Sent Sailfish DBus notification ID:" << reply.value();
        return reply.value();
    } else {
        qWarning() << "Failed to send DBus notification:" << reply.error().message();
        return 0;
    }
}

void NotificationManager::closeNotification(uint id)
{
    if (m_dBusInterface && m_dBusInterface->isValid() && id > 0) {
        m_dBusInterface->call(QStringLiteral("CloseNotification"), id);
    }
}
