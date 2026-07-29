#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

// Cross-platform helpers for Windows 11 desktop shell (also works on Linux).
class PlatformUtils : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString configDir READ configDir CONSTANT)
    Q_PROPERTY(bool isWindows READ isWindows CONSTANT)

public:
    explicit PlatformUtils(QObject *parent = nullptr);

    QString configDir() const;
    bool isWindows() const;

    Q_INVOKABLE bool writeTextFile(const QString &path, const QString &content) const;
    Q_INVOKABLE QString readTextFile(const QString &path) const;
    Q_INVOKABLE bool fileExists(const QString &path) const;
    Q_INVOKABLE void openUrl(const QString &url) const;
    Q_INVOKABLE void showNotification(const QString &title, const QString &body) const;
    Q_INVOKABLE void writeWatchlist(const QStringList &symbols) const;
    Q_INVOKABLE QStringList readWatchlist() const;
    Q_INVOKABLE QString deepseekKeyPath() const;
    Q_INVOKABLE QString rateNewsScriptPath() const;
    Q_INVOKABLE QString runDeepSeek(const QString &payloadJson, const QString &apiKey) const;
    Q_INVOKABLE void copyToClipboard(const QString &text) const;
    Q_INVOKABLE bool isOnBattery() const;
    Q_INVOKABLE bool isScreenLocked() const;
    Q_INVOKABLE QString joinPath(const QString &a, const QString &b) const;
    // Apply Windows 11 Mica/Acrylic (or no-op elsewhere). Pass a QQuickWindow from QML.
    Q_INVOKABLE void applyGlassEffect(QObject *window) const;
    // Reliable show/hide for frameless windows (Windows needs HWND restore/foreground).
    Q_INVOKABLE void showWindow(QObject *window) const;
    Q_INVOKABLE void hideWindow(QObject *window) const;
    Q_INVOKABLE void bringToFront(QObject *window) const;
};
