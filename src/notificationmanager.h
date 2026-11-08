#ifndef NOTIFICATIONMANAGER_H
#define NOTIFICATIONMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusReply>
#include <QDebug>

class NotificationManager : public QObject
{
    Q_OBJECT

public:
    explicit NotificationManager(QObject *parent = nullptr);

    Q_INVOKABLE uint sendNotification(const QString &summary, const QString &body, const QString &category = "email");
    Q_INVOKABLE void closeNotification(uint id);

private:
    QDBusInterface *m_dBusInterface;
};

#endif // NOTIFICATIONMANAGER_H
