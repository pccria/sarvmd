// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../core/theme/app_metrics.dart';
import '../../../l10n/app_localizations.dart';
import '../dialogs/document_properties_dialog.dart';

/// Sidebar & Touch Drawer settings group for Score Information & Typography.
///
/// Provides inline controls for work title, contributor credits, copyright,
/// running page numbers, and Gouldian header block visibility toggles.
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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.metadata.title);
    _subtitleController = TextEditingController(text: widget.metadata.subtitle);
    _composerController = TextEditingController(text: widget.metadata.composer);
    _arrangerController = TextEditingController(text: widget.metadata.arranger);
    _lyricistController = TextEditingController(text: widget.metadata.lyricist);
    _copyrightController = TextEditingController(text: widget.metadata.copyright);
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

        // ── 2. First-Page Header Block Inputs ─────────────────────────────────
        AnimatedOpacity(
          opacity: meta.showTitleBlock ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Column(
            spacing: 8.0,
            children: [
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
                controller: _subtitleController,
                label: l10n.metadataSubtitle,
                hint: 'e.g. Op. 45, No. 2',
                icon: Icons.subtitles_outlined,
                isVisible: meta.showSubtitle,
                isEnabled: meta.showTitleBlock,
                onChanged: (text) => _update(meta.copyWith(subtitle: text)),
                onVisibilityChanged: (vis) =>
                    _update(meta.copyWith(showSubtitle: vis)),
              ),
              _TypographyInputField(
                controller: _composerController,
                label: l10n.metadataComposer,
                hint: 'e.g. J. S. Bach',
                icon: Icons.person_outline,
                isVisible: meta.showComposer,
                isEnabled: meta.showTitleBlock,
                onChanged: (text) => _update(meta.copyWith(composer: text)),
                onVisibilityChanged: (vis) =>
                    _update(meta.copyWith(showComposer: vis)),
              ),
              _TypographyInputField(
                controller: _arrangerController,
                label: l10n.metadataArranger,
                hint: 'e.g. Arranger',
                icon: Icons.music_note_outlined,
                isVisible: meta.showArranger,
                isEnabled: meta.showTitleBlock,
                onChanged: (text) => _update(meta.copyWith(arranger: text)),
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
                onChanged: (text) => _update(meta.copyWith(lyricist: text)),
                onVisibilityChanged: (vis) =>
                    _update(meta.copyWith(showLyricist: vis)),
              ),
            ],
          ),
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
            isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 16.0,
            color: isVisible
                ? cs.primary
                : cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          tooltip: isVisible
              ? l10n.scoreTypographyHideOnScore
              : l10n.scoreTypographyShowOnScore,
          onPressed: isEnabled ? () => onVisibilityChanged(!isVisible) : null,
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
  }
}
