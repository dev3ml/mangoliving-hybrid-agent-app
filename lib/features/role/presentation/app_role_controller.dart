import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_role.dart';

final appRoleProvider = StateProvider<AppRole>((Ref ref) => AppRole.none);
