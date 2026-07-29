using System.Collections.ObjectModel;
using System.Diagnostics;

namespace TickerLens.Native;

public partial class NewsWindow : AcrylicWindow
{
    private readonly ObservableCollection<Headline> _items = [];
    public NewsWindow()
    {
        InitializeComponent();
        NewsList.ItemsSource = _items;
        IsVisibleChanged += async (_, _) => { if (IsVisible && _items.Count == 0) await RefreshNews(); };
    }

    private async Task RefreshNews()
    {
        StatusText.Text = "Loading…";
        var settings = Settings.Load();
        var symbols = settings.Symbols.Split([',', ';', ' ', '\n'],
            StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var items = await MarketService.GetNews(symbols);
        _items.Clear();
        foreach (var item in items) _items.Add(item);
        StatusText.Text = $"{_items.Count} headlines · {DateTime.Now:HH:mm:ss}";
    }
    private async void RefreshClick(object sender, RoutedEventArgs e) => await RefreshNews();
    private void HeadlineClick(object sender, System.Windows.Input.MouseButtonEventArgs e)
    {
        if ((sender as FrameworkElement)?.DataContext is Headline item && item.Link.Length > 0)
            Process.Start(new ProcessStartInfo(item.Link) { UseShellExecute = true });
    }
}
