#ifndef WEBINPUT_H
#define WEBINPUT_H

#include <QObject>

class QQuickItem;

class WebInput : public QObject
{
    Q_OBJECT

public:
    explicit WebInput(QObject *parent = nullptr);

    Q_INVOKABLE void focusSearch(QQuickItem *webView);
};

#endif // WEBINPUT_H
