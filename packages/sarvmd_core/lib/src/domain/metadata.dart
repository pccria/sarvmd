// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Represents descriptive score metadata for a SarvMD manuscript document.
class DocumentMetadata {
  /// The main title of the musical work.
  final String title;

  /// Subtitle or movement title (e.g., 'Op. 14', 'I. Allegro').
  final String subtitle;

  /// The composer of the piece.
  final String composer;

  /// The arranger or orchestrator of the piece.
  final String arranger;

  /// The lyricist or librettist.
  final String lyricist;

  /// Copyright notice or license terms printed on the score.
  final String copyright;

  /// Master switch for rendering the first-page title block.
  final bool showTitleBlock;

  /// Whether the work title is visible on printed output.
  final bool showTitle;

  /// Whether the subtitle is visible on printed output.
  final bool showSubtitle;

  /// Whether the composer name is visible on printed output.
  final bool showComposer;

  /// Whether the arranger name is visible on printed output.
  final bool showArranger;

  /// Whether the lyricist name is visible on printed output.
  final bool showLyricist;

  /// Whether the copyright notice is visible on printed output.
  final bool showCopyright;

  /// Whether running page numbers are visible on subsequent pages.
  final bool showPageNumbers;

  /// The ID of the built-in staff profile from which this document originated (if any).
  final String? profileId;

  /// When this document was first created.
  final DateTime? createdAt;

  /// When this document was last modified.
  final DateTime? modifiedAt;

  /// Arbitrary forward-compatible key-value pairs for future plugins or user properties.
  final Map<String, dynamic> customProperties;

  const DocumentMetadata({
    this.title = '',
    this.subtitle = '',
    this.composer = '',
    this.arranger = '',
    this.lyricist = '',
    this.copyright = '',
    this.showTitleBlock = true,
    this.showTitle = true,
    this.showSubtitle = true,
    this.showComposer = true,
    this.showArranger = true,
    this.showLyricist = true,
    this.showCopyright = true,
    this.showPageNumbers = true,
    this.profileId,
    this.createdAt,
    this.modifiedAt,
    this.customProperties = const {},
  });

  /// The effective creation timestamp, defaulting to unix epoch if not set.
  DateTime get effectiveCreatedAt =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// The effective modification timestamp, defaulting to [effectiveCreatedAt] if not set.
  DateTime get effectiveModifiedAt => modifiedAt ?? effectiveCreatedAt;

  /// Creates a copy of this metadata with optional field overrides.
  DocumentMetadata copyWith({
    String? title,
    String? subtitle,
    String? composer,
    String? arranger,
    String? lyricist,
    String? copyright,
    bool? showTitleBlock,
    bool? showTitle,
    bool? showSubtitle,
    bool? showComposer,
    bool? showArranger,
    bool? showLyricist,
    bool? showCopyright,
    bool? showPageNumbers,
    String? Function()? profileId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? customProperties,
  }) {
    return DocumentMetadata(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      composer: composer ?? this.composer,
      arranger: arranger ?? this.arranger,
      lyricist: lyricist ?? this.lyricist,
      copyright: copyright ?? this.copyright,
      showTitleBlock: showTitleBlock ?? this.showTitleBlock,
      showTitle: showTitle ?? this.showTitle,
      showSubtitle: showSubtitle ?? this.showSubtitle,
      showComposer: showComposer ?? this.showComposer,
      showArranger: showArranger ?? this.showArranger,
      showLyricist: showLyricist ?? this.showLyricist,
      showCopyright: showCopyright ?? this.showCopyright,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      profileId: profileId != null ? profileId() : this.profileId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      customProperties: customProperties ?? this.customProperties,
    );
  }

