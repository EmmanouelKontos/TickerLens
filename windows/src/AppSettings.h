#pragma once

#include <QObject>
#include <QSettings>
#include <QVariant>
#include <QColor>
#include <QString>

// QSettings-backed configuration exposed to QML (Windows / desktop shell).
class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString symbols READ symbols WRITE setSymbols NOTIFY symbolsChanged)
    Q_PROPERTY(int refreshInterval READ refreshInterval WRITE setRefreshInterval NOTIFY settingsChanged)
    Q_PROPERTY(int athRefreshHours READ athRefreshHours WRITE setAthRefreshHours NOTIFY settingsChanged)
    Q_PROPERTY(bool skipWeekends READ skipWeekends WRITE setSkipWeekends NOTIFY settingsChanged)
    Q_PROPERTY(bool limitMarketHours READ limitMarketHours WRITE setLimitMarketHours NOTIFY settingsChanged)
    Q_PROPERTY(bool useMarketHolidays READ useMarketHolidays WRITE setUseMarketHolidays NOTIFY settingsChanged)
    Q_PROPERTY(bool pauseOnBattery READ pauseOnBattery WRITE setPauseOnBattery NOTIFY settingsChanged)
    Q_PROPERTY(bool pauseWhenLocked READ pauseWhenLocked WRITE setPauseWhenLocked NOTIFY settingsChanged)
    Q_PROPERTY(int marketOpenHour READ marketOpenHour WRITE setMarketOpenHour NOTIFY settingsChanged)
    Q_PROPERTY(int marketOpenMinute READ marketOpenMinute WRITE setMarketOpenMinute NOTIFY settingsChanged)
    Q_PROPERTY(int marketCloseHour READ marketCloseHour WRITE setMarketCloseHour NOTIFY settingsChanged)
    Q_PROPERTY(int marketCloseMinute READ marketCloseMinute WRITE setMarketCloseMinute NOTIFY settingsChanged)
    Q_PROPERTY(QString sortMode READ sortMode WRITE setSortMode NOTIFY settingsChanged)
    Q_PROPERTY(bool showCompanyName READ showCompanyName WRITE setShowCompanyName NOTIFY settingsChanged)
    Q_PROPERTY(bool showDailyChange READ showDailyChange WRITE setShowDailyChange NOTIFY settingsChanged)
    Q_PROPERTY(bool showAth READ showAth WRITE setShowAth NOTIFY settingsChanged)
    Q_PROPERTY(bool showCurrencySymbol READ showCurrencySymbol WRITE setShowCurrencySymbol NOTIFY settingsChanged)
    Q_PROPERTY(bool compactRows READ compactRows WRITE setCompactRows NOTIFY settingsChanged)
    Q_PROPERTY(bool showSparklines READ showSparklines WRITE setShowSparklines NOTIFY settingsChanged)
    Q_PROPERTY(bool showDayRange READ showDayRange WRITE setShowDayRange NOTIFY settingsChanged)
    Q_PROPERTY(bool showPrePost READ showPrePost WRITE setShowPrePost NOTIFY settingsChanged)
    Q_PROPERTY(bool showEarnings READ showEarnings WRITE setShowEarnings NOTIFY settingsChanged)
    Q_PROPERTY(int earningsRefreshHours READ earningsRefreshHours WRITE setEarningsRefreshHours NOTIFY settingsChanged)
    Q_PROPERTY(bool showPortfolio READ showPortfolio WRITE setShowPortfolio NOTIFY settingsChanged)
    Q_PROPERTY(bool multiColumn READ multiColumn WRITE setMultiColumn NOTIFY settingsChanged)
    Q_PROPERTY(bool pulseOnChange READ pulseOnChange WRITE setPulseOnChange NOTIFY settingsChanged)
    Q_PROPERTY(double athNearThreshold READ athNearThreshold WRITE setAthNearThreshold NOTIFY settingsChanged)
    Q_PROPERTY(int sparkleMinWidth READ sparkleMinWidth WRITE setSparkleMinWidth NOTIFY settingsChanged)
    Q_PROPERTY(int multiColumnMinWidth READ multiColumnMinWidth WRITE setMultiColumnMinWidth NOTIFY settingsChanged)
    Q_PROPERTY(QString panelSymbol READ panelSymbol WRITE setPanelSymbol NOTIFY settingsChanged)
    Q_PROPERTY(bool useCustomColors READ useCustomColors WRITE setUseCustomColors NOTIFY settingsChanged)
    Q_PROPERTY(int glassOpacity READ glassOpacity WRITE setGlassOpacity NOTIFY settingsChanged)
    Q_PROPERTY(QColor cardColor READ cardColor WRITE setCardColor NOTIFY settingsChanged)
    Q_PROPERTY(QColor textColor READ textColor WRITE setTextColor NOTIFY settingsChanged)
    Q_PROPERTY(QColor mutedTextColor READ mutedTextColor WRITE setMutedTextColor NOTIFY settingsChanged)
    Q_PROPERTY(QColor positiveColor READ positiveColor WRITE setPositiveColor NOTIFY settingsChanged)
    Q_PROPERTY(QColor negativeColor READ negativeColor WRITE setNegativeColor NOTIFY settingsChanged)
    Q_PROPERTY(QColor athColor READ athColor WRITE setAthColor NOTIFY settingsChanged)
    Q_PROPERTY(QColor accentColor READ accentColor WRITE setAccentColor NOTIFY settingsChanged)
    Q_PROPERTY(int borderOpacity READ borderOpacity WRITE setBorderOpacity NOTIFY settingsChanged)
    Q_PROPERTY(int cornerRadius READ cornerRadius WRITE setCornerRadius NOTIFY settingsChanged)
    Q_PROPERTY(QString portfolioJson READ portfolioJson WRITE setPortfolioJson NOTIFY settingsChanged)
    Q_PROPERTY(QString alertsJson READ alertsJson WRITE setAlertsJson NOTIFY settingsChanged)
    Q_PROPERTY(QString alertStateJson READ alertStateJson WRITE setAlertStateJson NOTIFY settingsChanged)
    Q_PROPERTY(QString athCacheJson READ athCacheJson WRITE setAthCacheJson NOTIFY settingsChanged)
    Q_PROPERTY(QString earningsCacheJson READ earningsCacheJson WRITE setEarningsCacheJson NOTIFY settingsChanged)

    // News
    Q_PROPERTY(bool useSharedWatchlist READ useSharedWatchlist WRITE setUseSharedWatchlist NOTIFY settingsChanged)
    Q_PROPERTY(QString newsSymbols READ newsSymbols WRITE setNewsSymbols NOTIFY settingsChanged)
    Q_PROPERTY(int newsRefreshInterval READ newsRefreshInterval WRITE setNewsRefreshInterval NOTIFY settingsChanged)
    Q_PROPERTY(int maxItems READ maxItems WRITE setMaxItems NOTIFY settingsChanged)
    Q_PROPERTY(int newsPerSymbol READ newsPerSymbol WRITE setNewsPerSymbol NOTIFY settingsChanged)
    Q_PROPERTY(bool showPublisher READ showPublisher WRITE setShowPublisher NOTIFY settingsChanged)
    Q_PROPERTY(bool showTickers READ showTickers WRITE setShowTickers NOTIFY settingsChanged)
    Q_PROPERTY(bool showTime READ showTime WRITE setShowTime NOTIFY settingsChanged)
    Q_PROPERTY(bool showSentiment READ showSentiment WRITE setShowSentiment NOTIFY settingsChanged)
    Q_PROPERTY(bool useDeepSeek READ useDeepSeek WRITE setUseDeepSeek NOTIFY settingsChanged)
    Q_PROPERTY(QString deepseekApiKey READ deepseekApiKey WRITE setDeepseekApiKey NOTIFY settingsChanged)
    Q_PROPERTY(QString deepseekModel READ deepseekModel WRITE setDeepseekModel NOTIFY settingsChanged)
    Q_PROPERTY(bool alwaysOnTop READ alwaysOnTop WRITE setAlwaysOnTop NOTIFY settingsChanged)
    Q_PROPERTY(bool showStockWindow READ showStockWindow WRITE setShowStockWindow NOTIFY settingsChanged)
    Q_PROPERTY(bool showNewsWindow READ showNewsWindow WRITE setShowNewsWindow NOTIFY settingsChanged)

