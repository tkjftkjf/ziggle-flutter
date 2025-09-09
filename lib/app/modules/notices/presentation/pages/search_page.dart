import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:rxdart/rxdart.dart';
import 'package:ziggle/app/di/locator.dart';
import 'package:ziggle/app/modules/common/presentation/extensions/date_time.dart';
import 'package:ziggle/app/modules/common/presentation/extensions/toast.dart';
import 'package:ziggle/app/modules/common/presentation/functions/noop.dart';
import 'package:ziggle/app/modules/common/presentation/widgets/ziggle_button.dart';
import 'package:ziggle/app/modules/common/presentation/widgets/ziggle_pressable.dart';
import 'package:ziggle/app/modules/core/data/models/analytics_event.dart';
import 'package:ziggle/app/modules/core/domain/enums/page_source.dart';
import 'package:ziggle/app/modules/core/domain/repositories/analytics_repository.dart';
import 'package:ziggle/app/modules/notices/domain/entities/notice_entity.dart';
import 'package:ziggle/app/modules/notices/domain/enums/notice_type.dart';
import 'package:ziggle/app/modules/notices/presentation/bloc/notice_list_bloc.dart';
import 'package:ziggle/app/modules/notices/presentation/widgets/infinite_scroll.dart';
import 'package:ziggle/app/router.gr.dart';
import 'package:ziggle/app/values/palette.dart';
import 'package:ziggle/gen/assets.gen.dart';
import 'package:ziggle/gen/strings.g.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutoRouteAwareStateMixin<SearchPage> {
  @override
  void didPush() => AnalyticsRepository.pageView(const AnalyticsEvent.search());
  @override
  void didPopNext() =>
      AnalyticsRepository.pageView(const AnalyticsEvent.search());

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NoticeListBloc>(),
      child: BlocListener<NoticeListBloc, NoticeListState>(
        listener: (context, state) => state.mapOrNull(
          error: (error) => context.showToast(error.message),
        ),
        child: const _Layout(),
      ),
    );
  }
}

class _Layout extends StatefulWidget {
  const _Layout();

  @override
  State<_Layout> createState() => _LayoutState();
}

class _LayoutState extends State<_Layout> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(noop));
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSearchTextField(
                    controller: _controller,
                    onChanged: (value) => context.read<NoticeListBloc>().add(
                        NoticeListEvent.load(NoticeType.all, query: value)),
                    prefixIcon: Assets.icons.search.svg(width: 20),
                    placeholder: context.t.notice.search.hint,
                    suffixIcon: const Icon(Icons.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                ZiggleButton.text(
                  onPressed: () => context.router.maybePop(),
                  child: Text(
                    context.t.common.cancel,
                    style: const TextStyle(color: Palette.grayText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _controller.text.isEmpty
          ? Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Assets.icons.search.svg(
                    width: 65,
                    height: 65,
                    colorFilter: const ColorFilter.mode(
                      Palette.gray,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    context.t.notice.search.description,
                    style: const TextStyle(
                      color: Palette.grayText,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ],
              ),
            )
          : BlocBuilder<NoticeListBloc, NoticeListState>(
              builder: (context, state) {
                return RefreshIndicator(
                  onRefresh: () => NoticeListBloc.refresh(context),
                  child: state.showLoading
                      ? Center(
                          child: Lottie.asset(Assets.lotties.loading,
                              height: MediaQuery.of(context).size.width * 0.2,
                              width: MediaQuery.of(context).size.width * 0.2),
                        )
                      : InfiniteScroll(
                          onLoadMore: () => NoticeListBloc.loadMore(context),
                          slivers: [
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              sliver: _buildList(state),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }

  SliverList _buildList(NoticeListState state) {
    return SliverList.builder(
      itemBuilder: (context, index) {
        if (index >= state.notices.length) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: Lottie.asset(Assets.lotties.loading,
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.width * 0.2),
            ),
          );
        }
        final notice = state.notices[index];
        return Container(
          decoration: index != state.notices.length - 1
              ? null
              : const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0x5B3C3C43),
                      width: 0.33,
                    ),
                  ),
                ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 9,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x5B3C3C43), width: 0.33),
              ),
            ),
            child: ZigglePressable(
              onPressed: () {
                AnalyticsRepository.click(
                    AnalyticsEvent.notice(notice.id, PageSource.search));
                SingleNoticeShellRoute(notice: notice).push(context);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    notice.titles.current,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Palette.black,
                    ),
                  ),
                  Text(
                    '${notice.author.name}, ${notice.createdAt.getTimeAgo(context)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Palette.grayText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      itemCount: state.notices.length + (state.isLoading ? 1 : 0),
    );
  }
}