  /// Serializes this metadata instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'composer': composer,
        'arranger': arranger,
        'lyricist': lyricist,
        'copyright': copyright,
        if (!showTitleBlock) 'showTitleBlock': false,
        if (!showTitle) 'showTitle': false,
        if (!showSubtitle) 'showSubtitle': false,
        if (!showComposer) 'showComposer': false,
        if (!showArranger) 'showArranger': false,
        if (!showLyricist) 'showLyricist': false,
        if (!showCopyright) 'showCopyright': false,
        if (!showPageNumbers) 'showPageNumbers': false,
        if (profileId != null) 'profileId': profileId,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
        if (customProperties.isNotEmpty) 'customProperties': customProperties,
      };

  /// Deserializes a [DocumentMetadata] from a JSON map.
  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return DocumentMetadata(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      composer: json['composer'] as String? ?? '',
      arranger: json['arranger'] as String? ?? '',
      lyricist: json['lyricist'] as String? ?? '',
      copyright: json['copyright'] as String? ?? '',
      showTitleBlock: json['showTitleBlock'] as bool? ?? true,
      showTitle: json['showTitle'] as bool? ?? true,
      showSubtitle: json['showSubtitle'] as bool? ?? true,
      showComposer: json['showComposer'] as bool? ?? true,
      showArranger: json['showArranger'] as bool? ?? true,
      showLyricist: json['showLyricist'] as bool? ?? true,
      showCopyright: json['showCopyright'] as bool? ?? true,
      showPageNumbers: json['showPageNumbers'] as bool? ?? true,
      profileId: json['profileId'] as String?,
      createdAt: parseDate(json['createdAt']),
      modifiedAt: parseDate(json['modifiedAt']),
      customProperties: json['customProperties'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['customProperties'] as Map)
          : const {},
    );
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final valA = a[key];
      final valB = b[key];
      if (valA is List && valB is List) {
        if (valA.length != valB.length) return false;
        for (int i = 0; i < valA.length; i++) {
          if (valA[i] != valB[i]) return false;
        }
      } else if (valA != valB) {
        return false;
      }
    }
    return true;
  }

  /// Checks whether two metadata instances share identical user-facing metadata,
  /// ignoring volatile operational timestamps ([modifiedAt] and [createdAt]).
  bool hasSameContent(DocumentMetadata other) =>
      identical(this, other) ||
      (title == other.title &&
          subtitle == other.subtitle &&
          composer == other.composer &&
          arranger == other.arranger &&
          lyricist == other.lyricist &&
          copyright == other.copyright &&
          showTitleBlock == other.showTitleBlock &&
          showTitle == other.showTitle &&
          showSubtitle == other.showSubtitle &&
          showComposer == other.showComposer &&
          showArranger == other.showArranger &&
          showLyricist == other.showLyricist &&
          showCopyright == other.showCopyright &&
          showPageNumbers == other.showPageNumbers &&
          profileId == other.profileId &&
          _mapEquals(customProperties, other.customProperties));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          subtitle == other.subtitle &&
          composer == other.composer &&
          arranger == other.arranger &&
          lyricist == other.lyricist &&
          copyright == other.copyright &&
          showTitleBlock == other.showTitleBlock &&
          showTitle == other.showTitle &&
          showSubtitle == other.showSubtitle &&
          showComposer == other.showComposer &&
          showArranger == other.showArranger &&
          showLyricist == other.showLyricist &&
          showCopyright == other.showCopyright &&
          showPageNumbers == other.showPageNumbers &&
          profileId == other.profileId &&
          createdAt == other.createdAt &&
          modifiedAt == other.modifiedAt &&
          _mapEquals(customProperties, other.customProperties);

  @override
  int get hashCode => Object.hash(
        title,
        subtitle,
        composer,
        arranger,
        lyricist,
        copyright,
        showTitleBlock,
        showTitle,
        showSubtitle,
        showComposer,
        showArranger,
        showLyricist,
        showCopyright,
        showPageNumbers,
        profileId,
        createdAt,
        modifiedAt,
      );
}

/// Convenience extension providing score engraving typography checks.
extension DocumentMetadataTypography on DocumentMetadata {
  /// Whether the title should be printed on the first page.
  bool get hasPrintableTitle =>
      showTitleBlock && showTitle && title.trim().isNotEmpty;

  /// Whether the subtitle should be printed on the first page.
  bool get hasPrintableSubtitle =>
      showTitleBlock && showSubtitle && subtitle.trim().isNotEmpty;

  /// Whether the composer name should be printed on the first page.
  bool get hasPrintableComposer =>
      showTitleBlock && showComposer && composer.trim().isNotEmpty;

  /// Whether the arranger name should be printed on the first page.
  bool get hasPrintableArranger =>
      showTitleBlock && showArranger && arranger.trim().isNotEmpty;

  /// Whether the lyricist/librettist name should be printed on the first page.
  bool get hasPrintableLyricist =>
      showTitleBlock && showLyricist && lyricist.trim().isNotEmpty;

  /// Whether the copyright/license notice should be printed.
  bool get hasPrintableCopyright =>
      showCopyright && copyright.trim().isNotEmpty;

  /// Whether page numbers should be printed on subsequent pages.
  bool get hasPrintablePageNumbers => showPageNumbers;

  /// Whether a score title block (title, subtitle, composer, lyricist, arranger)
  /// should be rendered at the top of the first page.
  bool get hasTitleBlock =>
      showTitleBlock &&
      (hasPrintableTitle ||
          hasPrintableSubtitle ||
          hasPrintableComposer ||
          hasPrintableLyricist ||
          hasPrintableArranger);

  /// Whether this document has any user-facing printable header/footer metadata to render.
  bool get hasPrintableTypography =>
      hasTitleBlock || hasPrintableCopyright;
}

