import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ziggle/app/modules/core/domain/enums/language.dart';
import 'package:ziggle/app/modules/notices/domain/entities/notice_group_entity.dart';
import 'package:ziggle/app/modules/notices/domain/entities/notice_write_draft_entity.dart';
import 'package:ziggle/app/modules/notices/domain/enums/notice_category.dart';
import 'package:ziggle/app/modules/user/domain/entities/user_entity.dart';

import '../enums/notice_reaction.dart';
import 'author_entity.dart';
import 'notice_content_entity.dart';
import 'notice_reaction_entity.dart';

class NoticeEntity {
  final int id;
  final int views;
  final List<Language> langs;
  final DateTime? deadline;
  final DateTime? currentDeadline;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<String> tags;
  final Map<Language, String> titles;
  final Map<Language, String> contents;
  final List<NoticeContentEntity> additionalContents;
  final List<NoticeReactionEntity> reactions;
  final AuthorEntity author;
  final List<ImageProvider> images;
  final List<String> documentUrls;
  final bool isReminded;
  final DateTime publishedAt;
  final NoticeGroupEntity? group;
  final NoticeCategory category;

  NoticeEntity({
    required this.id,
    required this.views,
    required this.langs,
    required this.deadline,
    required this.currentDeadline,
    required this.createdAt,
    required this.deletedAt,
    required this.tags,
    required this.titles,
    required this.contents,
    required this.additionalContents,
    required this.reactions,
    required this.author,
    required this.images,
    required this.documentUrls,
    required this.isReminded,
    required this.publishedAt,
    required this.group,
    required this.category,
  });

  factory NoticeEntity.fromId(int id) => NoticeEntity(
        id: id,
        views: 0,
        langs: [],
        deadline: null,
        currentDeadline: null,
        createdAt: DateTime.now(),
        deletedAt: null,
        tags: [],
        titles: {Language.getCurrentLanguage(): ''},
        contents: {Language.getCurrentLanguage(): ''},
        additionalContents: [],
        reactions: [],
        images: [],
        documentUrls: [],
        author: AuthorEntity(name: '', uuid: ''),
        isReminded: false,
        publishedAt: DateTime.now(),
        group: null,
        category: NoticeCategory.etc,
      );
  factory NoticeEntity.mock({
    DateTime? deadline,
    required DateTime createdAt,
    List<String> tags = const [],
    required String title,
    required String content,
    List<NoticeReactionEntity> reactions = const [],
    String authorName = '홍길동',
    List<String> imageUrls = const [],
    bool isReminded = false,
    NoticeCategory category = NoticeCategory.etc,
  }) =>
      NoticeEntity(
        id: 0,
        views: 0,
        langs: [Language.ko],
        deadline: deadline,
        currentDeadline: null,
        createdAt: createdAt,
        deletedAt: null,
        tags: tags,
        titles: {Language.getCurrentLanguage(): title},
        contents: {Language.getCurrentLanguage(): content},
        additionalContents: [],
        reactions: reactions,
        author: AuthorEntity(name: authorName, uuid: ''),
        images:
            imageUrls.map((url) => CachedNetworkImageProvider(url)).toList(),
        documentUrls: [],
        isReminded: isReminded,
        publishedAt: DateTime.now(),
        group: null,
        category: category,
      );
  factory NoticeEntity.fromDraft({
    required NoticeWriteDraftEntity draft,
    required UserEntity user,
  }) =>
      NoticeEntity(
        id: 0,
        views: 0,
        langs: [Language.ko],
        deadline: draft.deadline,
        currentDeadline: draft.deadline,
        createdAt: DateTime.now(),
        deletedAt: null,
        tags: draft.tags,
        titles: draft.titles,
        contents: draft.bodies,
        additionalContents: [],
        reactions: [],
        author: AuthorEntity(name: user.name, uuid: ''),
        images: draft.images.map((file) => FileImage(file)).toList(),
        documentUrls: [],
        isReminded: false,
        publishedAt: DateTime.now(),
        group: draft.group,
        category: NoticeCategory.fromType(draft.type!)!,
      );
}

extension NoticeEntityExtension on NoticeEntity {
  int reactionsBy(NoticeReaction reaction) =>
      reactions.firstWhereOrNull((e) => e.emoji == reaction.emoji)?.count ?? 0;
  int get likes => reactionsBy(NoticeReaction.like);
  bool reacted(NoticeReaction reaction) =>
      reactions.firstWhereOrNull((e) => e.emoji == reaction.emoji)?.isReacted ??
      false;
  bool get canRemind {
    if (currentDeadline == null) return false;
    if (currentDeadline!.toLocal().isBefore(DateTime.now())) return false;
    return true;
  }

  bool get isCertified => false;

  int get lastContentId => maxBy(additionalContents, (c) => c.id)?.id ?? 1;

  NoticeEntity copyWith({
    DateTime? publishedAt,
    List<NoticeReactionEntity>? reactions,
  }) =>
      NoticeEntity(
        id: id,
        views: views,
        langs: langs,
        deadline: deadline,
        currentDeadline: currentDeadline,
        createdAt: createdAt,
        deletedAt: deletedAt,
        tags: tags,
        titles: titles,
        contents: contents,
        additionalContents: additionalContents,
        reactions: reactions ?? this.reactions,
        author: author,
        images: images,
        documentUrls: documentUrls,
        isReminded: isReminded,
        publishedAt: publishedAt ?? this.publishedAt,
        group: group,
        category: category,
      );

  NoticeEntity addReaction(NoticeReaction reaction) {
    final reactions = [
      ...this.reactions.where((e) => e.emoji != reaction.emoji),
      NoticeReactionEntity(
        emoji: reaction.emoji,
        count: reactionsBy(reaction) + 1,
        isReacted: true,
      ),
    ];
    return copyWith(reactions: reactions);
  }

  NoticeEntity removeReaction(NoticeReaction reaction) {
    final newCount = reactionsBy(reaction) - 1;
    final reactions = [
      ...this.reactions.where((e) => e.emoji != reaction.emoji),
      if (newCount > 0)
        NoticeReactionEntity(
          emoji: reaction.emoji,
          count: newCount,
          isReacted: false,
        ),
    ];
    return copyWith(reactions: reactions);
  }

  bool get isPublished => publishedAt.isBefore(DateTime.now());
  NoticeEntity addDraft(NoticeWriteDraftEntity draft) => NoticeEntity(
        id: id,
        views: views,
        langs: langs,
        deadline: deadline,
        currentDeadline: currentDeadline,
        createdAt: createdAt,
        deletedAt: deletedAt,
        tags: tags,
        titles: draft.titles.isNotEmpty ? draft.titles : titles,
        contents: draft.bodies.isNotEmpty ? draft.bodies : contents,
        additionalContents: [
          ...additionalContents,
          ...draft.additionalContent.entries.mapIndexed(
            (index, content) => NoticeContentEntity(
              deadline: draft.deadline ?? currentDeadline,
              id: lastContentId + 1,
              lang: content.key,
              content: content.value,
              createdAt: DateTime.now(),
            ),
          ),
        ],
        reactions: reactions,
        author: author,
        images: images,
        documentUrls: documentUrls,
        isReminded: isReminded,
        publishedAt: publishedAt,
        group: group,
        category: category,
      );
}

extension LanguageContentX on Map<Language, String> {
  String get current => this[Language.getCurrentLanguage()] ?? values.first;
}