public:
    explicit AppSettings(QObject *parent = nullptr);

    QString symbols() const;
    void setSymbols(const QString &v);

    int refreshInterval() const;
    void setRefreshInterval(int v);
    int athRefreshHours() const;
    void setAthRefreshHours(int v);
    bool skipWeekends() const;
    void setSkipWeekends(bool v);
    bool limitMarketHours() const;
    void setLimitMarketHours(bool v);
    bool useMarketHolidays() const;
    void setUseMarketHolidays(bool v);
    bool pauseOnBattery() const;
    void setPauseOnBattery(bool v);
    bool pauseWhenLocked() const;
    void setPauseWhenLocked(bool v);
    int marketOpenHour() const;
    void setMarketOpenHour(int v);
    int marketOpenMinute() const;
    void setMarketOpenMinute(int v);
    int marketCloseHour() const;
    void setMarketCloseHour(int v);
    int marketCloseMinute() const;
    void setMarketCloseMinute(int v);
    QString sortMode() const;
    void setSortMode(const QString &v);
    bool showCompanyName() const;
    void setShowCompanyName(bool v);
    bool showDailyChange() const;
    void setShowDailyChange(bool v);
    bool showAth() const;
    void setShowAth(bool v);
    bool showCurrencySymbol() const;
    void setShowCurrencySymbol(bool v);
    bool compactRows() const;
    void setCompactRows(bool v);
    bool showSparklines() const;
    void setShowSparklines(bool v);
    bool showDayRange() const;
    void setShowDayRange(bool v);
    bool showPrePost() const;
    void setShowPrePost(bool v);
    bool showEarnings() const;
    void setShowEarnings(bool v);
    int earningsRefreshHours() const;
    void setEarningsRefreshHours(int v);
    bool showPortfolio() const;
    void setShowPortfolio(bool v);
    bool multiColumn() const;
    void setMultiColumn(bool v);
    bool pulseOnChange() const;
    void setPulseOnChange(bool v);
    double athNearThreshold() const;
    void setAthNearThreshold(double v);
    int sparkleMinWidth() const;
    void setSparkleMinWidth(int v);
    int multiColumnMinWidth() const;
    void setMultiColumnMinWidth(int v);
    QString panelSymbol() const;
    void setPanelSymbol(const QString &v);
    bool useCustomColors() const;
    void setUseCustomColors(bool v);
    int glassOpacity() const;
    void setGlassOpacity(int v);
    QColor cardColor() const;
    void setCardColor(const QColor &v);
    QColor textColor() const;
    void setTextColor(const QColor &v);
    QColor mutedTextColor() const;
    void setMutedTextColor(const QColor &v);
    QColor positiveColor() const;
    void setPositiveColor(const QColor &v);
    QColor negativeColor() const;
    void setNegativeColor(const QColor &v);
    QColor athColor() const;
    void setAthColor(const QColor &v);
    QColor accentColor() const;
    void setAccentColor(const QColor &v);
    int borderOpacity() const;
    void setBorderOpacity(int v);
    int cornerRadius() const;
    void setCornerRadius(int v);
    QString portfolioJson() const;
    void setPortfolioJson(const QString &v);
    QString alertsJson() const;
    void setAlertsJson(const QString &v);
    QString alertStateJson() const;
    void setAlertStateJson(const QString &v);
    QString athCacheJson() const;
    void setAthCacheJson(const QString &v);
    QString earningsCacheJson() const;
    void setEarningsCacheJson(const QString &v);

    bool useSharedWatchlist() const;
    void setUseSharedWatchlist(bool v);
    QString newsSymbols() const;
    void setNewsSymbols(const QString &v);
    int newsRefreshInterval() const;
    void setNewsRefreshInterval(int v);
    int maxItems() const;
    void setMaxItems(int v);
    int newsPerSymbol() const;
    void setNewsPerSymbol(int v);
    bool showPublisher() const;
    void setShowPublisher(bool v);
    bool showTickers() const;
    void setShowTickers(bool v);
    bool showTime() const;
    void setShowTime(bool v);
    bool showSentiment() const;
    void setShowSentiment(bool v);
    bool useDeepSeek() const;
    void setUseDeepSeek(bool v);
    QString deepseekApiKey() const;
    void setDeepseekApiKey(const QString &v);
    QString deepseekModel() const;
    void setDeepseekModel(const QString &v);
    bool alwaysOnTop() const;
    void setAlwaysOnTop(bool v);
    bool showStockWindow() const;
    void setShowStockWindow(bool v);
    bool showNewsWindow() const;
    void setShowNewsWindow(bool v);

    Q_INVOKABLE void sync();

signals:
    void symbolsChanged();
    void settingsChanged();

private:
    QSettings m_settings;
    QVariant get(const QString &key, const QVariant &def) const;
    void set(const QString &key, const QVariant &val);
};
