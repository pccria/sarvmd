// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../core/theme/app_metrics.dart';
import '../../../l10n/app_localizations.dart';
import '../dialogs/document_properties_dialog.dart';

/// Sidebar & Touch Drawer settings group for Score Information & Typography.
///
/// Rationalized UX with progressive disclosure:
/// - Prominent primary credits (Title, Composer)
/// - Collapsible secondary contributor credits (Subtitle, Arranger, Lyricist)
///   with automatic expansion if any secondary field contains text
/// - Smooth animated master header switch collapse
/// - Live Gouldian engraving headroom indicator badge (mm clearance on Page 1)
/// - Reactive, state-aware visibility eye toggles (ghosted when empty, active when populated)
class ScoreTypographySettingsGroup extends StatefulWidget {
  const ScoreTypographySettingsGroup({
    super.key,
    required this.metadata,
    required this.onMetadataChanged,
  });

  final core.DocumentMetadata metadata;
  final ValueChanged<core.DocumentMetadata> onMetadataChanged;

  @override
  State<ScoreTypographySettingsGroup> createState() =>
      _ScoreTypographySettingsGroupState();
}

class _ScoreTypographySettingsGroupState
    extends State<ScoreTypographySettingsGroup> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _composerController;
  late final TextEditingController _arrangerController;
  late final TextEditingController _lyricistController;
  late final TextEditingController _copyrightController;

  late bool _isSecondaryExpanded;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.metadata.title);
    _subtitleController = TextEditingController(text: widget.metadata.subtitle);
    _composerController = TextEditingController(text: widget.metadata.composer);
    _arrangerController = TextEditingController(text: widget.metadata.arranger);
    _lyricistController = TextEditingController(text: widget.metadata.lyricist);
    _copyrightController = TextEditingController(text: widget.metadata.copyright);

    _isSecondaryExpanded = _hasSecondaryData(widget.metadata);
  }

  bool _hasSecondaryData(core.DocumentMetadata meta) {
    return meta.subtitle.trim().isNotEmpty ||
        meta.arranger.trim().isNotEmpty ||
        meta.lyricist.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(ScoreTypographySettingsGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metadata.title != _titleController.text) {
      _titleController.text = widget.metadata.title;
    }
    if (widget.metadata.subtitle != _subtitleController.text) {
      _subtitleController.text = widget.metadata.subtitle;
    }
    if (widget.metadata.composer != _composerController.text) {
      _composerController.text = widget.metadata.composer;
    }
    if (widget.metadata.arranger != _arrangerController.text) {
      _arrangerController.text = widget.metadata.arranger;
    }
    if (widget.metadata.lyricist != _lyricistController.text) {
      _lyricistController.text = widget.metadata.lyricist;
    }
    if (widget.metadata.copyright != _copyrightController.text) {
      _copyrightController.text = widget.metadata.copyright;
    }

    if (_hasSecondaryData(widget.metadata) && !_isSecondaryExpanded) {
      _isSecondaryExpanded = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _composerController.dispose();
    _arrangerController.dispose();
    _lyricistController.dispose();
    _copyrightController.dispose();
    super.dispose();
  }

  void _update(core.DocumentMetadata updated) {
    widget.onMetadataChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final meta = widget.metadata;
    final headroomMm = core.ScoreTypographyMetrics.computeHeaderHeadroomMm(meta);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10.0,
      children: [
        // ── 1. Master Header Block Switch ─────────────────────────────────────
        _SwitchRow(
          icon: Icons.view_headline_rounded,
          title: l10n.scoreTypographyHeaderBlock,
          subtitle: l10n.scoreTypographyHeaderBlockSubtitle,
          value: meta.showTitleBlock,
          onChanged: (val) => _update(meta.copyWith(showTitleBlock: val)),
        ),

        // ── 2. First-Page Header Block (Animated Collapse) ────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: meta.showTitleBlock
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8.0,
                  children: [
                    // Live Gouldian Headroom Readout Badge
                    _HeadroomBadge(
                      headroomMm: headroomMm,
                      l10n: l10n,
                    ),

                    // Primary Inputs: Title & Composer
                    _TypographyInputField(
                      controller: _titleController,
                      label: l10n.metadataScoreTitle,
                      hint: 'e.g. Autumn Leaves',
                      icon: Icons.title,
                      isVisible: meta.showTitle,
                      isEnabled: meta.showTitleBlock,
                      onChanged: (text) => _update(meta.copyWith(title: text)),
                      onVisibilityChanged: (vis) =>
                          _update(meta.copyWith(showTitle: vis)),
                    ),
                    _TypographyInputField(
                      controller: _composerController,
                      label: l10n.metadataComposer,
                      hint: 'e.g. J. S. Bach',
                      icon: Icons.person_outline,
                      isVisible: meta.showComposer,
                      isEnabled: meta.showTitleBlock,
                      onChanged: (text) =>
                          _update(meta.copyWith(composer: text)),
                      onVisibilityChanged: (vis) =>
                          _update(meta.copyWith(showComposer: vis)),
                    ),

                    // Progressive Disclosure Toggle for Additional Credits
                    _ProgressiveDisclosureButton(
                      isExpanded: _isSecondaryExpanded,
                      label: _isSecondaryExpanded
                          ? l10n.scoreTypographyLessCredits
                          : l10n.scoreTypographyMoreCredits,
                      hasActiveData: _hasSecondaryData(meta),
                      onTap: () {
                        setState(() {
                          _isSecondaryExpanded = !_isSecondaryExpanded;
                        });
                      },
                    ),

                    // Secondary Contributor Credits Accordion
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: _isSecondaryExpanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: 8.0,
                              children: [
                                _TypographyInputField(
                                  controller: _subtitleController,
                                  label: l10n.metadataSubtitle,
                                  hint: 'e.g. Op. 45, No. 2',
                                  icon: Icons.subtitles_outlined,
                                  isVisible: meta.showSubtitle,
                                  isEnabled: meta.showTitleBlock,
                                  onChanged: (text) =>
                                      _update(meta.copyWith(subtitle: text)),
                                  onVisibilityChanged: (vis) =>
                                      _update(meta.copyWith(showSubtitle: vis)),
                                ),
                                _TypographyInputField(
                                  controller: _arrangerController,
                                  label: l10n.metadataArranger,
                                  hint: 'e.g. Arranger',
                                  icon: Icons.music_note_outlined,
                                  isVisible: meta.showArranger,
                                  isEnabled: meta.showTitleBlock,
                                  onChanged: (text) =>
                                      _update(meta.copyWith(arranger: text)),
                                  onVisibilityChanged: (vis) =>
                                      _update(meta.copyWith(showArranger: vis)),
                                ),
                                _TypographyInputField(
                                  controller: _lyricistController,
                                  label: l10n.metadataLyricist,
                                  hint: 'e.g. Lyricist / Librettist',
                                  icon: Icons.edit_note_outlined,
                                  isVisible: meta.showLyricist,
                                  isEnabled: meta.showTitleBlock,
                                  onChanged: (text) =>
                                      _update(meta.copyWith(lyricist: text)),
                                  onVisibilityChanged: (vis) =>
                                      _update(meta.copyWith(showLyricist: vis)),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                )
              : _HeaderDisabledNotice(l10n: l10n),
        ),

        const Divider(height: 12),

        // ── 3. Page Numbers Switch ────────────────────────────────────────────
        _SwitchRow(
          icon: Icons.format_list_numbered_rounded,
          title: l10n.scoreTypographyPageNumbers,
          subtitle: l10n.scoreTypographyPageNumbersSubtitle,
          value: meta.showPageNumbers,
          onChanged: (val) => _update(meta.copyWith(showPageNumbers: val)),
        ),

        // ── 4. Copyright Field ────────────────────────────────────────────────
        _TypographyInputField(
          controller: _copyrightController,
          label: l10n.metadataCopyright,
          hint: 'e.g. © 2026 SarvMD',
          icon: Icons.copyright_outlined,
          isVisible: meta.showCopyright,
          onChanged: (text) => _update(meta.copyWith(copyright: text)),
          onVisibilityChanged: (vis) =>
              _update(meta.copyWith(showCopyright: vis)),
        ),

        const SizedBox(height: 4.0),

        // ── 5. Advanced Properties Action ─────────────────────────────────────
        OutlinedButton.icon(
          icon: const Icon(Icons.more_horiz_rounded, size: 16.0),
          label: Text(l10n.scoreTypographyMoreProperties),
          onPressed: () => showDocumentPropertiesDialog(context),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            side: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeadroomBadge extends StatelessWidget {
  const _HeadroomBadge({
    required this.headroomMm,
    required this.l10n,
  });

  final double headroomMm;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.straighten_rounded,
            size: 15.0,
            color: cs.primary,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              headroomMm > 0
                  ? l10n.scoreTypographyHeadroom(headroomMm.toStringAsFixed(1))
                  : l10n.scoreTypographyHeadroomNone,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDisabledNotice extends StatelessWidget {
  const _HeaderDisabledNotice({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 15.0,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              l10n.scoreTypographyHeaderDisabledNotice,
              style: TextStyle(
                fontSize: 11.0,
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressiveDisclosureButton extends StatelessWidget {
  const _ProgressiveDisclosureButton({
    required this.isExpanded,
    required this.label,
    required this.hasActiveData,
    required this.onTap,
  });

  final bool isExpanded;
  final String label;
  final bool hasActiveData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18.0,
              color: cs.primary,
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isExpanded && hasActiveData)
              Container(
                margin: const EdgeInsets.only(left: 4.0),
                width: 7.0,
                height: 7.0,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: AppOpacities.border),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.0, color: cs.primary),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypographyInputField extends StatelessWidget {
  const _TypographyInputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    required this.isVisible,
    this.isEnabled = true,
    required this.onChanged,
    required this.onVisibilityChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool isVisible;
  final bool isEnabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.trim().isNotEmpty;

        final Color eyeColor;
        final String tooltipText;

        if (!hasText) {
          eyeColor = cs.onSurfaceVariant.withValues(alpha: 0.3);
          tooltipText = l10n.scoreTypographyEnterTextNotice;
        } else if (isVisible) {
          eyeColor = cs.primary;
          tooltipText = l10n.scoreTypographyHideOnScore;
        } else {
          eyeColor = cs.onSurfaceVariant.withValues(alpha: 0.5);
          tooltipText =
              '${l10n.scoreTypographyHiddenNotice} (${l10n.scoreTypographyShowOnScore})';
        }

        return TextField(
          controller: controller,
          enabled: isEnabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 16.0, color: cs.onSurfaceVariant),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 16.0,
                color: eyeColor,
              ),
              tooltip: tooltipText,
              onPressed:
                  isEnabled ? () => onVisibilityChanged(!isVisible) : null,
              visualDensity: VisualDensity.compact,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          style: TextStyle(
            fontSize: 12.5,
            color: isVisible
                ? null
                : cs.onSurface.withValues(alpha: 0.4),
          ),
        );
      },
    );
  }
}

