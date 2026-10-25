// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import 'adaptive_dialog_helper.dart';

/// Displays the adaptive Score Metadata / Document Properties dialog.
///
/// Enables viewing and editing extended `.sarv` score metadata fields:
/// - Title
/// - Subtitle
/// - Composer
/// - Arranger
/// - Lyricist
/// - Copyright Notice
/// As well as viewing file path and creation/modification timestamps.
Future<void> showDocumentPropertiesDialog(BuildContext context) {
  final documentCubit = context.read<DocumentCubit>();
  final currentState = documentCubit.state;

  return showSarvAdaptiveModal<void>(
    context: context,
    maxWidth: 520.0,
    builder: (modalContext, isMobile) {
      return DocumentPropertiesDialog(
        initialMetadata: currentState.metadata,
        filePath: currentState.filePath,
        onApply: (newMetadata) {
          documentCubit.updateMetadata(newMetadata);
        },
      );
    },
  );
}

/// Content widget for the Document Properties dialog/bottom sheet.
class DocumentPropertiesDialog extends StatefulWidget {
  final core.DocumentMetadata initialMetadata;
  final String? filePath;
  final ValueChanged<core.DocumentMetadata> onApply;

  const DocumentPropertiesDialog({
    super.key,
    required this.initialMetadata,
    this.filePath,
    required this.onApply,
  });

  @override
  State<DocumentPropertiesDialog> createState() => _DocumentPropertiesDialogState();
}

