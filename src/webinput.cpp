#include "webinput.h"

#include <QCoreApplication>
#include <QDebug>
#include <QKeyEvent>
#include <QQuickItem>

WebInput::WebInput(QObject *parent)
    : QObject(parent)
{
}

void WebInput::focusSearch(QQuickItem *webView)
{
    if (!webView || !webView->window() || !webView->isVisible() || !webView->isEnabled()) {
        qWarning() << "Cannot focus Outlook search: the web view is not available";
        return;
    }

    webView->forceActiveFocus(Qt::OtherFocusReason);

    QKeyEvent press(QEvent::KeyPress, Qt::Key_Q, Qt::AltModifier, QStringLiteral("q"));
    QCoreApplication::sendEvent(webView, &press);
    QKeyEvent release(QEvent::KeyRelease, Qt::Key_Q, Qt::AltModifier, QStringLiteral("q"));
    QCoreApplication::sendEvent(webView, &release);
}
