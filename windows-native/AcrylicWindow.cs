using System.Runtime.InteropServices;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Shell;

namespace TickerLens.Native;

public class AcrylicWindow : Window
{
    private bool _realClose;

    public AcrylicWindow()
    {
        WindowStyle = WindowStyle.None;
        AllowsTransparency = false;
        Background = System.Windows.Media.Brushes.Transparent;
        ShowInTaskbar = false;
        ResizeMode = ResizeMode.CanResize;
        WindowChrome.SetWindowChrome(this, new WindowChrome {
            CaptionHeight = 0,
            CornerRadius = new CornerRadius(22),
            GlassFrameThickness = new Thickness(-1),
            ResizeBorderThickness = new Thickness(7),
            UseAeroCaptionButtons = false
        });
        SourceInitialized += (_, _) => ApplyBackdrop();
        Loaded += (_, _) => Dispatcher.BeginInvoke(
            System.Windows.Threading.DispatcherPriority.Loaded,
            new Action(ApplyBackdrop));
        Closing += (_, e) => {
            if (!_realClose) { e.Cancel = true; Hide(); }
        };
    }

    public void CloseForReal() { _realClose = true; Close(); }

    protected void DragHeader(object sender, System.Windows.Input.MouseButtonEventArgs e)
    {
        if (e.ChangedButton == System.Windows.Input.MouseButton.Left) DragMove();
    }

    private void ApplyBackdrop()
    {
        var source = (HwndSource)PresentationSource.FromVisual(this);
        source.CompositionTarget.BackgroundColor = Colors.Transparent;
        var hwnd = source.Handle;
        var dark = 1;
        var corner = 2;     // DWMWCP_ROUND
        var acrylic = 3;    // DWMSBT_TRANSIENTWINDOW
        DwmSetWindowAttribute(hwnd, 20, ref dark, 4);
        DwmSetWindowAttribute(hwnd, 33, ref corner, 4);
        DwmSetWindowAttribute(hwnd, 38, ref acrylic, 4);
        var margins = new Margins { Left = -1, Right = -1, Top = -1, Bottom = -1 };
        DwmExtendFrameIntoClientArea(hwnd, ref margins);

        // WPF can still present an opaque redirection surface even after a
        // successful DWMWA_SYSTEMBACKDROP_TYPE call. Applying the composition
        // accent to the HWND guarantees a real blurred desktop surface instead
        // of a merely translucent gray fill.
        var accent = new AccentPolicy {
            State = AccentState.EnableAcrylicBlurBehind,
            Flags = 2,
            GradientColor = 0x551C1818
        };
        var size = Marshal.SizeOf<AccentPolicy>();
        var pointer = Marshal.AllocHGlobal(size);
        try {
            Marshal.StructureToPtr(accent, pointer, false);
            var data = new CompositionAttributeData {
                Attribute = 19, // WCA_ACCENT_POLICY
                Data = pointer,
                SizeOfData = size
            };
            SetWindowCompositionAttribute(hwnd, ref data);
        } finally {
            Marshal.FreeHGlobal(pointer);
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Margins { public int Left, Right, Top, Bottom; }
    private enum AccentState {
        Disabled = 0,
        EnableBlurBehind = 3,
        EnableAcrylicBlurBehind = 4
    }
    [StructLayout(LayoutKind.Sequential)]
    private struct AccentPolicy {
        public AccentState State;
        public int Flags;
        public uint GradientColor;
        public int AnimationId;
    }
    [StructLayout(LayoutKind.Sequential)]
    private struct CompositionAttributeData {
        public int Attribute;
        public IntPtr Data;
        public int SizeOfData;
    }
    [DllImport("dwmapi.dll")] private static extern int DwmSetWindowAttribute(
        IntPtr hwnd, int attribute, ref int value, int size);
    [DllImport("dwmapi.dll")] private static extern int DwmExtendFrameIntoClientArea(
        IntPtr hwnd, ref Margins margins);
    [DllImport("user32.dll")] private static extern int SetWindowCompositionAttribute(
        IntPtr hwnd, ref CompositionAttributeData data);
}
