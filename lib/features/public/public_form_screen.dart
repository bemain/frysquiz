import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/form_provider.dart';
import '../user/form_fill_screen.dart';

class PublicFormScreen extends ConsumerWidget {
  const PublicFormScreen({super.key, required this.formId});

  final String formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formAsync = ref.watch(formDetailProvider(formId));
    return formAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Fel: $e'))),
      data: (form) {
        if (form == null) {
          return const Scaffold(
            body: Center(child: Text('Enkäten hittades inte.')),
          );
        }
        return FormFillContent(form: form, isPublic: true);
      },
    );
  }
}
