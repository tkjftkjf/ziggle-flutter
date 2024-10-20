import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:ziggle/app/modules/common/presentation/widgets/ziggle_button.dart';
import 'package:ziggle/app/modules/common/presentation/widgets/ziggle_row_button.dart';
import 'package:ziggle/app/modules/core/data/models/analytics_event.dart';
import 'package:ziggle/app/modules/core/domain/enums/page_source.dart';
import 'package:ziggle/app/modules/core/domain/repositories/analytics_repository.dart';
import 'package:ziggle/app/modules/notices/domain/enums/notice_type.dart';
import 'package:ziggle/app/modules/user/domain/entities/user_entity.dart';
import 'package:ziggle/app/modules/user/presentation/bloc/auth_bloc.dart';
import 'package:ziggle/app/modules/user/presentation/bloc/user_bloc.dart';
import 'package:ziggle/app/router.gr.dart';
import 'package:ziggle/app/values/palette.dart';
import 'package:ziggle/app/values/strings.dart';
import 'package:ziggle/gen/assets.gen.dart';
import 'package:ziggle/gen/strings.g.dart';

@RoutePage()
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutoRouteAwareStateMixin<ProfilePage> {
  @override
  void didChangeTabRoute(previousRoute) =>
      AnalyticsRepository.pageView(const AnalyticsEvent.profile());

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: _Layout(),
          ),
        ),
      ),
    );
  }
}

class _Layout extends StatelessWidget {
  const _Layout();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (_, c) => c.mapOrNull(done: (v) => true) ?? false,
      builder: (context, state) {
        final authenticated = state.user != null;
        return Column(
          children: [
            if (authenticated)
              _Profile(user: state.user!)
            else
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) => Stack(
                  alignment: Alignment.center,
                  children: [
                    ImageFiltered(
                      enabled: authState.isLoading,
                      imageFilter: ImageFilter.blur(
                        sigmaX: 10,
                        sigmaY: 10,
                        tileMode: TileMode.decal,
                      ),
                      child: const _Login(),
                    ),
                    if (authState.isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                  ],
                ),
              ),
            const SizedBox(height: 40),
            ZiggleRowButton(
              icon: Assets.icons.setting.svg(),
              title: Text(context.t.user.setting.title),
              onPressed: () {
                AnalyticsRepository.click(
                    const AnalyticsEvent.profileSetting());
                const SettingRoute().push(context);
              },
            ),
            if (authenticated) ...[
              const SizedBox(height: 20),
              ZiggleRowButton(
                icon: Assets.icons.write.svg(),
                title: Text(context.t.user.written),
                onPressed: () {
                  AnalyticsRepository.click(
                      const AnalyticsEvent.profileMyNotices());
                  ListRoute(type: NoticeType.written).push(context);
                },
              ),
            ],
            const SizedBox(height: 20),
            ZiggleRowButton(
              icon: Assets.icons.flag.svg(),
              title: Text(context.t.user.feedback),
              onPressed: () {
                AnalyticsRepository.click(
                    const AnalyticsEvent.profileFeedback());
                launchUrlString(
                  Strings.heyDeveloperUrl(UserBloc.userOrNull(context)?.email),
                );
              },
            ),
            const SizedBox(height: 40),
            if (authenticated)
              ZiggleRowButton(
                showChevron: false,
                title: Text(context.t.user.account.logout),
                destructive: true,
                onPressed: () {
                  AnalyticsRepository.click(
                      const AnalyticsEvent.profileLogout(PageSource.profile));
                  context
                      .read<AuthBloc>()
                      .add(const AuthEvent.logout(source: PageSource.profile));
                },
              ),
          ],
        );
      },
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Assets.images.defaultProfile.image(width: 120),
        const SizedBox(height: 10),
        Text(
          user.name,
          style: const TextStyle(
            color: Palette.black,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          user.email,
          style: const TextStyle(
            color: Palette.grayText,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _Login extends StatelessWidget {
  const _Login();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t.user.login.title,
          style: const TextStyle(
            fontSize: 24,
            color: Palette.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          context.t.user.login.description,
          style: const TextStyle(
            fontSize: 14,
            color: Palette.grayText,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        ZiggleButton.cta(
          onPressed: () {
            AnalyticsRepository.click(
                const AnalyticsEvent.profileLogin(PageSource.profile));
            context
                .read<AuthBloc>()
                .add(const AuthEvent.login(source: PageSource.profile));
          },
          child: Text(context.t.user.login.action),
        ),
      ],
    );
  }
}
