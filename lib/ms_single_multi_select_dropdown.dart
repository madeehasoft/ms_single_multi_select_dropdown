import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// ------------------ CONTROLLER ------------------
/// Controller for managing focus and selection state of [MsDropSingleMultiSelector].
///
/// Provides access to selected items, focus control, and input text.
class MsDropController {
  /// Focus node used to manage keyboard focus for the dropdown.
  final FocusNode focusNode = FocusNode();

  /// Currently selected item in single-select mode.
  MsClass? selectedSingle;

  /// Currently selected items in multi-select mode.
  List<MsClass> selectedMulti = [];

  /// Text input from the search field.
  String text = "";

  /// Optional callback to notify the widget to rebuild
  VoidCallback? notifyClear;

  bool _disposed = false;

  /// Requests focus for the dropdown input field.
  void requestFocus() {
    if (!_disposed) focusNode.requestFocus();
  }

  /// Removes focus from the dropdown input field.
  void unfocus() {
    if (!_disposed) focusNode.unfocus();
  }

  /// Disposes the focus node. Safe to call more than once.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    notifyClear = null;
    focusNode.dispose();
  }

  /// Returns true if any item is selected.
  bool get isSelected => selectedSingle != null || selectedMulti.isNotEmpty;

  /// ------------------ CLEAR ------------------
  void clear() {
    selectedSingle = null;
    selectedMulti = <MsClass>[];
    text = "";

    // Notify the widget to rebuild
    notifyClear?.call();
  }

  /// Programmatically select a single item and update the widget
  void selectSingleItem(MsClass item) {
    selectedSingle = item;
    text = item.name;
    notifyClear?.call(); // triggers UI refresh
  }

  /// Programmatically select multiple items
  void selectMultiItems(List<MsClass> items) {
    selectedMulti = List<MsClass>.of(items);
    selectedSingle = null;
    notifyClear?.call(); // triggers _onControllerClear
  }

  /// Forces the attached widget to refresh from the controller state.
  void refreshUI() {
    notifyClear?.call();
  }
}

/// ------------------ MODEL ------------------
/// Represents a selectable item in the dropdown.
///
/// Includes optional prefix and suffix codes for categorization or metadata.
class MsClass {
  /// Prefix code used for grouping or filtering.
  final String? prefixCode;

  /// Display name of the item.
  final String name;

  /// Suffix code used for additional metadata.
  final String? suffixCode;

  /// Creates a new [MsClass] with the given prefix, name, and suffix.
  const MsClass({
    this.prefixCode,
    required this.name,
    this.suffixCode,
  });

  @override
  bool operator ==(Object other) =>
      other is MsClass &&
      prefixCode == other.prefixCode &&
      name == other.name &&
      suffixCode == other.suffixCode;

  @override
  int get hashCode => Object.hash(prefixCode, name, suffixCode);
}

/// ------------------ MULTI-SELECT HELPER MODELS ------------------
/// Data + callbacks handed to [MsDropSingleMultiSelector.multiActionsBuilder]
/// so a client can build the bottom action bar completely by themselves.
class MsMultiActions {
  /// Number of currently selected items.
  final int selectedCount;

  /// Number of items currently visible in the list (after search filter).
  final int visibleCount;

  /// True when every visible item is selected.
  final bool allVisibleSelected;

  /// Select (or unselect, if all are already selected) every visible item.
  final VoidCallback toggleAll;

  /// Opens the "selected items" dialog. Null when nothing is selected.
  final VoidCallback? view;

  /// Closes the dropdown and fires `onSubmittedMulti`.
  final VoidCallback done;

  const MsMultiActions({
    required this.selectedCount,
    required this.visibleCount,
    required this.allVisibleSelected,
    required this.toggleAll,
    required this.view,
    required this.done,
  });
}

/// Data + callbacks handed to [MsDropSingleMultiSelector.selectedDialogBuilder]
/// so a client can build the "selected items" dialog completely by themselves.
class MsSelectedDialogData {
  /// The currently selected items.
  final List<MsClass> selected;

  /// Unselect one item.
  final void Function(MsClass item) remove;

  /// Unselect everything.
  final VoidCallback clearAll;

  /// Close the dialog.
  final VoidCallback close;

  const MsSelectedDialogData({
    required this.selected,
    required this.remove,
    required this.clearAll,
    required this.close,
  });
}

/// ------------------ MAIN WIDGET ------------------
/// A customizable dropdown widget supporting single and multi-select modes.
///
/// Includes keyboard navigation, search, and styling options.
class MsDropSingleMultiSelector extends StatefulWidget {
  /// List of items to display in the dropdown.
  final List<MsClass> items;

  /// Enables multi-select mode if true.
  final bool multiSelect;

  /// Callback when a single item is selected.
  final void Function(MsClass?)? onChangedSingle;

