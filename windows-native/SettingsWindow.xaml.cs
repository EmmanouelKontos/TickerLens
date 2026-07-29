namespace TickerLens.Native;

public partial class SettingsWindow : Window
{
    public Settings Result { get; private set; }
    public SettingsWindow(Settings settings)
    {
        InitializeComponent();
        Result = settings;
        SymbolsBox.Text = settings.Symbols;
        RefreshBox.Text = settings.RefreshMinutes.ToString();
        TopmostBox.IsChecked = settings.AlwaysOnTop;
    }
    private void SaveClick(object sender, RoutedEventArgs e)
    {
        Result = new Settings {
            Symbols = SymbolsBox.Text.Trim(),
            RefreshMinutes = int.TryParse(RefreshBox.Text, out var value) ? Math.Clamp(value, 1, 1440) : 5,
            AlwaysOnTop = TopmostBox.IsChecked == true
        };
        DialogResult = true;
    }
}
