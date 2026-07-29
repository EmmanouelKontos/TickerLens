#include "PlatformUtils.h"

#include <QClipboard>
#include <QCoreApplication>
#include <QDateTime>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>
#include <QUrl>

#ifdef Q_OS_WIN
#  include <windows.h>
#  include <dwmapi.h>
#  ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#    define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#  endif
#  ifndef DWMWA_SYSTEMBACKDROP_TYPE
#    define DWMWA_SYSTEMBACKDROP_TYPE 38
#  endif
#  ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#    define DWMWA_WINDOW_CORNER_PREFERENCE 33
#  endif
#  ifndef DWMWCP_ROUND
#    define DWMWCP_ROUND 2
#  endif
#  ifndef DWMSBT_MAINWINDOW
#    define DWMSBT_MAINWINDOW 2 /* Mica */
#  endif
#  ifndef DWMSBT_TRANSIENTWINDOW
#    define DWMSBT_TRANSIENTWINDOW 3 /* Acrylic */
#  endif
#endif

#include <QQuickWindow>

PlatformUtils::PlatformUtils(QObject *parent)
    : QObject(parent)
{
    QDir().mkpath(configDir());
}

QString PlatformUtils::configDir() const
{
    // %APPDATA%/TickerLens on Windows, ~/.config/TickerLens on Linux
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    // AppConfigLocation already includes org/app if set; we set org to TickerLens
    QDir d(base);
    if (!d.exists())
        d.mkpath(QStringLiteral("."));
    return d.absolutePath();
}

bool PlatformUtils::isWindows() const
{
#ifdef Q_OS_WIN
    return true;
#else
    return false;
#endif
}

bool PlatformUtils::writeTextFile(const QString &path, const QString &content) const
{
    QFileInfo fi(path);
    QDir().mkpath(fi.absolutePath());
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return false;
    f.write(content.toUtf8());
    f.close();
#ifdef Q_OS_UNIX
    // best-effort private key files
    if (path.endsWith(QLatin1String("deepseek.key")))
        QFile::setPermissions(path, QFileDevice::ReadOwner | QFileDevice::WriteOwner);
#endif
    return true;
}

QString PlatformUtils::readTextFile(const QString &path) const
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(f.readAll());
}

bool PlatformUtils::fileExists(const QString &path) const
{
    return QFile::exists(path);
}

void PlatformUtils::openUrl(const QString &url) const
{
    QDesktopServices::openUrl(QUrl(url));
}

void PlatformUtils::showNotification(const QString &title, const QString &body) const
{
#ifdef Q_OS_WIN
    // PowerShell toast (Windows 10/11)
    const QString script =
        QStringLiteral(
            "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null; "
            "$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent("
            "[Windows.UI.Notifications.ToastTemplateType]::ToastText02); "
            "$text = $template.GetElementsByTagName('text'); "
            "$text.Item(0).AppendChild($template.CreateTextNode('%1')) | Out-Null; "
            "$text.Item(1).AppendChild($template.CreateTextNode('%2')) | Out-Null; "
            "$toast = [Windows.UI.Notifications.ToastNotification]::new($template); "
            "[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('TickerLens').Show($toast);")
            .arg(QString(title).replace(QLatin1Char('\''), QLatin1String("''")),
                 QString(body).replace(QLatin1Char('\''), QLatin1String("''")));
    QProcess::startDetached(QStringLiteral("powershell"),
                            {QStringLiteral("-NoProfile"), QStringLiteral("-Command"), script});
#else
    QProcess::startDetached(QStringLiteral("notify-send"),
                            {QStringLiteral("-a"), QStringLiteral("TickerLens"), title, body});
#endif
}

void PlatformUtils::writeWatchlist(const QStringList &symbols) const
{
    QJsonObject o;
    QJsonArray arr;
    for (const QString &s : symbols)
        arr.append(s);
    o.insert(QStringLiteral("symbols"), arr);
    o.insert(QStringLiteral("updated"), QDateTime::currentMSecsSinceEpoch());
    o.insert(QStringLiteral("source"), QStringLiteral("tickerlens-desktop"));
    const QString path = QDir(configDir()).filePath(QStringLiteral("watchlist.json"));
    writeTextFile(path, QString::fromUtf8(QJsonDocument(o).toJson(QJsonDocument::Compact)));
}

QStringList PlatformUtils::readWatchlist() const
{
    const QString path = QDir(configDir()).filePath(QStringLiteral("watchlist.json"));
    const QString raw = readTextFile(path);
    if (raw.isEmpty())
        return {};
    const QJsonDocument doc = QJsonDocument::fromJson(raw.toUtf8());
    if (!doc.isObject())
        return {};
    const QJsonArray arr = doc.object().value(QStringLiteral("symbols")).toArray();
    QStringList out;
    for (const QJsonValue &v : arr)
        out << v.toString().trimmed().toUpper();
    out.removeAll(QString());
    return out;
}

