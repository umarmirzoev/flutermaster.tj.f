import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/models/master_application_status.dart';
import '../../auth/providers/auth_provider.dart';
import '../../master/presentation/master_dashboard.dart';
import '../../master/presentation/master_pending_profile.dart';
import 'profile_dashboard.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isMaster && auth.masterProfile != null) {
      if (auth.masterProfile!.applicationStatus ==
          MasterApplicationStatus.approved) {
        return const MasterDashboard(bottomPadding: 110);
      }
      return const MasterPendingProfile(bottomPadding: 110);
    }

    return const ProfileDashboard(bottomPadding: 110);
  }
}
