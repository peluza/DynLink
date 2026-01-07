import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String _androidWidgetProvider = 'DdnsWidgetProvider';

  static Future<void> updateWidget({
    required String? ip,
    required String? domain,
    required String status,
  }) async {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);

    // Make status simpler
    String displayStatus = status;
    if (status.startsWith('Success')) displayStatus = 'ACTIVE';
    if (status.startsWith('Skipped')) displayStatus = 'SYNCED';
    if (status.startsWith('Error')) displayStatus = 'ERROR';

    await HomeWidget.saveWidgetData<String>('ip', ip ?? '---.---.---.---');
    await HomeWidget.saveWidgetData<String>('domain', domain ?? 'No Account');
    await HomeWidget.saveWidgetData<String>('status', displayStatus);
    await HomeWidget.saveWidgetData<String>('last_updated', '$timeStr');

    await HomeWidget.updateWidget(
      name: _androidWidgetProvider,
      androidName: _androidWidgetProvider,
    );
  }
}
