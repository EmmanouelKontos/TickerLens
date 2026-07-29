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
#include <QMessageBox>
#include <QDateTime>
#include <QTextStream>
#include <QSharedMemory>
#include <QLocalServer>
#include <QLocalSocket>
#include <QTimer>

static const char *kIpcName = "TickerLens-ipc-v1";
static const char *kLockName = "TickerLens-single-instance-v1";

static QString logPath()
{
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
    QDir().mkpath(dir);
    return QDir(dir).filePath(QStringLiteral("tickerlens.log"));
}

static void logLine(const QString &line)
{
    QFile f(logPath());
    if (!f.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
        return;
    QTextStream ts(&f);
    ts << QDateTime::currentDateTime().toString(Qt::ISODate) << "  " << line << "\n";
}

static void ensureHelperScripts()
{
    const QString cfg = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(cfg);
    const QString dst = QDir(cfg).filePath(QStringLiteral("rate_news.py"));
    if (QFile::exists(dst))
        return;
    const QString srcApp = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("rate_news.py"));
    if (QFile::exists(srcApp))
        QFile::copy(srcApp, dst);
}

// Notify the already-running instance to raise its windows.
static bool activateExistingInstance()
{
    QLocalSocket sock;
    sock.connectToServer(QString::fromLatin1(kIpcName));
    if (!sock.waitForConnected(800))
        return false;
    sock.write("raise\n");
    sock.flush();
    sock.waitForBytesWritten(500);
    sock.disconnectFromServer();
    return true;
}

int main(int argc, char *argv[])
{
    QGuiApplication::setOrganizationName(QStringLiteral("TickerLens"));
    QGuiApplication::setOrganizationDomain(QStringLiteral("tickerlens.app"));
    QGuiApplication::setApplicationName(QStringLiteral("TickerLens"));
    QGuiApplication::setApplicationVersion(QStringLiteral("1.6.3"));

    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    // ── Single instance ─────────────────────────────────────────────────
    // QSharedMemory lock: create() fails if another process holds the key.
    static QSharedMemory instanceLock(QString::fromLatin1(kLockName));
    if (!instanceLock.create(1)) {
        // Another instance is alive (or a crash left a stale lock — try activate)
        if (activateExistingInstance()) {
            logLine(QStringLiteral("second instance: activated existing and exiting"));
            return 0;
        }
        // Stale lock after crash: attach+detach then recreate
        if (instanceLock.attach())
            instanceLock.detach();
        if (!instanceLock.create(1)) {
            // Still can't create — try activate once more
            activateExistingInstance();
            logLine(QStringLiteral("second instance: could not take lock, exiting"));
            return 0;
        }
    }

    logLine(QStringLiteral("start v%1 dir=%2")
                .arg(QCoreApplication::applicationVersion(),
                     QCoreApplication::applicationDirPath()));

    const QString appDir = QCoreApplication::applicationDirPath();
    QCoreApplication::addLibraryPath(appDir);
    QCoreApplication::addLibraryPath(QDir(appDir).filePath(QStringLiteral("plugins")));

    ensureHelperScripts();

    AppSettings settings;
    PlatformUtils platform;
    UpdateInstaller updater;

    QQmlApplicationEngine engine;
    engine.addImportPath(QDir(appDir).filePath(QStringLiteral("qml")));
    engine.rootContext()->setContextProperty(QStringLiteral("AppSettings"), &settings);
    engine.rootContext()->setContextProperty(QStringLiteral("Platform"), &platform);
    engine.rootContext()->setContextProperty(QStringLiteral("UpdateInstaller"), &updater);

    const QUrl url(QStringLiteral("qrc:/qml/App.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() {
            logLine(QStringLiteral("QML objectCreationFailed"));
            QMessageBox::critical(
                nullptr,
                QStringLiteral("TickerLens"),
                QStringLiteral("Failed to load the UI.\n\n"
                               "Try reinstalling from the latest GitHub release.\n"
                               "Log: %1")
                    .arg(logPath()));
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        logLine(QStringLiteral("rootObjects empty after load"));
        QMessageBox::critical(
            nullptr,
            QStringLiteral("TickerLens"),
            QStringLiteral("Failed to start (empty UI).\nLog: %1").arg(logPath()));
        return -1;
    }

    logLine(QStringLiteral("QML loaded OK"));
    QObject *root = engine.rootObjects().constFirst();

    // IPC server: second instances send "raise"
    QLocalServer::removeServer(QString::fromLatin1(kIpcName));
    auto *ipc = new QLocalServer(&app);
    if (!ipc->listen(QString::fromLatin1(kIpcName)))
        logLine(QStringLiteral("IPC listen failed: ") + ipc->errorString());
    QObject::connect(ipc, &QLocalServer::newConnection, &app, [ipc, root]() {
        while (QLocalSocket *s = ipc->nextPendingConnection()) {
            QObject::connect(s, &QLocalSocket::readyRead, s, [s, root]() {
                const QByteArray msg = s->readAll();
                if (msg.contains("raise") && root) {
                    QMetaObject::invokeMethod(root, "raiseFromSecondInstance");
                    logLine(QStringLiteral("raised from second instance request"));
                }
                s->disconnectFromServer();
                s->deleteLater();
            });
        }
    });

    // System tray
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
    if (QSystemTrayIcon::isSystemTrayAvailable())
        tray.show();
    else
        logLine(QStringLiteral("system tray not available"));

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

    // Show windows after the event loop starts (HWND ready)
    QTimer::singleShot(100, root, [root]() {
        QMetaObject::invokeMethod(root, "ensureVisibleOnLaunch");
        logLine(QStringLiteral("ensureVisibleOnLaunch requested"));
    });

    return app.exec();
}
