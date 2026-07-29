using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Windows.Threading;

namespace TickerLens.Native;

public partial class MainWindow : AcrylicWindow
{
    private readonly ObservableCollection<Quote> _quotes = [];
    private readonly DispatcherTimer _timer = new();
    private Settings _settings = Settings.Load();
    private bool _busy;

    public MainWindow()
    {
        InitializeComponent();
        QuoteList.ItemsSource = _quotes;
        Topmost = _settings.AlwaysOnTop;
        _timer.Tick += async (_, _) => await RefreshQuotes();
        Loaded += async (_, _) => {
            ConfigureTimer();
            await RefreshQuotes();
        };
    }

    private void ConfigureTimer()
    {
        _timer.Interval = TimeSpan.FromMinutes(Math.Max(1, _settings.RefreshMinutes));
        _timer.Start();
    }

    private async Task RefreshQuotes()
    {
        if (_busy) return;
        _busy = true;
        StatusText.Text = _quotes.Count == 0 ? "Loading…" : "Updating…";
        var symbols = _settings.Symbols.Split([',', ';', ' ', '\n'],
            StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(x => x.ToUpperInvariant()).Distinct().Take(40).ToArray();
        var results = await Task.WhenAll(symbols.Select(async symbol => {
            try { return await MarketService.GetQuote(symbol); } catch { return null; }
        }));
        _quotes.Clear();
        foreach (var quote in results.Where(x => x != null)) _quotes.Add(quote!);
        StatusText.Text = _quotes.Count == 0
            ? "Couldn’t load prices"
            : $"{_quotes.Count} symbols · {DateTime.Now:HH:mm:ss}";
        _busy = false;
    }

    private async void RefreshClick(object sender, RoutedEventArgs e) => await RefreshQuotes();

    private async void SettingsClick(object sender, RoutedEventArgs e)
    {
        var dialog = new SettingsWindow(_settings) { Owner = this };
        if (dialog.ShowDialog() != true) return;
        _settings = dialog.Result;
        _settings.Save();
        Topmost = _settings.AlwaysOnTop;
        ConfigureTimer();
        await RefreshQuotes();
    }

    private void QuoteClick(object sender, System.Windows.Input.MouseButtonEventArgs e)
    {
        if ((sender as FrameworkElement)?.DataContext is not Quote quote) return;
        Process.Start(new ProcessStartInfo(
            $"https://finance.yahoo.com/quote/{Uri.EscapeDataString(quote.Symbol)}") {
            UseShellExecute = true
        });
    }
}