class _DocumentPropertiesDialogState extends State<DocumentPropertiesDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _composerController;
  late final TextEditingController _arrangerController;
  late final TextEditingController _lyricistController;
  late final TextEditingController _copyrightController;

  late bool _showTitleBlock;
  late bool _showTitle;
  late bool _showSubtitle;
  late bool _showComposer;
  late bool _showArranger;
  late bool _showLyricist;
  late bool _showCopyright;
  late bool _showPageNumbers;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialMetadata.title);
    _subtitleController = TextEditingController(text: widget.initialMetadata.subtitle);
    _composerController = TextEditingController(text: widget.initialMetadata.composer);
    _arrangerController = TextEditingController(text: widget.initialMetadata.arranger);
    _lyricistController = TextEditingController(text: widget.initialMetadata.lyricist);
    _copyrightController = TextEditingController(text: widget.initialMetadata.copyright);

    _showTitleBlock = widget.initialMetadata.showTitleBlock;
    _showTitle = widget.initialMetadata.showTitle;
    _showSubtitle = widget.initialMetadata.showSubtitle;
    _showComposer = widget.initialMetadata.showComposer;
    _showArranger = widget.initialMetadata.showArranger;
    _showLyricist = widget.initialMetadata.showLyricist;
    _showCopyright = widget.initialMetadata.showCopyright;
    _showPageNumbers = widget.initialMetadata.showPageNumbers;
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

  void _handleSave() {
    final updatedMetadata = widget.initialMetadata.copyWith(
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      composer: _composerController.text.trim(),
      arranger: _arrangerController.text.trim(),
      lyricist: _lyricistController.text.trim(),
      copyright: _copyrightController.text.trim(),
      showTitleBlock: _showTitleBlock,
      showTitle: _showTitle,
      showSubtitle: _showSubtitle,
      showComposer: _showComposer,
      showArranger: _showArranger,
      showLyricist: _showLyricist,
      showCopyright: _showCopyright,
      showPageNumbers: _showPageNumbers,
    );

    widget.onApply(updatedMetadata);
    Navigator.of(context).pop();
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    return DateFormat('yyyy-MM-dd HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: cs.primary,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.documentPropertiesTitle,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      widget.filePath ?? l10n.metadataUnsaved,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20.0),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: l10n.actionCancel,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Divider(height: 1),
          const SizedBox(height: 12.0),

          // Scrollable Form Body
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Master Toggles Card (Header Block & Page Numbers)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.view_headline_rounded, size: 18.0, color: cs.primary),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.scoreTypographyHeaderBlock,
                                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    l10n.scoreTypographyHeaderBlockSubtitle,
                                    style: TextStyle(fontSize: 11.0, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _showTitleBlock,
                              onChanged: (val) => setState(() => _showTitleBlock = val),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          children: [
                            Icon(Icons.format_list_numbered_rounded, size: 18.0, color: cs.primary),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.scoreTypographyPageNumbers,
                                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    l10n.scoreTypographyPageNumbersSubtitle,
                                    style: TextStyle(fontSize: 11.0, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _showPageNumbers,
                              onChanged: (val) => setState(() => _showPageNumbers = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14.0),

                  // Title Field
                  _buildTextField(
                    controller: _titleController,
                    label: l10n.metadataScoreTitle,
                    icon: Icons.title,
                    hint: 'e.g. Autumn Leaves',
                    isVisible: _showTitle,
                    onVisibilityChanged: (val) => setState(() => _showTitle = val),
                  ),
                  const SizedBox(height: 12.0),

                  // Subtitle Field
                  _buildTextField(
                    controller: _subtitleController,
                    label: l10n.metadataSubtitle,
                    icon: Icons.subtitles_outlined,
                    hint: 'e.g. Op. 45, No. 2',
                    isVisible: _showSubtitle,
                    onVisibilityChanged: (val) => setState(() => _showSubtitle = val),
                  ),
                  const SizedBox(height: 12.0),

                  // Composer & Arranger in a 2-column or wrapping row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 380) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _composerController,
                                label: l10n.metadataComposer,
                                icon: Icons.person_outline,
                                hint: 'e.g. J. S. Bach',
                                isVisible: _showComposer,
                                onVisibilityChanged: (val) => setState(() => _showComposer = val),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: _buildTextField(
                                controller: _arrangerController,
                                label: l10n.metadataArranger,
                                icon: Icons.music_note_outlined,
                                hint: 'e.g. Arranger',
                                isVisible: _showArranger,
                                onVisibilityChanged: (val) => setState(() => _showArranger = val),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildTextField(
                              controller: _composerController,
                              label: l10n.metadataComposer,
                              icon: Icons.person_outline,
                              hint: 'e.g. J. S. Bach',
                              isVisible: _showComposer,
                              onVisibilityChanged: (val) => setState(() => _showComposer = val),
                            ),
                            const SizedBox(height: 12.0),
                            _buildTextField(
                              controller: _arrangerController,
                              label: l10n.metadataArranger,
                              icon: Icons.music_note_outlined,
                              hint: 'e.g. Arranger',
                              isVisible: _showArranger,
                              onVisibilityChanged: (val) => setState(() => _showArranger = val),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12.0),

                  // Lyricist Field
                  _buildTextField(
                    controller: _lyricistController,
                    label: l10n.metadataLyricist,
                    icon: Icons.edit_note_outlined,
                    hint: 'e.g. Lyricist / Librettist',
                    isVisible: _showLyricist,
                    onVisibilityChanged: (val) => setState(() => _showLyricist = val),
                  ),
                  const SizedBox(height: 12.0),

                  // Copyright Field
                  _buildTextField(
                    controller: _copyrightController,
                    label: l10n.metadataCopyright,
                    icon: Icons.copyright_outlined,
                    hint: 'e.g. © 2026 Pooria Askari Moqaddam',
                    isVisible: _showCopyright,
                    onVisibilityChanged: (val) => setState(() => _showCopyright = val),
                  ),
                  const SizedBox(height: 16.0),

                  // Document Meta Info Card (Timestamps, File location)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          label: l10n.metadataFilePath,
                          value: widget.filePath ?? l10n.metadataUnsaved,
                          icon: Icons.folder_outlined,
                          isPath: widget.filePath != null,
                          cs: cs,
                        ),
                        if (widget.initialMetadata.createdAt != null) ...[
                          const SizedBox(height: 6.0),
                          _buildInfoRow(
                            label: l10n.metadataCreatedAt,
                            value: _formatDateTime(widget.initialMetadata.createdAt),
                            icon: Icons.calendar_today_outlined,
                            cs: cs,
                          ),
                        ],
                        if (widget.initialMetadata.modifiedAt != null) ...[
                          const SizedBox(height: 6.0),
                          _buildInfoRow(
                            label: l10n.metadataModifiedAt,
                            value: _formatDateTime(widget.initialMetadata.modifiedAt),
                            icon: Icons.update_outlined,
                            cs: cs,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          const Divider(height: 1),
          const SizedBox(height: 12.0),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionCancel),
              ),
              const SizedBox(width: 8.0),
              FilledButton(
                onPressed: _handleSave,
                child: Text(l10n.actionApply),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool? isVisible,
    ValueChanged<bool>? onVisibilityChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18.0, color: cs.onSurfaceVariant),
        suffixIcon: onVisibilityChanged != null && isVisible != null
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18.0,
                  color: isVisible ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                tooltip: isVisible ? l10n.scoreTypographyHideOnScore : l10n.scoreTypographyShowOnScore,
                onPressed: () => onVisibilityChanged(!isVisible),
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      style: TextStyle(
        fontSize: 13.5,
        color: (isVisible ?? true) ? null : cs.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required ColorScheme cs,
    bool isPath = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.0, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 6.0),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              color: isPath ? cs.primary : cs.onSurfaceVariant,
              fontFamily: isPath ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
