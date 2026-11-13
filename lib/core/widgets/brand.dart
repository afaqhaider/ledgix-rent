import 'package:material_ui/material_ui.dart';

/// Brand image paths.
abstract final class BrandAssets {
  static const logo = 'assets/ledgix-rent-logo.png'; // mark + "Rent"
  static const mark = 'assets/ledgix-rent-logo-mark.png'; // mark only

  /// Both PNGs are 740×812. A fixed width keeps layout stable before decode.
  static const aspect = 740 / 812;
}

/// The hexagon mark. The PNG keeps its 740×812 aspect ratio.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        BrandAssets.mark,
        height: size,
        width: size * BrandAssets.aspect,
        fit: BoxFit.contain,
        semanticLabel: 'LedGix Rent',
      );
}

/// Full logo (mark + "Rent") for the login screen.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) => Image.asset(
        BrandAssets.logo,
        height: height,
        width: height * BrandAssets.aspect,
        fit: BoxFit.contain,
        semanticLabel: 'LedGix Rent',
      );
}

/// App bar title with the logo mark in front (mirrors in RTL).
class BrandTitle extends StatelessWidget {
  const BrandTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const ExcludeSemantics(child: LogoMark(size: 28)),
        const SizedBox(width: 10),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ]);
}
