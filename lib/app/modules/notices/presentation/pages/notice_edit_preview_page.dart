import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ziggle/app/modules/common/presentation/extensions/toast.dart';
import 'package:ziggle/app/modules/common/presentation/widgets/ziggle_app_bar.dart';
import 'package:ziggle/app/modules/core/data/models/analytics_event.dart';
import 'package:ziggle/app/modules/core/domain/enums/page_source.dart';
import 'package:ziggle/app/modules/core/domain/repositories/analytics_repository.dart';
import 'package:ziggle/app/modules/notices/domain/entities/notice_entity.dart';
import 'package:ziggle/app/modules/notices/presentation/bloc/notice_bloc.dart';
import 'package:ziggle/app/modules/notices/presentation/bloc/notice_write_bloc.dart';
import 'package:ziggle/app/modules/notices/presentation/widgets/notice_renderer.dart';
import 'package:ziggle/gen/strings.g.dart';

@RoutePage()
class NoticeEditPreviewPage extends StatefulWidget {
  const NoticeEditPreviewPage({super.key});

  @override
  State<NoticeEditPreviewPage> createState() => _NoticeEditPreviewPageState();
}

class _NoticeEditPreviewPageState extends State<NoticeEditPreviewPage>
    with AutoRouteAwareStateMixin<NoticeEditPreviewPage> {
  @override
  void didPush() =>
      AnalyticsRepository.pageView(AnalyticsEvent.noticeEditPreview(
          context.read<NoticeBloc>().state.entity!.id));
  @override
  void didPopNext() =>
      AnalyticsRepository.pageView(AnalyticsEvent.noticeEditPreview(
          context.read<NoticeBloc>().state.entity!.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZiggleAppBar.compact(
        backLabel: context.t.notice.write.configTitle,
        from: PageSource.noticeEditPreview,
        title: Text(context.t.notice.write.preview),
      ),
      body: Builder(
        builder: (context) {
          final draft =
              context.select((NoticeWriteBloc bloc) => bloc.state.draft);
          final notice =
              context.select((NoticeBloc bloc) => bloc.state.entity!);
          return BlocListener<NoticeBloc, NoticeState>(
            listener: (context, state) {
              state.mapOrNull(
                error: (error) => context.showToast(error.message),
              );
            },
            child: NoticeRenderer(
              notice: notice.addDraft(draft),
              hideAuthorSetting: true,
            ),
          );
        },
      ),
    );
  }
}
