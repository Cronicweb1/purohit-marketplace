import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/session.dart';
import '../../data/messages_repository.dart';

/// The tab shell.
///
/// Both roles share one `StatefulShellRoute` with five branches, because
/// go_router builds the branch list once at router-construction time and cannot
/// rebuild it when the role changes. Instead the *destinations* are filtered per
/// role and mapped back onto branch indexes. A family never sees "Find work"; a
/// purohit never sees "Post".
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Branch order, fixed in router.dart:
  //   0 = /jobs (browse: rituals for family, open jobs for purohit)
  //   1 = /my-work (my jobs for family, my applications for purohit)
  //   2 = /post (family only)
  //   3 = /profile
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final session = ref.watch(sessionProvider);
    final isPurohit = session.isPurohit;
    // Both roles get Messages, so this is read unconditionally. Null while the
    // first fetch is in flight, which simply means no badge yet.
    final unread = (ref.watch(unreadCountsProvider).value ?? const <int, int>{})
        .values
        .fold<int>(0, (a, b) => a + b);

    final destinations = <_Dest>[
      _Dest(
        branch: 0,
        icon: isPurohit ? Icons.work_outline : Icons.search,
        selectedIcon: isPurohit ? Icons.work : Icons.search,
        label: isPurohit ? t.navFindWork : t.navBrowse,
      ),
      _Dest(
        branch: 1,
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
        label: isPurohit ? t.navApplications : t.navMyJobs,
      ),
      if (!isPurohit)
        _Dest(
          branch: 2,
          icon: Icons.add_circle_outline,
          selectedIcon: Icons.add_circle,
          label: t.navPost,
        ),
      _Dest(
        branch: 4,
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        label: t.navMessages,
        badge: unread == 0 ? null : '$unread',
      ),
      _Dest(
        branch: 3,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: t.navProfile,
      ),
    ];

    var selected = destinations
        .indexWhere((d) => d.branch == navigationShell.currentIndex);
    if (selected < 0) selected = 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          navigationShell.goBranch(
            destinations[i].branch,
            initialLocation:
                destinations[i].branch == navigationShell.currentIndex,
          );
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: d.badge == null
                  ? Icon(d.icon)
                  : Badge(label: Text(d.badge!), child: Icon(d.icon)),
              selectedIcon: d.badge == null
                  ? Icon(d.selectedIcon)
                  : Badge(
                      label: Text(d.badge!),
                      child: Icon(d.selectedIcon),
                    ),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Dest {
  const _Dest({
    required this.branch,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badge,
  });

  final int branch;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Unread count, already formatted. Null hides the badge entirely.
  final String? badge;
}
