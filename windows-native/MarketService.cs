using System.Net.Http;
using System.Text.Json;
using System.Xml.Linq;

namespace TickerLens.Native;

public static class MarketService
{
    private static readonly HttpClient Http = new() {
        Timeout = TimeSpan.FromSeconds(15)
    };

    static MarketService()
    {
        Http.DefaultRequestHeaders.UserAgent.ParseAdd("TickerLens/2.0");
    }

    public static async Task<Quote?> GetQuote(string symbol)
    {
        var url = "https://query1.finance.yahoo.com/v8/finance/chart/"
            + Uri.EscapeDataString(symbol) + "?range=1d&interval=5m";
        using var stream = await Http.GetStreamAsync(url);
        using var json = await JsonDocument.ParseAsync(stream);
        var result = json.RootElement.GetProperty("chart").GetProperty("result")[0];
        var meta = result.GetProperty("meta");
        var price = Number(meta, "regularMarketPrice");
        var previous = Number(meta, "chartPreviousClose");
        if (previous <= 0) previous = Number(meta, "previousClose");
        var closes = new List<double>();
        if (result.TryGetProperty("indicators", out var indicators)
            && indicators.TryGetProperty("quote", out var quotes)
            && quotes.GetArrayLength() > 0
            && quotes[0].TryGetProperty("close", out var closeArray))
            foreach (var item in closeArray.EnumerateArray())
                if (item.ValueKind == JsonValueKind.Number) closes.Add(item.GetDouble());

        return new Quote {
            Symbol = symbol.ToUpperInvariant(),
            Name = Text(meta, "longName", Text(meta, "shortName", symbol)),
            Price = price,
            Change = price - previous,
            ChangePercent = previous > 0 ? (price / previous - 1) * 100 : 0,
            High52 = Number(meta, "fiftyTwoWeekHigh"),
            Currency = Text(meta, "currency", "USD"),
            Spark = closes
        };
    }

    public static async Task<List<Headline>> GetNews(IEnumerable<string> symbols)
    {
        var output = new List<Headline>();
        foreach (var symbol in symbols.Take(8)) {
            try {
                var xml = await Http.GetStringAsync(
                    "https://finance.yahoo.com/rss/headline?s=" + Uri.EscapeDataString(symbol));
                var doc = XDocument.Parse(xml);
                foreach (var item in doc.Descendants("item").Take(3)) {
                    var title = item.Element("title")?.Value.Trim() ?? "";
                    if (title.Length == 0 || output.Any(x => x.Title == title)) continue;
                    output.Add(new Headline {
                        Title = title,
                        Link = item.Element("link")?.Value ?? "",
                        Publisher = "Yahoo Finance",
                        Time = DateTime.TryParse(item.Element("pubDate")?.Value, out var date)
                            ? Relative(date) : "",
                        Symbols = symbol,
                        Sentiment = Sentiment(title)
                    });
                }
            } catch { }
        }
        return output.Take(40).ToList();
    }

    private static string Sentiment(string title)
    {
        var value = title.ToLowerInvariant();
        string[] good = ["surge", "soar", "beat", "gain", "record", "growth", "rally", "upgrade"];
        string[] bad = ["tumble", "fall", "miss", "drop", "risk", "cut", "loss", "downgrade", "crash"];
        var score = good.Count(value.Contains) - bad.Count(value.Contains);
        return score > 0 ? "Good" : score < 0 ? "Bad" : "Neutral";
    }

    private static string Relative(DateTime value)
    {
        var age = DateTimeOffset.Now - value;
        return age.TotalMinutes < 60 ? $"{Math.Max(1, (int)age.TotalMinutes)}m"
            : age.TotalHours < 24 ? $"{(int)age.TotalHours}h" : $"{(int)age.TotalDays}d";
    }

    private static double Number(JsonElement e, string key) =>
        e.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetDouble() : 0;
    private static string Text(JsonElement e, string key, string fallback) =>
        e.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.String
            ? v.GetString() ?? fallback : fallback;
}
