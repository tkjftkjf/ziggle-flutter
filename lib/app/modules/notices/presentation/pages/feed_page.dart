import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ziggle/app/di/locator.dart';
import 'package:ziggle/app/modules/common/presentation/extensions/toast.dart';
import 'package:ziggle/app/modules/common/presentation/widgets/ziggle_app_bar.dart';
import 'package:ziggle/app/modules/core/data/models/analytics_event.dart';
import 'package:ziggle/app/modules/core/domain/enums/page_source.dart';
import 'package:ziggle/app/modules/core/domain/repositories/analytics_repository.dart';
import 'package:ziggle/app/modules/notices/domain/enums/notice_type.dart';
import 'package:ziggle/app/modules/notices/presentation/bloc/notice_list_bloc.dart';
import 'package:ziggle/app/modules/notices/presentation/widgets/list_layout.dart';
import 'package:ziggle/app/modules/user/presentation/bloc/user_bloc.dart';
import 'package:ziggle/app/router.gr.dart';
import 'package:ziggle/app/values/palette.dart';
import 'package:ziggle/gen/strings.g.dart';

@RoutePage()
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with AutoRouteAwareStateMixin<FeedPage> {
  @override
  void didInitTabRoute(previousRoute) =>
      AnalyticsRepository.pageView(const AnalyticsEvent.feed());
  @override
  void didChangeTabRoute(previousRoute) =>
      AnalyticsRepository.pageView(const AnalyticsEvent.feed());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.grayLight,
      appBar: ZiggleAppBar.main(
        onTapSearch: () {
          AnalyticsRepository.click(
              const AnalyticsEvent.search(PageSource.feed));
          const SearchRoute().push(context);
        },
        onTapWrite: () {
          AnalyticsRepository.click(
              const AnalyticsEvent.write(PageSource.feed));
          if (UserBloc.userOrNull(context) == null) {
            return context.showToast(
              context.t.user.login.description,
            );
          }
          const NoticeWriteBodyRoute().push(context);
        },
      ),
      body: BlocProvider(
        create: (_) => sl<NoticeListBloc>()
          ..add(const NoticeListEvent.load(NoticeType.all)),
        child: BlocListener<NoticeListBloc, NoticeListState>(
          listener: (context, state) => state.mapOrNull(
            error: (error) => context.showToast(error.message),
          ),
          child: const ListLayout(
            noticeType: NoticeType.all,
          ),
        ),
      ),
    );
  }
}
