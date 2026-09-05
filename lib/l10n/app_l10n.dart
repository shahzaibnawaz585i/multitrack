import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_locale_controller.dart';

extension AppL10nContext on BuildContext {
  AppLocaleController get localeController {
    try {
      return Provider.of<AppLocaleController>(this);
    } catch (_) {
      return appLocaleController ??
          Provider.of<AppLocaleController>(this, listen: false);
    }
  }

  String tr(String text) => localeController.translate(text);

  String trp(String text, Map<String, String> params) {
    return localeController.translateParams(text, params);
  }
}