  /// Callback when multiple items are selected.
  final void Function(List<MsClass>)? onChangedMulti;

  /// Callback when Enter is pressed in single-select mode.
  final void Function(MsClass?)? onSubmittedSingle;

  /// Callback when Enter is pressed in multi-select mode.
  final void Function(List<MsClass>)? onSubmittedMulti;

  /// Callback when clear icon is tapped
  final VoidCallback? onClearTapped;

  /// Optional controller to manage focus and selection externally.
  final MsDropController? controller;

  /// Width of the dropdown trigger widget (num).
  final dynamic dropdownWidth;

  /// Width of the dropdown menu (num).
  final dynamic dropdownMenuWidth;

  /// Height for the input field.
  final double? dropdownHeight;

  /// Style for the text field input.
  final TextStyle? searchFieldStyle;

  /// Style for dropdown items.
  final TextStyle? dropdownItemStyle;

  /// Style for prefix text in dropdown items.
  final TextStyle? dropdownItemPrefixStyle;

  /// Style for suffix text in dropdown items.
  final TextStyle? dropdownItemSuffixStyle;

  /// Style for the trigger button text.
  final TextStyle? buttonTextStyle;

  /// Style for the multi-select action buttons.
  final ButtonStyle? buttonStyle;

  /// Hint text for the input field.
  final String? searchFieldHint;

  /// Icon shown for search functionality.
  final Icon? searchIcon;

  /// Icon shown for opening the dropdown menu.
  final Icon? menuIcon;

  /// Icon shown for clearing the selection.
  final Icon? clearIcon;

  /// Background color of the text field.
  final Color? searchFieldBackgroundColor;

  /// Background color for highlighted dropdown items.
  final Color? dropdownItemHighlightColor;

  /// Background color of the dropdown menu.
  final Color? dropdownBackgroundColor;

  /// showPrefixCode.
  final bool showPrefixCode;

  /// showSuffixCode.
  final bool showSuffixCode;

  /// Border radius for the input field
  final double? searchFieldBorderRadius;

  /// Focused border color for the input field
  final Color? searchFieldFocusedBorderColor;

  /// Focused border width for the input field
  final double? searchFieldFocusedBorderWidth;

  /// Enabled border color for the input field
  final Color? searchFieldEnabledBorderColor;

  /// Enabled border width for the input field
  final double? searchFieldEnabledBorderWidth;

  // ---------- Multi-select bottom action bar (all optional) ----------

  /// Label of the "Check All" button. Default: `Check All`.
  final String? checkAllText;

  /// Label of the "Uncheck All" button. Default: `Uncheck All`.
  final String? uncheckAllText;

  /// Label of the "View" button. Default: `View`.
  final String? viewText;

  /// Label of the "Done" button. Default: `Done`.
  final String? doneText;

  /// Append the selected count to the View button, e.g. `View (3)`.
  final bool showViewCount;

  /// Style override for the "Check All / Uncheck All" button.
  final ButtonStyle? checkAllButtonStyle;

  /// Style override for the "View" button.
  final ButtonStyle? viewButtonStyle;

  /// Style override for the "Done" button.
  final ButtonStyle? doneButtonStyle;

  /// Height reserved for the bottom action bar. Default: 56.
  final double? multiActionsHeight;

  /// Fully replace the bottom action bar with your own widget.
  final Widget Function(BuildContext context, MsMultiActions actions)?
      multiActionsBuilder;

  // ---------- "Selected items" dialog (all optional) ----------

  /// Dialog title. Default: `Selected Items`.
  final String? selectedDialogTitle;

  /// Builds the sub-title text, e.g. `3 selected`.
  final String Function(int count)? selectedDialogCountText;

  /// Text of the dialog close button. Default: `Close`.
  final String? selectedDialogCloseText;

  /// Text of the dialog "clear all" button. Default: `Clear All`.
  final String? selectedDialogClearAllText;

  /// Text shown when nothing is selected. Default: `No items selected`.
  final String? selectedDialogEmptyText;

  /// Hint of the search box inside the dialog.
  final String? selectedDialogSearchHint;

  /// Show a search box inside the dialog when the list is long.
  final bool selectedDialogShowSearch;

  /// Dialog width. Default: min(460, 90% of screen).
  final double? selectedDialogWidth;

  /// Dialog max height. Default: 70% of screen.
  final double? selectedDialogMaxHeight;

  /// Dialog background color.
  final Color? selectedDialogBackgroundColor;

  /// Accent color (header icon, code chips, close button).
  final Color? selectedDialogAccentColor;

  /// Dialog shape (e.g. different corner radius).
  final ShapeBorder? selectedDialogShape;

  /// Dialog title style.
  final TextStyle? selectedDialogTitleStyle;

  /// Style of each item name in the dialog.
  final TextStyle? selectedDialogItemStyle;

