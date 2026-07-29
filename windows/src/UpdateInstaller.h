#pragma once

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>

// Downloads a GitHub release asset and applies it (Windows zip install / Linux tarball).
class UpdateInstaller : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit UpdateInstaller(QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    int progress() const { return m_progress; }
    QString status() const { return m_status; }

    // assetUrl: browser_download_url of the platform package
    // version: e.g. "1.6.0"
    Q_INVOKABLE void downloadAndInstall(const QString &assetUrl, const QString &version);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE QString preferredInstallDir() const;

signals:
    void busyChanged();
    void progressChanged();
    void statusChanged();
    // success=true: app should quit so the apply script can replace files (Windows)
    // or plasma install finished (Linux)
    void finished(bool success, const QString &message);
    void failed(const QString &error);

private:
    void setBusy(bool v);
    void setProgress(int p);
    void setStatus(const QString &s);
    void fail(const QString &error);
    void onDownloadFinished();
    void applyPackage(const QString &archivePath);
    bool applyWindows(const QString &archivePath);
    bool applyLinux(const QString &archivePath);
    QString workDir() const;

    QNetworkAccessManager m_nam;
    QNetworkReply *m_reply = nullptr;
    QFile m_file;
    QString m_version;
    QString m_archivePath;
    bool m_busy = false;
    int m_progress = 0;
    QString m_status;
};
