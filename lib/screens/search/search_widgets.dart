import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/book.dart';
import '../../utils/favorites_manager.dart';

// ───────────── Small helpers: colours that work in light AND dark theme ─────────────
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color inkColor(BuildContext c) => _isDark(c) ? Colors.white : Colors.black;
Color onInkColor(BuildContext c) => _isDark(c) ? Colors.black : Colors.white;
Color lineColor(BuildContext c) =>
    _isDark(c) ? AppColors.darkBorder : AppColors.lightBorder;

// ───────────── Recommendation logic ─────────────
/// Gives every book a "score". Higher score = shown earlier under "Recommended".
/// 1) how well it matches the typed words
/// 2) is it similar to books the user recently opened
/// 3) is it still available
int relevanceScore(Book b, String query) {
  var score = 0;
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    final title = b.title.toLowerCase();
    if (title.startsWith(q)) {
      score += 5;
    } else if (title.contains(q)) {
      score += 3;
    }
    if (b.author.toLowerCase().contains(q)) score += 2;
    if (b.subject.toLowerCase().contains(q)) score += 2;
  }
  for (final seen in FavoritesManager.instance.recentlyViewed) {
    if (seen.id == b.id) continue;
    if (seen.subject == b.subject) score += 2;
    if (seen.department == b.department) score += 1;
  }
  if (b.available) score += 1;
  return score;
}

// ───────────── Rounded chip (used for topics, filters, sort) ─────────────
class PillChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool selected; // black filled
  final bool hot; // shows the 🔥
  final bool soft; // light-grey style (used in the results filter row)
  final bool showArrow;

  const PillChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.hot = false,
    this.soft = false,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final ink = inkColor(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final Color fill = selected
        ? ink
        : soft
            ? (dark ? AppColors.darkSurface : const Color(0xFFF1F1F1))
            : Colors.transparent;

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: (selected || soft)
            ? BorderSide.none
            : BorderSide(color: lineColor(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? onInkColor(context) : ink,
                ),
              ),
              if (hot) ...[
                const SizedBox(width: 4),
                const Text('🔥', style: TextStyle(fontSize: 13)),
              ],
              if (showArrow) ...[
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down,
                    size: 18, color: selected ? onInkColor(context) : ink),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── Section heading ─────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ───────────── Search bar: back arrow + rounded box + black search button ─────────────
class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final Widget? trailing;
  final String hint;

  const SearchBox({
    super.key,
    required this.controller,
    required this.onBack,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.trailing,
    this.hint = 'Search by title, author, or subject',
  });

  @override
  Widget build(BuildContext context) {
    final ink = inkColor(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: ink),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: TextField(
                        controller: controller,
                        readOnly: readOnly,
                        autofocus: autofocus,
                        onTap: onTap,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: hint,
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Material(
                      color: ink,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => (onSubmitted ?? (_) {})(controller.text),
                        child: SizedBox(
                          width: 52,
                          height: 38,
                          child: Icon(Icons.search, color: onInkColor(context)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
