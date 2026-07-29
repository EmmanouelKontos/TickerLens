#include "AppSettings.h"
#include "PlatformUtils.h"
#include "UpdateInstaller.h"

#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QStyle>

static void ensureHelperScripts()
{
    const QString cfg = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(cfg);
    const QString dst = QDir(cfg).filePath(QStringLiteral("rate_news.py"));
    if (QFile::exists(dst))
        return;
    // Try application directory
    const QString srcApp = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("rate_news.py"));
    if (QFile::exists(srcApp))
        QFile::copy(srcApp, dst);
}

int main(int argc, char *argv[])
{
    QGuiApplication::setOrganizationName(QStringLiteral("TickerLens"));
    QGuiApplication::setOrganizationDomain(QStringLiteral("tickerlens.app"));
    QGuiApplication::setApplicationName(QStringLiteral("TickerLens"));
    QGuiApplication::setApplicationVersion(QStringLiteral("1.6.1"));

    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    ensureHelperScripts();

    AppSettings settings;
    PlatformUtils platform;
    UpdateInstaller updater;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("AppSettings"), &settings);
    engine.rootContext()->setContextProperty(QStringLiteral("Platform"), &platform);
    engine.rootContext()->setContextProperty(QStringLiteral("UpdateInstaller"), &updater);

    const QUrl url(QStringLiteral("qrc:/qml/App.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    // System tray (Windows 11 / desktop)
    QSystemTrayIcon tray;
    tray.setToolTip(QStringLiteral("TickerLens"));
    tray.setIcon(app.windowIcon().isNull()
                     ? QIcon::fromTheme(QStringLiteral("office-chart-line"),
                                        app.style()->standardIcon(QStyle::SP_ComputerIcon))
                     : app.windowIcon());

    QMenu trayMenu;
    QAction *actStock = trayMenu.addAction(QStringLiteral("Show / Hide Markets"));
    QAction *actNews = trayMenu.addAction(QStringLiteral("Show / Hide News"));
    trayMenu.addSeparator();
    QAction *actQuit = trayMenu.addAction(QStringLiteral("Quit"));
    tray.setContextMenu(&trayMenu);
    tray.show();

    QObject *root = engine.rootObjects().isEmpty() ? nullptr : engine.rootObjects().constFirst();
    if (root) {
        QObject::connect(actStock, &QAction::triggered, root, [root]() {
            QMetaObject::invokeMethod(root, "toggleStock");
        });
        QObject::connect(actNews, &QAction::triggered, root, [root]() {
            QMetaObject::invokeMethod(root, "toggleNews");
        });
        QObject::connect(actQuit, &QAction::triggered, &app, &QCoreApplication::quit);
        QObject::connect(&tray, &QSystemTrayIcon::activated, root, [root](QSystemTrayIcon::ActivationReason r) {
            if (r == QSystemTrayIcon::Trigger || r == QSystemTrayIcon::DoubleClick)
                QMetaObject::invokeMethod(root, "toggleStock");
        });
    }

    return app.exec();
}