  /// Fully replace the dialog. Return a `Dialog` / `AlertDialog` / any widget.
  final Widget Function(BuildContext context, MsSelectedDialogData data)?
      selectedDialogBuilder;

  /// Creates a new [MsDropSingleMultiSelector] widget.
  const MsDropSingleMultiSelector({
    super.key,
    required this.items,
    this.multiSelect = false,
    this.onChangedSingle,
    this.onChangedMulti,
    this.onSubmittedSingle,
    this.onSubmittedMulti,
    this.controller,
    this.dropdownWidth,
    this.dropdownMenuWidth,
    this.searchFieldStyle,
    this.dropdownItemStyle,
    this.buttonTextStyle,
    this.buttonStyle,
    this.dropdownItemPrefixStyle,
    this.dropdownItemSuffixStyle,
    this.searchFieldHint,
    this.searchIcon,
    this.menuIcon,
    this.clearIcon,
    this.searchFieldBackgroundColor,
    this.dropdownItemHighlightColor,
    this.dropdownBackgroundColor,
    this.dropdownHeight,
    this.onClearTapped,
    this.showPrefixCode = false,
    this.showSuffixCode = false,
    this.searchFieldBorderRadius,
    this.searchFieldFocusedBorderColor,
    this.searchFieldFocusedBorderWidth,
    this.searchFieldEnabledBorderColor,
    this.searchFieldEnabledBorderWidth,
    this.checkAllText,
    this.uncheckAllText,
    this.viewText,
    this.doneText,
    this.showViewCount = true,
    this.checkAllButtonStyle,
    this.viewButtonStyle,
    this.doneButtonStyle,
    this.multiActionsHeight,
    this.multiActionsBuilder,
    this.selectedDialogTitle,
    this.selectedDialogCountText,
    this.selectedDialogCloseText,
    this.selectedDialogClearAllText,
    this.selectedDialogEmptyText,
    this.selectedDialogSearchHint,
    this.selectedDialogShowSearch = true,
    this.selectedDialogWidth,
    this.selectedDialogMaxHeight,
    this.selectedDialogBackgroundColor,
    this.selectedDialogAccentColor,
    this.selectedDialogShape,
    this.selectedDialogTitleStyle,
    this.selectedDialogItemStyle,
    this.selectedDialogBuilder,
  });

  @override
  State<MsDropSingleMultiSelector> createState() =>
      _MsDropSingleMultiSelectorState();
}

class _MsDropSingleMultiSelectorState extends State<MsDropSingleMultiSelector> {
  bool isOpen = false;

  bool get hasSelected {
    if (widget.multiSelect) return selectedMulti.isNotEmpty;
    return selectedSingle != null;
  }

  String get searchFieldHint => widget.searchFieldHint ?? "Search...";

  TextStyle get searchFieldStyle =>
      widget.searchFieldStyle ??
      const TextStyle(fontSize: 14, color: Colors.black);

  TextStyle get dropdownItemStyle =>
      widget.dropdownItemStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  TextStyle get dropdownItemPrefixStyle =>
      widget.dropdownItemPrefixStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  TextStyle get dropdownItemSufixStyle =>
      widget.dropdownItemSuffixStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  TextStyle get buttonTextStyle =>
      widget.buttonTextStyle ??
      const TextStyle(fontSize: 14, color: Colors.black87);

  /// Optional client style applied to all three action buttons.
  ButtonStyle? get buttonStyle => widget.buttonStyle;

  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  late final FocusNode _keyboardNode;
  late final TextEditingController _searchCtrl;

  /// Stable reference so we can safely compare/unbind from the controller.
  late final VoidCallback _clearListener = _onControllerClear;

  List<MsClass> filtered = [];
  Set<MsClass> selectedMulti = {};
  MsClass? selectedSingle;
  int highlighted = 0;

  OverlayEntry? _overlayEntry;

  final LayerLink _layerLink = LayerLink();
  final ScrollController listController = ScrollController();
  static const double itemHeight = 48;

  // ------------------ LIFECYCLE ------------------

  @override
  void initState() {
    super.initState();

    _acquireFocusNode();
    _keyboardNode = FocusNode(skipTraversal: true);
    _searchCtrl = TextEditingController();

    filtered = List.from(widget.items);

    // Adopt anything already selected on the controller (e.g. set before the
    // widget was built) and listen for later changes.
    _bindController(widget.controller);
    highlighted = _initialHighlight();
  }

