import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/session.dart';
import '../features/device/view/device_capture_screen.dart';
import '../features/pdf/view/export_screen.dart';
import '../features/profile/view/profile_capture_screen.dart';
import '../features/shared/view/form_type_select_screen.dart';
import '../features/shared/view/home_screen.dart';
import '../features/shared/view/review_screen.dart';
import '../features/shared/view/diagnostics_screen.dart';
import '../features/session/view/session_flow_screen.dart';

enum AppRoute {
  home,
  formTypeSelect,
  session,
  profileCapture,
  deviceCapture,
  review,
  export,
  diagnostics,
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/form-type',
        name: AppRoute.formTypeSelect.name,
        builder: (context, state) => const FormTypeSelectScreen(),
      ),
      GoRoute(
        path: '/session',
        name: AppRoute.session.name,
        builder: (context, state) => SessionFlowScreen(
          formType: state.extra is FormType ? state.extra as FormType : FormType.received,
        ),
      ),
      GoRoute(
        path: '/profile',
        name: AppRoute.profileCapture.name,
        builder: (context, state) => ProfileCaptureScreen(
          formType: state.extra is FormType ? state.extra as FormType : null,
        ),
      ),
      GoRoute(
        path: '/device',
        name: AppRoute.deviceCapture.name,
        builder: (context, state) => DeviceCaptureScreen(
          formType: state.extra is FormType ? state.extra as FormType : null,
        ),
      ),
      GoRoute(
        path: '/review',
        name: AppRoute.review.name,
        builder: (context, state) {
          FormType? formType;
          double? confidence;
          Map<String, dynamic>? extras;
          if (state.extra is Map<String, dynamic>) {
            extras = Map<String, dynamic>.from(state.extra! as Map<String, dynamic>);
            formType = extras['formType'] as FormType?;
            confidence = extras['confidence'] as double?;
          } else if (state.extra is FormType) {
            formType = state.extra as FormType?;
          }
          return ReviewScreen(
            formType: formType,
            confidence: confidence,
            extras: extras,
          );
        },
      ),
      GoRoute(
        path: '/export',
        name: AppRoute.export.name,
        builder: (context, state) {
          FormType? formType;
          Map<String, dynamic>? fields;
          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra! as Map<String, dynamic>;
            formType = extra['formType'] as FormType?;
            fields = extra['fields'] as Map<String, dynamic>?;
          } else if (state.extra is FormType) {
            formType = state.extra as FormType?;
          }
          return ExportScreen(formType: formType, fields: fields);
        },
      ),
      GoRoute(
        path: '/diagnostics',
        name: AppRoute.diagnostics.name,
        builder: (context, state) => const DiagnosticsScreen(),
      ),
    ],
  );
});
