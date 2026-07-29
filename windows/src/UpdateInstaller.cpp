#include "UpdateInstaller.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QNetworkRequest>
#include <QProcess>
#include <QStandardPaths>
#include <QUrl>
#include <QTimer>

UpdateInstaller::UpdateInstaller(QObject *parent)
    : QObject(parent)
{
}

QString UpdateInstaller::workDir() const
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    return QDir(base).filePath(QStringLiteral("TickerLens-update"));
}

QString UpdateInstaller::preferredInstallDir() const
{
#ifdef Q_OS_WIN
    const QString local = QDir::fromNativeSeparators(
        QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation));
    // GenericDataLocation = %LOCALAPPDATA% on Windows when org not used; prefer explicit
    const QString appLocal = QDir(QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation))
                                 .absolutePath();
    // AppLocalDataLocation may be %LOCALAPPDATA%/TickerLens/TickerLens — normalize to %LOCALAPPDATA%/TickerLens
    const QString localAppData = qEnvironmentVariable("LOCALAPPDATA");
    if (!localAppData.isEmpty()) {
        const QString preferred = QDir(localAppData).filePath(QStringLiteral("TickerLens"));
        const QString running = QDir::cleanPath(QCoreApplication::applicationDirPath());
        if (running.compare(QDir::cleanPath(preferred), Qt::CaseInsensitive) == 0
            || QFile::exists(QDir(preferred).filePath(QStringLiteral("TickerLens.exe"))))
            return preferred;
        // Portable run: install into the folder that currently holds the exe
        if (QFile::exists(QDir(running).filePath(QStringLiteral("TickerLens.exe"))))
            return running;
        return preferred;
    }
    Q_UNUSED(local);
    Q_UNUSED(appLocal);
    return QCoreApplication::applicationDirPath();
#else
    return QCoreApplication::applicationDirPath();
#endif
}

void UpdateInstaller::setBusy(bool v)
{
    if (m_busy == v)
        return;
    m_busy = v;
    emit busyChanged();
}

void UpdateInstaller::setProgress(int p)
{
    p = qBound(0, p, 100);
    if (m_progress == p)
        return;
    m_progress = p;
    emit progressChanged();
}

void UpdateInstaller::setStatus(const QString &s)
{
    if (m_status == s)
        return;
    m_status = s;
    emit statusChanged();
}

void UpdateInstaller::fail(const QString &error)
{
    setBusy(false);
    setStatus(error);
    emit failed(error);
    emit finished(false, error);
}

void UpdateInstaller::cancel()
{
    if (m_reply) {
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }
    if (m_file.isOpen())
        m_file.close();
    setBusy(false);
    setStatus(QStringLiteral("Cancelled"));
}

void UpdateInstaller::downloadAndInstall(const QString &assetUrl, const QString &version)
{
    if (m_busy) {
        emit failed(QStringLiteral("Update already in progress"));
        return;
    }
    if (assetUrl.trimmed().isEmpty()) {
        fail(QStringLiteral("No download URL for this platform"));
        return;
    }

    m_version = version.trimmed();
    const QUrl url(assetUrl);
    if (!url.isValid() || (url.scheme() != QLatin1String("https") && url.scheme() != QLatin1String("http"))) {
        fail(QStringLiteral("Invalid download URL"));
        return;
    }

    QDir().mkpath(workDir());
    QString fileName = QFileInfo(url.path()).fileName();
    if (fileName.isEmpty())
        fileName = QStringLiteral("TickerLens-update.bin");
    m_archivePath = QDir(workDir()).filePath(fileName);

    if (m_file.isOpen())
        m_file.close();
    m_file.setFileName(m_archivePath);
    if (!m_file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        fail(QStringLiteral("Cannot write temp file: ") + m_archivePath);
        return;
    }

    setBusy(true);
    setProgress(0);
    setStatus(QStringLiteral("Downloading…"));

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("TickerLens-UpdateInstaller"));
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    if (m_reply) {
        m_reply->disconnect(this);
        m_reply->deleteLater();
    }
    m_reply = m_nam.get(req);

    connect(m_reply, &QNetworkReply::downloadProgress, this, [this](qint64 rec, qint64 total) {
        if (total > 0)
            setProgress(int((rec * 100) / total));
        else
            setStatus(QStringLiteral("Downloading… %1 MB").arg(rec / (1024 * 1024)));
    });
    connect(m_reply, &QNetworkReply::readyRead, this, [this]() {
        if (m_reply && m_file.isOpen())
            m_file.write(m_reply->readAll());
    });
    connect(m_reply, &QNetworkReply::finished, this, &UpdateInstaller::onDownloadFinished);
}