  @override
  void didUpdateWidget(covariant MsDropSingleMultiSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.controller, widget.controller)) {
      _unbindController(oldWidget.controller);

      final oldNode = _focusNode;
      final oldOwned = _ownsFocusNode;
      _acquireFocusNode();
      if (oldOwned) {
        // Dispose after the TextField has stopped listening to it.
        WidgetsBinding.instance.addPostFrameCallback((_) => oldNode.dispose());
      }

      _bindController(widget.controller);
    }

    if (oldWidget.multiSelect != widget.multiSelect) {
      selectedSingle = null;
      selectedMulti = {};
      _syncTextFromSelection();
    }

    if (!listEquals(oldWidget.items, widget.items)) {
      _refilter();
      _refreshOverlay();
    }
  }

  @override
  void dispose() {
    // Remove overlay WITHOUT touching setState / text controller.
    _removeOverlay(notify: false);

    _unbindController(widget.controller);

    _keyboardNode.dispose();
    _searchCtrl.dispose();
    if (_ownsFocusNode) _focusNode.dispose();

    // The overlay entry may still be mounted until the end of this frame
    // (OverlayEntry.remove() defers while the tree is being finalized), and
    // its ListView still uses this controller. Dispose it after the frame.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => listController.dispose());

    super.dispose();
  }

  void _acquireFocusNode() {
    final c = widget.controller;
    if (c != null) {
      _focusNode = c.focusNode;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
  }

  void _bindController(MsDropController? c) {
    if (c == null) return;
    c.notifyClear = _clearListener;
    selectedSingle = c.selectedSingle;
    selectedMulti = c.selectedMulti.toSet();
    _syncTextFromSelection();
  }

  void _unbindController(MsDropController? c) {
    if (c != null && identical(c.notifyClear, _clearListener)) {
      c.notifyClear = null;
    }
  }

  // ------------------ HELPERS ------------------

  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  bool get _inBuildPhase =>
      SchedulerBinding.instance.schedulerPhase ==
      SchedulerPhase.persistentCallbacks;

  /// Text shown in the field when the dropdown is closed.
  String _labelText() {
    if (widget.multiSelect) {
      return selectedMulti.isNotEmpty
          ? 'Selected Item (${selectedMulti.length})'
          : '';
    }
    return selectedSingle?.name ?? '';
  }

  /// Sets the field text and parks the caret at the end (assigning `.text`
  /// directly leaves an invalid selection).
  void _setSearchText(String t) {
    _searchCtrl.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  void _syncTextFromSelection() => _setSearchText(_labelText());

  int _initialHighlight() {
    if (filtered.isEmpty) return -1;
    if (widget.multiSelect) {
      if (selectedMulti.isNotEmpty) {
        final i = filtered.indexOf(selectedMulti.last);
        if (i != -1) return i;
      }
      return 0;
    }
    if (selectedSingle != null) {
      final i = filtered.indexOf(selectedSingle!);
      if (i != -1) return i;
    }
    return 0;
  }

  List<MsClass> _filterItems(String q) {
    final qq = q.toLowerCase();
    return widget.items
        .where((e) =>
            e.name.toLowerCase().contains(qq) ||
            (e.prefixCode ?? "").toLowerCase().contains(qq) ||
            (e.suffixCode ?? "").toLowerCase().contains(qq))
        .toList();
  }

  void _refilter() {
    final text = _searchCtrl.text;
    // The summary label ("Selected Item (2)" / the item name) is not a search.
    final showAll =
        text.isEmpty || _overlayEntry == null || text == _labelText();
    filtered = showAll ? List.from(widget.items) : _filterItems(text);
    highlighted = filtered.isEmpty
        ? -1
        : (highlighted < 0 ? 0 : math.min(highlighted, filtered.length - 1));
  }

  /// Rebuilds the overlay safely (never during a build phase).
  void _refreshOverlay() {
    if (_overlayEntry == null) return;
    if (_inBuildPhase) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlayEntry?.markNeedsBuild();
      });
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _requestFocusLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // ------------------ CONTROLLER CALLBACK ------------------

  void _onControllerClear() {
    if (!mounted) return;

    void apply() {
      if (!mounted) return;
      setState(() {
        selectedSingle = widget.controller?.selectedSingle;
        selectedMulti = widget.controller?.selectedMulti.toSet() ?? {};
        _syncTextFromSelection();

        filtered = List.from(widget.items);
        highlighted = _initialHighlight();
      });
      _refreshOverlay();
    }

    // Controller methods may be called while the framework is building.
    if (_inBuildPhase) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  // ------------------ OVERLAY ------------------

  /// [fromTyping]: the list was already filtered by the text the user typed,
  /// so the filter / highlight must not be reset.
  void _showOverlay({bool fromTyping = false}) {
    if (!mounted || _overlayEntry != null) return;

    if (!fromTyping) {
      filtered = List.from(widget.items);
      highlighted = _initialHighlight();
    }

    final entry = _createOverlay();
    _overlayEntry = entry;
    Overlay.of(context).insert(entry);
    isOpen = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) scrollToHighlighted();
    });
  }

  /// Removes the dropdown overlay.
  ///
  /// When [notify] is false (used from [dispose]) no setState / controller
  /// access happens, which avoids "setState on a defunct element" asserts.
  void _removeOverlay({bool notify = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;

    if (entry != null) {
      try {
        entry.remove();
      } catch (_) {}
      try {
        entry.dispose();
      } catch (_) {}
    }

    filtered = List.from(widget.items);
    highlighted = filtered.isNotEmpty ? 0 : -1;

    if (!notify || !mounted) return;

    _syncTextFromSelection();
    widget.controller?.text = _searchCtrl.text;
    if (isOpen) setState(() => isOpen = false);
  }

  double get _footerHeight => widget.multiActionsHeight ?? 56;

  double _desiredListHeight() {
    const double minHeight = 60;
    final double multiSelectButtonsHeight = _footerHeight;
    const double extraPadding = 16;

    double h = filtered.isNotEmpty
        ? filtered.length * itemHeight + extraPadding
        : minHeight;

    if (widget.multiSelect) {
      h += multiSelectButtonsHeight;
      if (filtered.isEmpty) h = multiSelectButtonsHeight + extraPadding;
    }
    return h;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (overlayContext) {
        if (!mounted) return const SizedBox.shrink();

        final ro = context.findRenderObject();
        if (ro is! RenderBox || !ro.attached || !ro.hasSize) {
          return const SizedBox.shrink();
        }

        final size = ro.size;
        final offset = ro.localToGlobal(Offset.zero);
        final media = MediaQuery.of(overlayContext);
        // Keyboard aware: don't count the area covered by the on-screen keyboard.
        final screenHeight = media.size.height - media.viewInsets.bottom;

        const double minHeight = 60;
        const double defaultMaxHeight = 300;

        final spaceBelow = screenHeight - offset.dy - size.height - 8;
        final spaceAbove = offset.dy - 8;
        final needed = _desiredListHeight();

        // Flip above the field when there is not enough room below.
        final showAbove = needed > spaceBelow && spaceAbove > spaceBelow;
        final available = showAbove ? spaceAbove : spaceBelow;
        final maxHeight =
            available.clamp(minHeight, defaultMaxHeight).toDouble();
        final height = needed.clamp(minHeight, maxHeight).toDouble();

        final menuWidth = _toDouble(widget.dropdownMenuWidth) ?? size.width;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Tap anywhere outside the dropdown
            _focusNode.unfocus();
            _removeOverlay();
          },
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                width: menuWidth,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: showAbove
                      ? Offset(0, -height - 4)
                      : Offset(0, size.height + 4),
                  child: Material(
                    elevation: 4,
                    color: widget.dropdownBackgroundColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: showAbove
                          ? Duration.zero
                          : const Duration(milliseconds: 150),
                      height: height,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(child: buildDropdownList()),
                          if (widget.multiSelect)
                            _buildMultiButtons(overlayContext),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleAllVisible() {
    final allVisibleSelected =
        filtered.isNotEmpty && filtered.every((i) => selectedMulti.contains(i));

    setState(() {
      if (allVisibleSelected) {
        selectedMulti.removeWhere((e) => filtered.contains(e));
      } else {
        selectedMulti.addAll(filtered);
      }

      widget.controller?.selectedMulti = selectedMulti.toList();
      _searchCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchCtrl.text.length,
      );
    });
    widget.onChangedMulti?.call(selectedMulti.toList());

    _requestFocusLater();
    _refreshOverlay();
  }

  void _finishMulti() {
    _focusNode.unfocus();
    _removeOverlay();
    widget.onSubmittedMulti?.call(selectedMulti.toList());
  }

  /// Bottom action bar of the multi-select dropdown.
  Widget _buildMultiButtons(BuildContext ctx) {
    final allVisibleSelected =
        filtered.isNotEmpty && filtered.every((i) => selectedMulti.contains(i));
    final count = selectedMulti.length;

    // ----- 100% custom footer supplied by the client -----
    if (widget.multiActionsBuilder != null) {
      return SizedBox(
        height: _footerHeight,
        child: widget.multiActionsBuilder!(
          ctx,
          MsMultiActions(
            selectedCount: count,
            visibleCount: filtered.length,
            allVisibleSelected: allVisibleSelected,
            toggleAll: _toggleAllVisible,
            view: count == 0 ? null : showSelectedDialog,
            done: _finishMulti,
          ),
        ),
      );
    }

    // ----- default professional footer -----
    final theme = Theme.of(ctx);
    final cs = theme.colorScheme;
    final textStyle = widget.buttonTextStyle ??
        const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600);

    ButtonStyle styled(ButtonStyle base, ButtonStyle? specific) {
      var r = base;
      if (buttonStyle != null) r = r.merge(buttonStyle);
      if (specific != null) r = r.merge(specific);
      return r;
    }

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
    const compact = EdgeInsets.symmetric(horizontal: 8);

    final outlinedBase = OutlinedButton.styleFrom(
      foregroundColor: cs.primary,
      side: BorderSide(color: cs.outlineVariant),
      shape: shape,
      padding: compact,
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final filledBase = FilledButton.styleFrom(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: shape,
      padding: compact,
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    Widget label(String t) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(t, style: textStyle, maxLines: 1),
        );

    final checkAllLabel = allVisibleSelected
        ? (widget.uncheckAllText ?? 'Uncheck All')
        : (widget.checkAllText ?? 'Check All');
    final viewLabel =
        '${widget.viewText ?? 'View'}${widget.showViewCount ? ' ($count)' : ''}';

    return SizedBox(
      height: _footerHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: styled(outlinedBase, widget.checkAllButtonStyle),
                  onPressed: _toggleAllVisible,
                  icon: Icon(
                    allVisibleSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 16,
                  ),
                  label: label(checkAllLabel),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: styled(outlinedBase, widget.viewButtonStyle),
                  onPressed: count == 0 ? null : showSelectedDialog,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: label(viewLabel),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FilledButton.icon(
                  style: styled(filledBase, widget.doneButtonStyle),
                  onPressed: _finishMulti,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: label(widget.doneText ?? 'Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ------------------ Dropdown List ------------------
  Widget buildDropdownList() {
    if (filtered.isEmpty) {
      return const Center(child: Text("No results"));
    }

    return ListView.builder(
      controller: listController,
      itemExtent: itemHeight,
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final e = filtered[i];
        final bool isHighlighted = i == highlighted;
        final bool isSelected = widget.multiSelect
            ? selectedMulti.contains(e)
            : selectedSingle == e;

        return InkWell(
          onTap: () {
            if (widget.multiSelect) {
              toggleMulti(e);
              setState(() => highlighted = i);
              _requestFocusLater();
              _refreshOverlay();
            } else {
              selectSingle(e);
              widget.onSubmittedSingle?.call(selectedSingle);
            }
          },
          child: Container(
            color: isHighlighted
                ? widget.dropdownItemHighlightColor ?? Colors.blue.shade100
                : widget.dropdownBackgroundColor ?? Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                if (widget.showPrefixCode)
                  Text(e.prefixCode ?? "", style: dropdownItemPrefixStyle),
                if (widget.showPrefixCode) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.name,
                    style: dropdownItemStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.showSuffixCode) const SizedBox(width: 6),
                if (widget.showSuffixCode)
                  Text(e.suffixCode ?? "", style: dropdownItemSufixStyle),
                if (widget.multiSelect) const SizedBox(width: 8),
                if (widget.multiSelect)
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ------------------ Keyboard Support ------------------
  KeyEventResult handleRawKey(KeyEvent event) {
    final isDown = event is KeyDownEvent;
    final isRepeat = event is KeyRepeatEvent;
    if (!isDown && !isRepeat) return KeyEventResult.ignored;

    // Only handle keys while the dropdown is open
    if (_overlayEntry == null) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isEnter = key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;

    // Escape works even when there are no results
    if (key == LogicalKeyboardKey.escape && isDown) {
      setState(() {
        if (widget.multiSelect) {
          selectedMulti.clear();
          widget.controller?.selectedMulti = <MsClass>[];
        } else {
          selectedSingle = null;
          widget.controller?.selectedSingle = null;
        }
        _searchCtrl.clear();
        widget.controller?.text = "";
      });
      _focusNode.unfocus();
      _removeOverlay();
      if (widget.multiSelect) {
        widget.onChangedMulti?.call([]);
      } else {
        widget.onChangedSingle?.call(null);
      }
      return KeyEventResult.handled;
    }

    // Enter in multi-select closes + submits, even when the search has no results
    if (isEnter && isDown && widget.multiSelect) {
      _finishMulti();
      return KeyEventResult.handled;
    }

    if (filtered.isEmpty) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        highlighted = (highlighted + 1).clamp(0, filtered.length - 1);
      });
      scrollToHighlighted();
      _refreshOverlay();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        highlighted = (highlighted - 1).clamp(0, filtered.length - 1);
      });
      scrollToHighlighted();
      _refreshOverlay();
      return KeyEventResult.handled;
    }

    if (isEnter && isDown) {
      if (highlighted >= 0 && highlighted < filtered.length) {
        selectSingle(filtered[highlighted]); // also closes overlay
        widget.onSubmittedSingle?.call(selectedSingle);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.controlRight && isDown) {
      if (highlighted >= 0 &&
          highlighted < filtered.length &&
          widget.multiSelect) {
        toggleMulti(filtered[highlighted]);
        _refreshOverlay();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Scrolls only as far as needed to make the highlighted item visible
  /// (instead of snapping it to the top on every arrow press).
  void scrollToHighlighted() {
    if (highlighted < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !listController.hasClients) return;

      final pos = listController.position;
      final double top = highlighted * itemHeight;
      final double bottom = top + itemHeight;

      double? target;
      if (top < pos.pixels) {
        target = top;
      } else if (bottom > pos.pixels + pos.viewportDimension) {
        target = bottom - pos.viewportDimension;
      }
      if (target == null) return;

      listController.animateTo(
        target.clamp(0.0, pos.maxScrollExtent).toDouble(),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      );
    });
  }

  /// ------------------ Selection ------------------
  void toggleMulti(MsClass item) {
    setState(() {
      if (selectedMulti.contains(item)) {
        selectedMulti.remove(item);
      } else {
        selectedMulti.add(item);
      }

      widget.controller?.selectedMulti = selectedMulti.toList();

      // Nothing selected -> clear text and show all items again
      if (selectedMulti.isEmpty) {
        _searchCtrl.clear();
        widget.controller?.text = "";
        filtered = List.from(widget.items);
        highlighted = filtered.isNotEmpty ? 0 : -1;
      }
    });

    if (selectedMulti.isEmpty) _requestFocusLater();

    widget.onChangedMulti?.call(selectedMulti.toList());
    _refreshOverlay();
  }

  void selectSingle(MsClass item) {
    setState(() {
      selectedSingle = item;
      _setSearchText(item.name);
    });

    widget.controller?.text = item.name;
    widget.controller?.selectedSingle = item;

    _focusNode.unfocus();
    _removeOverlay();

    // Callback last: the parent may rebuild/dispose this widget.
    widget.onChangedSingle?.call(item);
  }

  void _removeSelectedItem(MsClass item) {
    if (!mounted) return;
    setState(() {
      selectedMulti.remove(item);
      widget.controller?.selectedMulti = selectedMulti.toList();
      _syncTextFromSelection();
    });
    widget.controller?.text = _searchCtrl.text;
    widget.onChangedMulti?.call(selectedMulti.toList());
  }

  void _clearAllSelected() {
    if (!mounted) return;
    setState(() {
      selectedMulti.clear();
      widget.controller?.selectedMulti = <MsClass>[];
      _searchCtrl.clear();
      filtered = List.from(widget.items);
      highlighted = filtered.isNotEmpty ? 0 : -1;
    });
    widget.controller?.text = "";
    widget.onChangedMulti?.call([]);
  }

  void showSelectedDialog() {
    _removeOverlay(); // Close the dropdown first
    if (!mounted) return;

    String query = '';
    final scroll = ScrollController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final data = MsSelectedDialogData(
              selected: selectedMulti.toList(),
              remove: (item) {
                _removeSelectedItem(item);
                setLocal(() {});
              },
              clearAll: () {
                _clearAllSelected();
                setLocal(() {});
              },
              close: () => Navigator.of(dialogContext).pop(),
            );

            if (widget.selectedDialogBuilder != null) {
              return widget.selectedDialogBuilder!(ctx, data);
            }
            return _buildDefaultSelectedDialog(
              ctx,
              data,
              query,
              scroll,
              (q) => setLocal(() => query = q),
            );
          },
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 400), scroll.dispose);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        _searchCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchCtrl.text.length,
        );
        if (filtered.isNotEmpty) highlighted = 0;
        _refreshOverlay();
      });
    });
  }

  Widget _buildDefaultSelectedDialog(
    BuildContext ctx,
    MsSelectedDialogData data,
    String query,
    ScrollController scroll,
    ValueChanged<String> onQuery,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    final textTheme = Theme.of(ctx).textTheme;
    final accent = widget.selectedDialogAccentColor ?? cs.primary;
    final screen = MediaQuery.of(ctx).size;

    final width =
        widget.selectedDialogWidth ?? math.min(460.0, screen.width * 0.9);
    final maxHeight = widget.selectedDialogMaxHeight ?? screen.height * 0.7;

    final q = query.trim().toLowerCase();
    final visible = q.isEmpty
        ? data.selected
        : data.selected
            .where((e) =>
                e.name.toLowerCase().contains(q) ||
                (e.prefixCode ?? '').toLowerCase().contains(q) ||
                (e.suffixCode ?? '').toLowerCase().contains(q))
            .toList();

    final showSearch =
        widget.selectedDialogShowSearch && data.selected.length > 6;

    final countText = widget.selectedDialogCountText != null
        ? widget.selectedDialogCountText!(data.selected.length)
        : '${data.selected.length} selected';

    final titleStyle = widget.selectedDialogTitleStyle ??
        (textTheme.titleMedium ?? const TextStyle(fontSize: 16))
            .copyWith(fontWeight: FontWeight.w700);
    final itemStyle = widget.selectedDialogItemStyle ??
        (textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
            .copyWith(fontWeight: FontWeight.w600);

    Widget emptyState() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: cs.outline),
              const SizedBox(height: 10),
              Text(
                widget.selectedDialogEmptyText ?? 'No items selected',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        );

    Widget row(MsClass e) {
      final hasPrefix = (e.prefixCode ?? '').isNotEmpty;
      final hasSuffix = (e.suffixCode ?? '').isNotEmpty;
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (hasPrefix) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.prefixCode!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                e.name,
                style: itemStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasSuffix) ...[
              const SizedBox(width: 8),
              Text(
                e.suffixCode!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 18, color: cs.outline),
              onPressed: () => data.remove(e),
            ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: widget.selectedDialogBackgroundColor ?? cs.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: widget.selectedDialogShape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------- header ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.checklist_rounded,
                          color: accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.selectedDialogTitle ?? 'Selected Items',
                            style: titleStyle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            countText,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: data.close,
                    ),
                  ],
                ),
              ),

              // ---------- search ----------
              if (showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    onChanged: onQuery,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText:
                          widget.selectedDialogSearchHint ?? 'Search selected…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

              const Divider(height: 1),

              // ---------- list ----------
              Flexible(
                child: visible.isEmpty
                    ? emptyState()
                    : Scrollbar(
                        controller: scroll,
                        thumbVisibility: visible.length > 6,
                        child: ListView.separated(
                          controller: scroll,
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) => row(visible[i]),
                        ),
                      ),
              ),

              const Divider(height: 1),

              // ---------- actions ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
                child: Row(
                  children: [
                    if (data.selected.isNotEmpty)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: cs.error),
                        onPressed: data.clearAll,
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(
                          widget.selectedDialogClearAllText ?? 'Clear All',
                        ),
                      ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: data.close,
                      child: Text(
                        widget.selectedDialogCloseText ?? 'Close',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ------------------ Widget Build ------------------
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardNode,
      onKeyEvent: (node, event) => handleRawKey(event),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          height: widget.dropdownHeight ?? 45,
          width: _toDouble(widget.dropdownWidth) ?? double.infinity,
          child: TextField(
            controller: _searchCtrl,
            focusNode: _focusNode,
            style: searchFieldStyle,
            onChanged: (v) {
              var text = v;

              // While closed, the field shows the summary label
              // ("Selected Item (2)" / item name). Typing must replace it,
              // not get appended to it (which would filter to "No results").
              if (_overlayEntry == null) {
                final label = _labelText();
                if (label.isNotEmpty && text != label && text.contains(label)) {
                  text = text.replaceFirst(label, '');
                  _setSearchText(text);
                }
              }

              setState(() {
                widget.controller?.text = text;
                applyFilter(text);
                if (_overlayEntry == null) {
                  _showOverlay(fromTyping: true);
                } else {
                  _refreshOverlay();
                }
              });
            },
            decoration: InputDecoration(
              hintText: searchFieldHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.searchFieldBorderRadius ?? 4.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.searchFieldBorderRadius ?? 4.0,
                ),
                borderSide: BorderSide(
                  color: widget.searchFieldEnabledBorderColor ??
                      Colors.grey.shade400,
                  width: widget.searchFieldEnabledBorderWidth ?? 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.searchFieldBorderRadius ?? 4.0,
                ),
                borderSide: BorderSide(
                  color: widget.searchFieldFocusedBorderColor ?? Colors.blue,
                  width: widget.searchFieldFocusedBorderWidth ?? 2.0,
                ),
              ),
              filled: true,
              fillColor: widget.searchFieldBackgroundColor ?? Colors.white,
              contentPadding: EdgeInsets.zero,
              prefixIcon: widget.searchIcon ?? const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CLEAR ICON (only when something is selected)
                  if (hasSelected)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (widget.multiSelect) {
                              selectedMulti.clear();
                              widget.controller?.selectedMulti = <MsClass>[];
                            } else {
                              selectedSingle = null;
                              widget.controller?.selectedSingle = null;
                            }

                            _searchCtrl.clear();
                            widget.controller?.text = "";
                            applyFilter("");
                          });

                          if (widget.multiSelect) {
                            widget.onChangedMulti?.call([]);
                          } else {
                            widget.onChangedSingle?.call(null);
                          }

                          _refreshOverlay();
                          widget.onClearTapped?.call();
                          _requestFocusLater();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: widget.clearIcon ??
                              const Icon(Icons.clear, size: 23),
                        ),
                      ),
                    ),

                  // DROPDOWN ICON (ROTATING)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        final opening = _overlayEntry == null;
                        if (opening) {
                          setState(() => _showOverlay());
                        } else {
                          _removeOverlay();
                        }

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _focusNode.requestFocus();
                          // Select the summary text so typing replaces it
                          if (opening) {
                            _searchCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _searchCtrl.text.length,
                            );
                          }
                        });
                      },
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeInOut,
                        turns: isOpen ? 0.50 : 0.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: widget.menuIcon ??
                              const Icon(Icons.arrow_drop_down, size: 23),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void applyFilter(String q) {
    filtered = _filterItems(q);
    highlighted = filtered.isNotEmpty ? 0 : -1;
    scrollToHighlighted();
  }
}
