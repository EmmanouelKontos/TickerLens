using System.Windows.Media;

namespace TickerLens.Native;

public sealed class Sparkline : FrameworkElement
{
    public static readonly DependencyProperty ValuesProperty = DependencyProperty.Register(
        nameof(Values), typeof(List<double>), typeof(Sparkline),
        new FrameworkPropertyMetadata(null, FrameworkPropertyMetadataOptions.AffectsRender));
    public static readonly DependencyProperty PositiveProperty = DependencyProperty.Register(
        nameof(Positive), typeof(bool), typeof(Sparkline),
        new FrameworkPropertyMetadata(true, FrameworkPropertyMetadataOptions.AffectsRender));
    public List<double>? Values { get => (List<double>?)GetValue(ValuesProperty); set => SetValue(ValuesProperty, value); }
    public bool Positive { get => (bool)GetValue(PositiveProperty); set => SetValue(PositiveProperty, value); }

    protected override void OnRender(DrawingContext dc)
    {
        var values = Values;
        if (values == null || values.Count < 2 || ActualWidth < 2 || ActualHeight < 2) return;
        var min = values.Min();
        var max = values.Max();
        var span = Math.Max(0.0001, max - min);
        var geometry = new StreamGeometry();
        using (var ctx = geometry.Open()) {
            for (var i = 0; i < values.Count; i++) {
                var p = new System.Windows.Point(i * ActualWidth / (values.Count - 1),
                    ActualHeight - (values[i] - min) / span * ActualHeight);
                if (i == 0) ctx.BeginFigure(p, false, false); else ctx.LineTo(p, true, false);
            }
        }
        geometry.Freeze();
        dc.DrawGeometry(null, new System.Windows.Media.Pen(
            new SolidColorBrush((System.Windows.Media.Color)System.Windows.Media.ColorConverter.ConvertFromString(
                Positive ? "#42D77D" : "#FF5A61")), 1.7), geometry);
    }
}