void UpdateInstaller::onDownloadFinished()
{
    if (!m_reply)
        return;

    QNetworkReply *reply = m_reply;
    m_reply = nullptr;

    if (m_file.isOpen()) {
        if (reply->bytesAvailable())
            m_file.write(reply->readAll());
        m_file.close();
    }

    const auto err = reply->error();
    const QString errStr = reply->errorString();
    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    reply->deleteLater();

    if (err == QNetworkReply::OperationCanceledError) {
        QFile::remove(m_archivePath);
        setBusy(false);
        setStatus(QStringLiteral("Cancelled"));
        return;
    }
    if (err != QNetworkReply::NoError) {
        QFile::remove(m_archivePath);
        fail(QStringLiteral("Download failed: ") + errStr);
        return;
    }
    if (status >= 400) {
        QFile::remove(m_archivePath);
        fail(QStringLiteral("Download HTTP %1").arg(status));
        return;
    }
    if (!QFileInfo::exists(m_archivePath) || QFileInfo(m_archivePath).size() < 1024) {
        fail(QStringLiteral("Downloaded file is empty or too small"));
        return;
    }

    setProgress(100);
    setStatus(QStringLiteral("Installing…"));
    applyPackage(m_archivePath);
}

void UpdateInstaller::applyPackage(const QString &archivePath)
{
#ifdef Q_OS_WIN
    if (!applyWindows(archivePath))
        return;
#else
    if (!applyLinux(archivePath))
        return;
#endif
}

bool UpdateInstaller::applyWindows(const QString &archivePath)
{
#ifdef Q_OS_WIN
    const QString extractDir = QDir(workDir()).filePath(QStringLiteral("extract"));
    QDir(extractDir).removeRecursively();
    QDir().mkpath(extractDir);

    setStatus(QStringLiteral("Extracting…"));

    // Expand-Archive
    QProcess unzip;
    unzip.setProgram(QStringLiteral("powershell"));
    unzip.setArguments({
        QStringLiteral("-NoProfile"),
        QStringLiteral("-ExecutionPolicy"), QStringLiteral("Bypass"),
        QStringLiteral("-Command"),
        QStringLiteral("Expand-Archive -LiteralPath '%1' -DestinationPath '%2' -Force")
            .arg(QString(archivePath).replace(QLatin1Char('\''), QLatin1String("''")),
                 QString(extractDir).replace(QLatin1Char('\''), QLatin1String("''")))
    });
    unzip.start();
    if (!unzip.waitForFinished(300000) || unzip.exitCode() != 0) {
        fail(QStringLiteral("Extract failed: ") + QString::fromUtf8(unzip.readAllStandardError()).left(300));
        return false;
    }

    // Find folder containing TickerLens.exe (zip may nest one directory)
    QString packageDir;
    {
        QDirIterator it(extractDir, {QStringLiteral("TickerLens.exe")}, QDir::Files, QDirIterator::Subdirectories);
        if (it.hasNext()) {
            it.next();
            packageDir = QFileInfo(it.filePath()).absolutePath();
        }
    }
    if (packageDir.isEmpty()) {
        fail(QStringLiteral("Package missing TickerLens.exe"));
        return false;
    }

    const QString installDir = preferredInstallDir();
    QDir().mkpath(installDir);
    const qint64 pid = QCoreApplication::applicationPid();
    const QString exePath = QDir(installDir).filePath(QStringLiteral("TickerLens.exe"));
    const QString scriptPath = QDir(workDir()).filePath(QStringLiteral("apply-update.ps1"));

    // Wait for this process to exit, copy files, restart
    const QString script = QStringLiteral(
        "$ErrorActionPreference = 'Stop'\n"
        "$pidToWait = %1\n"
        "$src = '%2'\n"
        "$dst = '%3'\n"
        "$exe = '%4'\n"
        "try { Wait-Process -Id $pidToWait -Timeout 120 -ErrorAction SilentlyContinue } catch {}\n"
        "Start-Sleep -Seconds 1\n"
        "New-Item -ItemType Directory -Force -Path $dst | Out-Null\n"
        "$exclude = @('Install-TickerLens.ps1','Install.bat','Uninstall.ps1','apply-update.ps1')\n"
        "Get-ChildItem -LiteralPath $src -Force | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {\n"
        "  $target = Join-Path $dst $_.Name\n"
        "  if ($_.PSIsContainer) { Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force }\n"
        "  else { Copy-Item -LiteralPath $_.FullName -Destination $target -Force }\n"
        "}\n"
        "if (Test-Path (Join-Path $src 'Install-TickerLens.ps1')) {\n"
        "  Copy-Item (Join-Path $src 'Install-TickerLens.ps1') (Join-Path $dst 'Install-TickerLens.ps1') -Force -ErrorAction SilentlyContinue\n"
        "}\n"
        "Start-Process -FilePath $exe -WorkingDirectory $dst\n"
    ).arg(QString::number(pid),
          QString(packageDir).replace(QLatin1Char('\''), QLatin1String("''")),
          QString(installDir).replace(QLatin1Char('\''), QLatin1String("''")),
          QString(exePath).replace(QLatin1Char('\''), QLatin1String("''")));

    QFile sf(scriptPath);
    if (!sf.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        fail(QStringLiteral("Cannot write apply script"));
        return false;
    }
    sf.write(script.toUtf8());
    sf.close();

    const bool started = QProcess::startDetached(
        QStringLiteral("powershell"),
        {QStringLiteral("-NoProfile"),
         QStringLiteral("-ExecutionPolicy"), QStringLiteral("Bypass"),
         QStringLiteral("-File"), scriptPath});

    if (!started) {
        fail(QStringLiteral("Could not start update apply script"));
        return false;
    }

    setBusy(false);
    setStatus(QStringLiteral("Restarting to finish install…"));
    emit finished(true, QStringLiteral("Update downloaded. TickerLens will restart."));
    // Give the script a moment to attach Wait-Process, then quit
    QTimer::singleShot(400, qApp, &QCoreApplication::quit);
    return true;
#else
    Q_UNUSED(archivePath);
    fail(QStringLiteral("Windows install path used on non-Windows"));
    return false;
#endif
}

