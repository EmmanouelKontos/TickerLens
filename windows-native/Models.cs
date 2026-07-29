using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace TickerLens.Native;

public sealed class Quote : INotifyPropertyChanged
{
    public string Symbol { get; init; } = "";
    public string Name { get; set; } = "";
    public double Price { get; set; }
    public double Change { get; set; }
    public double ChangePercent { get; set; }
    public double High52 { get; set; }
    public string Currency { get; set; } = "USD";
    public List<double> Spark { get; set; } = [];
    public bool Positive => Change >= 0;
    public string PriceText => $"{CurrencyMark}{Price:N2}";
    public string ChangeText => $"{Change:+0.00;-0.00;0.00} ({ChangePercent:+0.00;-0.00;0.00}%)";
    public string AthText => High52 > 0 ? $"ATH {((Price / High52) - 1) * 100:0.00}%" : "";
    private string CurrencyMark => Currency switch { "EUR" => "€", "GBP" => "£", "JPY" => "¥", _ => "$" };
    public event PropertyChangedEventHandler? PropertyChanged;
    public void Refresh() => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(null));
}

public sealed class Headline
{
    public string Title { get; init; } = "";
    public string Link { get; init; } = "";
    public string Publisher { get; init; } = "";
    public string Time { get; init; } = "";
    public string Symbols { get; init; } = "";
    public string Sentiment { get; init; } = "Neutral";
    public bool Good => Sentiment == "Good";
    public bool Bad => Sentiment == "Bad";
}

public sealed class Settings
{
    public string Symbols { get; set; } = "SPY,QQQ,AAPL,MSFT,NVDA,GOOGL,AMZN,META,TSLA";
    public int RefreshMinutes { get; set; } = 5;
    public bool AlwaysOnTop { get; set; }

    private static string FilePath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "TickerLens", "native-settings.json");

    public static Settings Load()
    {
        try {
            return System.Text.Json.JsonSerializer.Deserialize<Settings>(
                File.ReadAllText(FilePath)) ?? new Settings();
        } catch { return new Settings(); }
    }

    public void Save()
    {
        Directory.CreateDirectory(Path.GetDirectoryName(FilePath)!);
        File.WriteAllText(FilePath,
            System.Text.Json.JsonSerializer.Serialize(this,
                new System.Text.Json.JsonSerializerOptions { WriteIndented = true }));
    }
}
