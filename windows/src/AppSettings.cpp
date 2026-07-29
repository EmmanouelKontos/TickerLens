#include "AppSettings.h"

#include <QCoreApplication>

AppSettings::AppSettings(QObject *parent)
    : QObject(parent)
    , m_settings(QSettings::IniFormat, QSettings::UserScope, QStringLiteral("TickerLens"), QStringLiteral("TickerLens"))
{
}

QVariant AppSettings::get(const QString &key, const QVariant &def) const
{
    return m_settings.value(key, def);
}

void AppSettings::set(const QString &key, const QVariant &val)
{
    if (m_settings.value(key) == val)
        return;
    m_settings.setValue(key, val);
    emit settingsChanged();
}

void AppSettings::sync()
{
    m_settings.sync();
}

#define STR_PROP(name, key, def) \
    QString AppSettings::name() const { return get(QStringLiteral(key), QStringLiteral(def)).toString(); } \
    void AppSettings::set##name(const QString &v) { \
        if (name() == v) return; \
        m_settings.setValue(QStringLiteral(key), v); \
        emit settingsChanged(); \
        if (QStringLiteral(#name) == QStringLiteral("symbols")) emit symbolsChanged(); \
    }

// Manual implementations for clarity / mixed types

QString AppSettings::symbols() const { return get(QStringLiteral("symbols"), QStringLiteral("SPY,QQQ,AAPL,MSFT,NVDA,GOOGL,AMZN,META,TSLA,RKLB,SPCX")).toString(); }
void AppSettings::setSymbols(const QString &v) {
    if (symbols() == v) return;
    m_settings.setValue(QStringLiteral("symbols"), v);
    emit symbolsChanged();
    emit settingsChanged();
}

int AppSettings::refreshInterval() const { return get(QStringLiteral("refreshInterval"), 5).toInt(); }
void AppSettings::setRefreshInterval(int v) { set(QStringLiteral("refreshInterval"), v); }

int AppSettings::athRefreshHours() const { return get(QStringLiteral("athRefreshHours"), 6).toInt(); }
void AppSettings::setAthRefreshHours(int v) { set(QStringLiteral("athRefreshHours"), v); }

bool AppSettings::skipWeekends() const { return get(QStringLiteral("skipWeekends"), true).toBool(); }
void AppSettings::setSkipWeekends(bool v) { set(QStringLiteral("skipWeekends"), v); }

bool AppSettings::limitMarketHours() const { return get(QStringLiteral("limitMarketHours"), false).toBool(); }
void AppSettings::setLimitMarketHours(bool v) { set(QStringLiteral("limitMarketHours"), v); }

bool AppSettings::useMarketHolidays() const { return get(QStringLiteral("useMarketHolidays"), true).toBool(); }
void AppSettings::setUseMarketHolidays(bool v) { set(QStringLiteral("useMarketHolidays"), v); }

bool AppSettings::pauseOnBattery() const { return get(QStringLiteral("pauseOnBattery"), false).toBool(); }
void AppSettings::setPauseOnBattery(bool v) { set(QStringLiteral("pauseOnBattery"), v); }

bool AppSettings::pauseWhenLocked() const { return get(QStringLiteral("pauseWhenLocked"), true).toBool(); }
void AppSettings::setPauseWhenLocked(bool v) { set(QStringLiteral("pauseWhenLocked"), v); }

int AppSettings::marketOpenHour() const { return get(QStringLiteral("marketOpenHour"), 9).toInt(); }
void AppSettings::setMarketOpenHour(int v) { set(QStringLiteral("marketOpenHour"), v); }
int AppSettings::marketOpenMinute() const { return get(QStringLiteral("marketOpenMinute"), 30).toInt(); }
void AppSettings::setMarketOpenMinute(int v) { set(QStringLiteral("marketOpenMinute"), v); }
int AppSettings::marketCloseHour() const { return get(QStringLiteral("marketCloseHour"), 16).toInt(); }
void AppSettings::setMarketCloseHour(int v) { set(QStringLiteral("marketCloseHour"), v); }
int AppSettings::marketCloseMinute() const { return get(QStringLiteral("marketCloseMinute"), 0).toInt(); }
void AppSettings::setMarketCloseMinute(int v) { set(QStringLiteral("marketCloseMinute"), v); }

QString AppSettings::sortMode() const { return get(QStringLiteral("sortMode"), QStringLiteral("aslisted")).toString(); }
void AppSettings::setSortMode(const QString &v) { set(QStringLiteral("sortMode"), v); }

bool AppSettings::showCompanyName() const { return get(QStringLiteral("showCompanyName"), true).toBool(); }
void AppSettings::setShowCompanyName(bool v) { set(QStringLiteral("showCompanyName"), v); }
bool AppSettings::showDailyChange() const { return get(QStringLiteral("showDailyChange"), true).toBool(); }
void AppSettings::setShowDailyChange(bool v) { set(QStringLiteral("showDailyChange"), v); }
bool AppSettings::showAth() const { return get(QStringLiteral("showAth"), true).toBool(); }
void AppSettings::setShowAth(bool v) { set(QStringLiteral("showAth"), v); }
bool AppSettings::showCurrencySymbol() const { return get(QStringLiteral("showCurrencySymbol"), true).toBool(); }
void AppSettings::setShowCurrencySymbol(bool v) { set(QStringLiteral("showCurrencySymbol"), v); }
bool AppSettings::compactRows() const { return get(QStringLiteral("compactRows"), false).toBool(); }
void AppSettings::setCompactRows(bool v) { set(QStringLiteral("compactRows"), v); }
bool AppSettings::showSparklines() const { return get(QStringLiteral("showSparklines"), true).toBool(); }
void AppSettings::setShowSparklines(bool v) { set(QStringLiteral("showSparklines"), v); }
bool AppSettings::showDayRange() const { return get(QStringLiteral("showDayRange"), true).toBool(); }
void AppSettings::setShowDayRange(bool v) { set(QStringLiteral("showDayRange"), v); }
bool AppSettings::showPrePost() const { return get(QStringLiteral("showPrePost"), true).toBool(); }
void AppSettings::setShowPrePost(bool v) { set(QStringLiteral("showPrePost"), v); }
bool AppSettings::showEarnings() const { return get(QStringLiteral("showEarnings"), true).toBool(); }
void AppSettings::setShowEarnings(bool v) { set(QStringLiteral("showEarnings"), v); }
int AppSettings::earningsRefreshHours() const { return get(QStringLiteral("earningsRefreshHours"), 24).toInt(); }
void AppSettings::setEarningsRefreshHours(int v) { set(QStringLiteral("earningsRefreshHours"), v); }
bool AppSettings::showPortfolio() const { return get(QStringLiteral("showPortfolio"), false).toBool(); }
void AppSettings::setShowPortfolio(bool v) { set(QStringLiteral("showPortfolio"), v); }
bool AppSettings::multiColumn() const { return get(QStringLiteral("multiColumn"), true).toBool(); }
void AppSettings::setMultiColumn(bool v) { set(QStringLiteral("multiColumn"), v); }
bool AppSettings::pulseOnChange() const { return get(QStringLiteral("pulseOnChange"), true).toBool(); }
void AppSettings::setPulseOnChange(bool v) { set(QStringLiteral("pulseOnChange"), v); }
double AppSettings::athNearThreshold() const { return get(QStringLiteral("athNearThreshold"), 0.25).toDouble(); }
void AppSettings::setAthNearThreshold(double v) { set(QStringLiteral("athNearThreshold"), v); }
int AppSettings::sparkleMinWidth() const { return get(QStringLiteral("sparkleMinWidth"), 340).toInt(); }
void AppSettings::setSparkleMinWidth(int v) { set(QStringLiteral("sparkleMinWidth"), v); }
int AppSettings::multiColumnMinWidth() const { return get(QStringLiteral("multiColumnMinWidth"), 520).toInt(); }
void AppSettings::setMultiColumnMinWidth(int v) { set(QStringLiteral("multiColumnMinWidth"), v); }
QString AppSettings::panelSymbol() const { return get(QStringLiteral("panelSymbol"), QString()).toString(); }
void AppSettings::setPanelSymbol(const QString &v) { set(QStringLiteral("panelSymbol"), v); }
bool AppSettings::useCustomColors() const { return get(QStringLiteral("useCustomColors"), true).toBool(); }
void AppSettings::setUseCustomColors(bool v) { set(QStringLiteral("useCustomColors"), v); }
int AppSettings::glassOpacity() const { return get(QStringLiteral("glassOpacity"), 68).toInt(); }
void AppSettings::setGlassOpacity(int v) { set(QStringLiteral("glassOpacity"), v); }

QColor AppSettings::cardColor() const { return get(QStringLiteral("cardColor"), QColor(QStringLiteral("#1a1a22"))).value<QColor>(); }
void AppSettings::setCardColor(const QColor &v) { set(QStringLiteral("cardColor"), v); }
QColor AppSettings::textColor() const { return get(QStringLiteral("textColor"), QColor(QStringLiteral("#f2f2f7"))).value<QColor>(); }
void AppSettings::setTextColor(const QColor &v) { set(QStringLiteral("textColor"), v); }
QColor AppSettings::mutedTextColor() const { return get(QStringLiteral("mutedTextColor"), QColor(QStringLiteral("#8e8e93"))).value<QColor>(); }
void AppSettings::setMutedTextColor(const QColor &v) { set(QStringLiteral("mutedTextColor"), v); }
QColor AppSettings::positiveColor() const { return get(QStringLiteral("positiveColor"), QColor(QStringLiteral("#30d158"))).value<QColor>(); }
void AppSettings::setPositiveColor(const QColor &v) { set(QStringLiteral("positiveColor"), v); }
QColor AppSettings::negativeColor() const { return get(QStringLiteral("negativeColor"), QColor(QStringLiteral("#ff453a"))).value<QColor>(); }
void AppSettings::setNegativeColor(const QColor &v) { set(QStringLiteral("negativeColor"), v); }
QColor AppSettings::athColor() const { return get(QStringLiteral("athColor"), QColor(QStringLiteral("#ffd60a"))).value<QColor>(); }
void AppSettings::setAthColor(const QColor &v) { set(QStringLiteral("athColor"), v); }
QColor AppSettings::accentColor() const { return get(QStringLiteral("accentColor"), QColor(QStringLiteral("#0a84ff"))).value<QColor>(); }
void AppSettings::setAccentColor(const QColor &v) { set(QStringLiteral("accentColor"), v); }

int AppSettings::borderOpacity() const { return get(QStringLiteral("borderOpacity"), 16).toInt(); }
void AppSettings::setBorderOpacity(int v) { set(QStringLiteral("borderOpacity"), v); }
int AppSettings::cornerRadius() const { return get(QStringLiteral("cornerRadius"), 20).toInt(); }
void AppSettings::setCornerRadius(int v) { set(QStringLiteral("cornerRadius"), v); }

QString AppSettings::portfolioJson() const { return get(QStringLiteral("portfolioJson"), QStringLiteral("{}")).toString(); }
void AppSettings::setPortfolioJson(const QString &v) { set(QStringLiteral("portfolioJson"), v); }
QString AppSettings::alertsJson() const { return get(QStringLiteral("alertsJson"), QStringLiteral("[]")).toString(); }
void AppSettings::setAlertsJson(const QString &v) { set(QStringLiteral("alertsJson"), v); }
QString AppSettings::alertStateJson() const { return get(QStringLiteral("alertStateJson"), QStringLiteral("{}")).toString(); }
void AppSettings::setAlertStateJson(const QString &v) { set(QStringLiteral("alertStateJson"), v); }
QString AppSettings::athCacheJson() const { return get(QStringLiteral("athCacheJson"), QStringLiteral("{}")).toString(); }
void AppSettings::setAthCacheJson(const QString &v) { set(QStringLiteral("athCacheJson"), v); }
QString AppSettings::earningsCacheJson() const { return get(QStringLiteral("earningsCacheJson"), QStringLiteral("{}")).toString(); }
void AppSettings::setEarningsCacheJson(const QString &v) { set(QStringLiteral("earningsCacheJson"), v); }

bool AppSettings::useSharedWatchlist() const { return get(QStringLiteral("useSharedWatchlist"), true).toBool(); }
void AppSettings::setUseSharedWatchlist(bool v) { set(QStringLiteral("useSharedWatchlist"), v); }
QString AppSettings::newsSymbols() const { return get(QStringLiteral("newsSymbols"), QStringLiteral("SPY,QQQ,AAPL,MSFT,NVDA,GOOGL,AMZN,META,TSLA,RKLB,SPCX")).toString(); }
void AppSettings::setNewsSymbols(const QString &v) { set(QStringLiteral("newsSymbols"), v); }
int AppSettings::newsRefreshInterval() const { return get(QStringLiteral("newsRefreshInterval"), 10).toInt(); }
void AppSettings::setNewsRefreshInterval(int v) { set(QStringLiteral("newsRefreshInterval"), v); }
int AppSettings::maxItems() const { return get(QStringLiteral("maxItems"), 40).toInt(); }
void AppSettings::setMaxItems(int v) { set(QStringLiteral("maxItems"), v); }
int AppSettings::newsPerSymbol() const { return get(QStringLiteral("newsPerSymbol"), 5).toInt(); }
void AppSettings::setNewsPerSymbol(int v) { set(QStringLiteral("newsPerSymbol"), v); }
bool AppSettings::showPublisher() const { return get(QStringLiteral("showPublisher"), true).toBool(); }
void AppSettings::setShowPublisher(bool v) { set(QStringLiteral("showPublisher"), v); }
bool AppSettings::showTickers() const { return get(QStringLiteral("showTickers"), true).toBool(); }
void AppSettings::setShowTickers(bool v) { set(QStringLiteral("showTickers"), v); }
bool AppSettings::showTime() const { return get(QStringLiteral("showTime"), true).toBool(); }
void AppSettings::setShowTime(bool v) { set(QStringLiteral("showTime"), v); }
bool AppSettings::showSentiment() const { return get(QStringLiteral("showSentiment"), true).toBool(); }
void AppSettings::setShowSentiment(bool v) { set(QStringLiteral("showSentiment"), v); }
bool AppSettings::useDeepSeek() const { return get(QStringLiteral("useDeepSeek"), true).toBool(); }
void AppSettings::setUseDeepSeek(bool v) { set(QStringLiteral("useDeepSeek"), v); }
QString AppSettings::deepseekApiKey() const { return get(QStringLiteral("deepseekApiKey"), QString()).toString(); }
void AppSettings::setDeepseekApiKey(const QString &v) { set(QStringLiteral("deepseekApiKey"), v); }
QString AppSettings::deepseekModel() const { return get(QStringLiteral("deepseekModel"), QStringLiteral("deepseek-chat")).toString(); }
void AppSettings::setDeepseekModel(const QString &v) { set(QStringLiteral("deepseekModel"), v); }
bool AppSettings::alwaysOnTop() const { return get(QStringLiteral("alwaysOnTop"), true).toBool(); }
void AppSettings::setAlwaysOnTop(bool v) { set(QStringLiteral("alwaysOnTop"), v); }
bool AppSettings::showStockWindow() const { return get(QStringLiteral("showStockWindow"), true).toBool(); }
void AppSettings::setShowStockWindow(bool v) { set(QStringLiteral("showStockWindow"), v); }
bool AppSettings::showNewsWindow() const { return get(QStringLiteral("showNewsWindow"), true).toBool(); }
void AppSettings::setShowNewsWindow(bool v) { set(QStringLiteral("showNewsWindow"), v); }

bool AppSettings::checkForUpdates() const { return get(QStringLiteral("checkForUpdates"), true).toBool(); }
void AppSettings::setCheckForUpdates(bool v) { set(QStringLiteral("checkForUpdates"), v); }
qint64 AppSettings::lastUpdateCheckMs() const { return get(QStringLiteral("lastUpdateCheckMs"), 0).toLongLong(); }
void AppSettings::setLastUpdateCheckMs(qint64 v) { set(QStringLiteral("lastUpdateCheckMs"), QVariant::fromValue(v)); }
QString AppSettings::dismissedUpdateVersion() const { return get(QStringLiteral("dismissedUpdateVersion"), QString()).toString(); }
void AppSettings::setDismissedUpdateVersion(const QString &v) { set(QStringLiteral("dismissedUpdateVersion"), v); }
QString AppSettings::appVersion() const
{
    const QString v = QCoreApplication::applicationVersion();
    return v.isEmpty() ? QStringLiteral("1.6.0") : v;
}