QString PlatformUtils::deepseekKeyPath() const
{
    return QDir(configDir()).filePath(QStringLiteral("deepseek.key"));
}

QString PlatformUtils::rateNewsScriptPath() const
{
    // Prefer next to application, then config dir, then source tree scripts
    const QString beside = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("rate_news.py"));
    if (QFile::exists(beside))
        return beside;
    const QString cfg = QDir(configDir()).filePath(QStringLiteral("rate_news.py"));
    if (QFile::exists(cfg))
        return cfg;
    return QDir(configDir()).filePath(QStringLiteral("rate_news.py"));
}

QString PlatformUtils::runDeepSeek(const QString &payloadJson, const QString &apiKey) const
{
    QDir().mkpath(configDir());
    const QString payloadPath = QDir(configDir()).filePath(QStringLiteral("ds_payload.json"));
    writeTextFile(payloadPath, payloadJson);

    if (!apiKey.trimmed().isEmpty())
        writeTextFile(deepseekKeyPath(), apiKey.trimmed());

    // Ensure helper script exists in config dir
    const QString scriptDst = QDir(configDir()).filePath(QStringLiteral("rate_news.py"));
    if (!QFile::exists(scriptDst)) {
        const QString src = QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("rate_news.py"));
        if (QFile::exists(src))
            QFile::copy(src, scriptDst);
    }

    QProcess proc;
    proc.setProgram(QStringLiteral("python3"));
#ifdef Q_OS_WIN
    // Prefer py launcher / python on Windows
    proc.setProgram(QStringLiteral("python"));
#endif
    proc.setArguments({scriptDst});
    proc.setWorkingDirectory(configDir());
    proc.setProcessChannelMode(QProcess::SeparateChannels);
    proc.start();
    if (!proc.waitForStarted(5000)) {
        // fallback python3
        proc.setProgram(QStringLiteral("python3"));
        proc.start();
        if (!proc.waitForStarted(5000))
            return QStringLiteral("{\"error\":\"python not found\"}");
    }
    if (!proc.waitForFinished(120000)) {
        proc.kill();
        return QStringLiteral("{\"error\":\"timeout\"}");
    }
    if (proc.exitCode() != 0) {
        const QString err = QString::fromUtf8(proc.readAllStandardError()).left(300);
        QJsonObject o;
        o.insert(QStringLiteral("error"), err);
        return QString::fromUtf8(QJsonDocument(o).toJson(QJsonDocument::Compact));
    }
    return QString::fromUtf8(proc.readAllStandardOutput());
}

void PlatformUtils::copyToClipboard(const QString &text) const
{
    if (auto *clip = QGuiApplication::clipboard())
        clip->setText(text);
}

bool PlatformUtils::isOnBattery() const
{
#ifdef Q_OS_WIN
    SYSTEM_POWER_STATUS st{};
    if (GetSystemPowerStatus(&st))
        return st.ACLineStatus == 0;
    return false;
#else
    // Best-effort Linux
    const QString bat = QStringLiteral("/sys/class/power_supply/BAT0/status");
    const QString s = readTextFile(bat).trimmed().toLower();
    return s.contains(QLatin1String("discharg"));
#endif
}

bool PlatformUtils::isScreenLocked() const
{
    // Desktop app: session lock detection is OS-specific; default false on Windows
    // (can be extended with WTS APIs). Linux probes omitted for portability.
    return false;
}

QString PlatformUtils::joinPath(const QString &a, const QString &b) const
{
    return QDir(a).filePath(b);
}

void PlatformUtils::applyGlassEffect(QObject *window) const
{
    if (!window)
        return;
#ifdef Q_OS_WIN
    auto *qw = qobject_cast<QQuickWindow *>(window);
    if (!qw)
        return;
    const HWND hwnd = reinterpret_cast<HWND>(qw->winId());
    if (!hwnd)
        return;

    BOOL dark = TRUE;
    DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark, sizeof(dark));

    // Windows 11: rounded corners + acrylic/mica backdrop
    const int corner = DWMWCP_ROUND;
    DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &corner, sizeof(corner));

    const int backdrop = DWMSBT_TRANSIENTWINDOW; // Acrylic — closer to frosted glass
    DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, &backdrop, sizeof(backdrop));

    // Keep Qt fill semi-transparent so backdrop shows through
    qw->setColor(Qt::transparent);
#else
    Q_UNUSED(window);
#endif
}
