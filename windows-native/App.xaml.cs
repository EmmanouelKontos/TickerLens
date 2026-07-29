using System.Threading;
using Forms = System.Windows.Forms;

namespace TickerLens.Native;

public partial class App : System.Windows.Application
{
    private Mutex? _mutex;
    private Forms.NotifyIcon? _tray;
    private MainWindow? _markets;
    private NewsWindow? _news;

    protected override void OnStartup(StartupEventArgs e)
    {
        _mutex = new Mutex(true, "TickerLens.Native.SingleInstance.v2", out var first);
        if (!first) { Shutdown(); return; }

        base.OnStartup(e);
        _markets = new MainWindow();
        _news = new NewsWindow();

        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("Show / Hide Markets", null, (_, _) => Toggle(_markets));
        menu.Items.Add("Show / Hide News", null, (_, _) => Toggle(_news));
        menu.Items.Add(new Forms.ToolStripSeparator());
        menu.Items.Add("Quit", null, (_, _) => Quit());
        _tray = new Forms.NotifyIcon {
            Icon = System.Drawing.Icon.ExtractAssociatedIcon(Environment.ProcessPath!),
            Text = "TickerLens",
            Visible = true,
            ContextMenuStrip = menu
        };
        _tray.MouseClick += (_, a) => {
            if (a.Button == Forms.MouseButtons.Left) Toggle(_markets);
        };

        _markets.Show();
    }

    private static void Toggle(Window window)
    {
        if (window.IsVisible) window.Hide();
        else { window.Show(); window.Activate(); }
    }

    private void Quit()
    {
        if (_tray != null) { _tray.Visible = false; _tray.Dispose(); }
        _markets?.CloseForReal();
        _news?.CloseForReal();
        Shutdown();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _tray?.Dispose();
        _mutex?.Dispose();
        base.OnExit(e);
    }
}
