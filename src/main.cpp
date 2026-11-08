#include <sailfishapp.h>
#include <QGuiApplication>
#include <QQuickView>
#include <QQmlEngine>
#include <QQmlContext>
#include <QStandardPaths>
#include <QUrl>
#include <QUrlQuery>
#include <QDir>
#include "notificationmanager.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    app->setOrganizationName("harbour-sailfish-horizon");
    app->setApplicationName("harbour-sailfish-horizon");

    QString mailtoDeeplink;
    bool backgroundMode = false;

    for (int i = 1; i < argc; ++i) {
        QString arg = QString::fromLocal8Bit(argv[i]);
        if (arg == QStringLiteral("--background")) {
            backgroundMode = true;
        } else if (arg.startsWith(QStringLiteral("mailto:"), Qt::CaseInsensitive)) {
            QUrl mailtoUrl(arg);
            QUrlQuery query(mailtoUrl);
            QString to = mailtoUrl.path();
            QString subject = query.queryItemValue(QStringLiteral("subject"));
            QString body = query.queryItemValue(QStringLiteral("body"));

            QString deep = QStringLiteral("https://outlook.office.com/mail/deeplink/compose?to=") + QUrl::toPercentEncoding(to);
            if (!subject.isEmpty()) {
                deep += QStringLiteral("&subject=") + QUrl::toPercentEncoding(subject);
            }
            if (!body.isEmpty()) {
                deep += QStringLiteral("&body=") + QUrl::toPercentEncoding(body);
            }
            mailtoDeeplink = deep;
        }
    }

    QScopedPointer<QQuickView> view(SailfishApp::createView());

    // Register DBus NotificationManager
    NotificationManager *notifMgr = new NotificationManager(app.data());
    view->rootContext()->setContextProperty(QStringLiteral("notificationManager"), notifMgr);
    view->rootContext()->setContextProperty(QStringLiteral("initialMailtoUrl"), mailtoDeeplink);
    view->rootContext()->setContextProperty(QStringLiteral("isBackgroundDaemon"), backgroundMode);

    view->setSource(SailfishApp::pathToMainQml());

    if (!backgroundMode) {
        view->show();
    }

    return app->exec();
}