bool UpdateInstaller::applyLinux(const QString &archivePath)
{
#ifndef Q_OS_WIN
    const QString extractDir = QDir(workDir()).filePath(QStringLiteral("extract"));
    QDir(extractDir).removeRecursively();
    QDir().mkpath(extractDir);

    setStatus(QStringLiteral("Extracting…"));

    QProcess tar;
    tar.setProgram(QStringLiteral("tar"));
    tar.setArguments({QStringLiteral("-xzf"), archivePath, QStringLiteral("-C"), extractDir});
    tar.start();
    if (!tar.waitForFinished(300000) || tar.exitCode() != 0) {
        // try without z in case it's not gzip (unlikely)
        fail(QStringLiteral("Extract failed: ") + QString::fromUtf8(tar.readAllStandardError()).left(300));
        return false;
    }

    // Find install.sh
    QString packageDir;
    {
        QDirIterator it(extractDir, {QStringLiteral("install.sh")}, QDir::Files, QDirIterator::Subdirectories);
        if (it.hasNext()) {
            it.next();
            packageDir = QFileInfo(it.filePath()).absolutePath();
        }
    }
    if (packageDir.isEmpty()) {
        // maybe package/ and news-package at top
        if (QFile::exists(QDir(extractDir).filePath(QStringLiteral("install.sh"))))
            packageDir = extractDir;
        else {
            const auto entries = QDir(extractDir).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString &e : entries) {
                const QString cand = QDir(extractDir).filePath(e);
                if (QFile::exists(QDir(cand).filePath(QStringLiteral("install.sh")))) {
                    packageDir = cand;
                    break;
                }
            }
        }
    }
    if (packageDir.isEmpty()) {
        fail(QStringLiteral("Package missing install.sh"));
        return false;
    }

    setStatus(QStringLiteral("Running install.sh…"));
    QProcess install;
    install.setProgram(QStringLiteral("bash"));
    install.setArguments({QDir(packageDir).filePath(QStringLiteral("install.sh"))});
    install.setWorkingDirectory(packageDir);
    install.start();
    if (!install.waitForFinished(300000) || install.exitCode() != 0) {
        const QString err = QString::fromUtf8(install.readAllStandardError() + install.readAllStandardOutput()).left(400);
        fail(QStringLiteral("install.sh failed: ") + err);
        return false;
    }

    setBusy(false);
    setStatus(QStringLiteral("Installed. Reload Plasma if the UI looks stale."));
    emit finished(true,
                  QStringLiteral("Update installed. If the UI looks stale, run:\n"
                                 "kquitapp6 plasmashell; plasmashell --replace &"));
    return true;
#else
    Q_UNUSED(archivePath);
    return false;
#endif
}
