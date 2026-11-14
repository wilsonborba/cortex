import 'package:cortex/presentation/frontend/theme/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_test/flutter_test.dart';

const _families = {'FluentSystemIcons-Regular', 'FluentSystemIcons-Filled'};

/// The icon map of issue #60: AppIcons name, Fluent 20 px glyph, 24 px glyph.
final _map = <String, (IconData, IconData, IconData)>{
  'chats': (
    AppIcons.chats,
    FluentIcons.chat_multiple_20_regular,
    FluentIcons.chat_multiple_24_regular,
  ),
  'memory': (
    AppIcons.memory,
    FluentIcons.brain_circuit_20_regular,
    FluentIcons.brain_circuit_24_regular,
  ),
  'personas': (
    AppIcons.personas,
    FluentIcons.people_20_regular,
    FluentIcons.people_24_regular,
  ),
  'usage': (
    AppIcons.usage,
    FluentIcons.data_bar_vertical_20_regular,
    FluentIcons.data_bar_vertical_24_regular,
  ),
  'newChat': (
    AppIcons.newChat,
    FluentIcons.compose_20_regular,
    FluentIcons.compose_24_regular,
  ),
  'temporaryChat': (
    AppIcons.temporaryChat,
    FluentIcons.eye_off_20_regular,
    FluentIcons.eye_off_24_regular,
  ),
  'account': (
    AppIcons.account,
    FluentIcons.person_circle_20_regular,
    FluentIcons.person_circle_24_regular,
  ),
  'settings': (
    AppIcons.settings,
    FluentIcons.settings_20_regular,
    FluentIcons.settings_24_regular,
  ),
  'systemTheme': (
    AppIcons.systemTheme,
    FluentIcons.desktop_20_regular,
    FluentIcons.desktop_24_regular,
  ),
  'lightTheme': (
    AppIcons.lightTheme,
    FluentIcons.weather_sunny_20_regular,
    FluentIcons.weather_sunny_24_regular,
  ),
  'darkTheme': (
    AppIcons.darkTheme,
    FluentIcons.weather_moon_20_regular,
    FluentIcons.weather_moon_24_regular,
  ),
  'language': (
    AppIcons.language,
    FluentIcons.local_language_20_regular,
    FluentIcons.local_language_24_regular,
  ),
  'logOut': (
    AppIcons.logOut,
    FluentIcons.sign_out_20_regular,
    FluentIcons.sign_out_24_regular,
  ),
  'search': (
    AppIcons.search,
    FluentIcons.search_20_regular,
    FluentIcons.search_24_regular,
  ),
  'attach': (
    AppIcons.attach,
    FluentIcons.attach_20_regular,
    FluentIcons.attach_24_regular,
  ),
  'send': (
    AppIcons.send,
    FluentIcons.send_20_regular,
    FluentIcons.send_24_regular,
  ),
  'stop': (
    AppIcons.stop,
    FluentIcons.stop_20_regular,
    FluentIcons.stop_24_regular,
  ),
  'copy': (
    AppIcons.copy,
    FluentIcons.copy_20_regular,
    FluentIcons.copy_24_regular,
  ),
  'copied': (
    AppIcons.copied,
    FluentIcons.checkmark_20_regular,
    FluentIcons.checkmark_24_regular,
  ),
  'close': (
    AppIcons.close,
    FluentIcons.dismiss_20_regular,
    FluentIcons.dismiss_24_regular,
  ),
  'more': (
    AppIcons.more,
    FluentIcons.more_horizontal_20_regular,
    FluentIcons.more_horizontal_24_regular,
  ),
  'file': (
    AppIcons.file,
    FluentIcons.document_text_20_regular,
    FluentIcons.document_text_24_regular,
  ),
  'tag': (AppIcons.tag, FluentIcons.tag_20_regular, FluentIcons.tag_24_regular),
  'entity': (
    AppIcons.entity,
    FluentIcons.person_20_regular,
    FluentIcons.person_24_regular,
  ),
  'note': (
    AppIcons.note,
    FluentIcons.lightbulb_20_regular,
    FluentIcons.lightbulb_24_regular,
  ),
  'bot': (AppIcons.bot, FluentIcons.bot_20_regular, FluentIcons.bot_24_regular),
  'externalLink': (
    AppIcons.externalLink,
    FluentIcons.open_20_regular,
    FluentIcons.open_24_regular,
  ),
  'pin': (AppIcons.pin, FluentIcons.pin_20_regular, FluentIcons.pin_24_regular),
  'unpin': (
    AppIcons.unpin,
    FluentIcons.pin_off_20_regular,
    FluentIcons.pin_off_24_regular,
  ),
  'delete': (
    AppIcons.delete,
    FluentIcons.delete_20_regular,
    FluentIcons.delete_24_regular,
  ),
  'retry': (
    AppIcons.retry,
    FluentIcons.arrow_clockwise_20_regular,
    FluentIcons.arrow_clockwise_24_regular,
  ),
  'rename': (
    AppIcons.rename,
    FluentIcons.edit_20_regular,
    FluentIcons.edit_24_regular,
  ),
  'play': (
    AppIcons.play,
    FluentIcons.play_20_regular,
    FluentIcons.play_24_regular,
  ),
  'pause': (
    AppIcons.pause,
    FluentIcons.pause_20_regular,
    FluentIcons.pause_24_regular,
  ),
  'zoomIn': (
    AppIcons.zoomIn,
    FluentIcons.zoom_in_20_regular,
    FluentIcons.zoom_in_24_regular,
  ),
  'zoomOut': (
    AppIcons.zoomOut,
    FluentIcons.zoom_out_20_regular,
    FluentIcons.zoom_out_24_regular,
  ),
  'fit': (
    AppIcons.fit,
    FluentIcons.zoom_fit_20_regular,
    FluentIcons.zoom_fit_24_regular,
  ),
  'expand': (
    AppIcons.expand,
    FluentIcons.chevron_down_20_regular,
    FluentIcons.chevron_down_24_regular,
  ),
  'collapse': (
    AppIcons.collapse,
    FluentIcons.chevron_up_20_regular,
    FluentIcons.chevron_up_24_regular,
  ),
  'warning': (
    AppIcons.warning,
    FluentIcons.warning_20_regular,
    FluentIcons.warning_24_regular,
  ),
  'error': (
    AppIcons.error,
    FluentIcons.error_circle_20_regular,
    FluentIcons.error_circle_24_regular,
  ),
  'info': (
    AppIcons.info,
    FluentIcons.info_20_regular,
    FluentIcons.info_24_regular,
  ),
  'securityBlock': (
    AppIcons.securityBlock,
    FluentIcons.shield_error_20_regular,
    FluentIcons.shield_error_24_regular,
  ),
  'web': (
    AppIcons.web,
    FluentIcons.globe_20_regular,
    FluentIcons.globe_24_regular,
  ),
  'jumpToLatest': (
    AppIcons.jumpToLatest,
    FluentIcons.arrow_down_20_regular,
    FluentIcons.arrow_down_24_regular,
  ),
  'add': (AppIcons.add, FluentIcons.add_20_regular, FluentIcons.add_24_regular),
  'calendar': (
    AppIcons.calendar,
    FluentIcons.calendar_ltr_20_regular,
    FluentIcons.calendar_ltr_24_regular,
  ),
  'menu': (
    AppIcons.menu,
    FluentIcons.navigation_20_regular,
    FluentIcons.navigation_24_regular,
  ),
  'list': (
    AppIcons.list,
    FluentIcons.text_bullet_list_ltr_20_regular,
    FluentIcons.text_bullet_list_ltr_24_regular,
  ),
  'folder': (
    AppIcons.folder,
    FluentIcons.folder_20_regular,
    FluentIcons.folder_24_regular,
  ),
  'apps': (
    AppIcons.apps,
    FluentIcons.apps_20_regular,
    FluentIcons.apps_24_regular,
  ),
  'back': (
    AppIcons.back,
    FluentIcons.arrow_left_20_regular,
    FluentIcons.arrow_left_24_regular,
  ),
  'next': (
    AppIcons.next,
    FluentIcons.arrow_right_20_regular,
    FluentIcons.arrow_right_24_regular,
  ),
  'loading': (
    AppIcons.loading,
    FluentIcons.hourglass_20_regular,
    FluentIcons.hourglass_24_regular,
  ),
  'offline': (
    AppIcons.offline,
    FluentIcons.cloud_off_20_regular,
    FluentIcons.cloud_off_24_regular,
  ),
  'empty': (
    AppIcons.empty,
    FluentIcons.tray_item_remove_20_regular,
    FluentIcons.tray_item_remove_24_regular,
  ),
  'notFound': (
    AppIcons.notFound,
    FluentIcons.search_info_20_regular,
    FluentIcons.search_info_24_regular,
  ),
  'login': (
    AppIcons.login,
    FluentIcons.person_arrow_right_20_regular,
    FluentIcons.person_arrow_right_24_regular,
  ),
  'activity': (
    AppIcons.activity,
    FluentIcons.pulse_20_regular,
    FluentIcons.pulse_24_regular,
  ),
  'active': (
    AppIcons.active,
    FluentIcons.record_20_regular,
    FluentIcons.record_24_regular,
  ),
  'category': (
    AppIcons.category,
    FluentIcons.shapes_20_regular,
    FluentIcons.shapes_24_regular,
  ),
  'document': (
    AppIcons.document,
    FluentIcons.note_20_regular,
    FluentIcons.note_24_regular,
  ),
  'chatsSelected': (
    AppIcons.chatsSelected,
    FluentIcons.chat_multiple_20_filled,
    FluentIcons.chat_multiple_24_filled,
  ),
  'memorySelected': (
    AppIcons.memorySelected,
    FluentIcons.brain_circuit_20_filled,
    FluentIcons.brain_circuit_24_filled,
  ),
  'personasSelected': (
    AppIcons.personasSelected,
    FluentIcons.people_20_filled,
    FluentIcons.people_24_filled,
  ),
  'usageSelected': (
    AppIcons.usageSelected,
    FluentIcons.data_bar_vertical_20_filled,
    FluentIcons.data_bar_vertical_24_filled,
  ),
  'settingsSelected': (
    AppIcons.settingsSelected,
    FluentIcons.settings_20_filled,
    FluentIcons.settings_24_filled,
  ),
  'pinSelected': (
    AppIcons.pinSelected,
    FluentIcons.pin_20_filled,
    FluentIcons.pin_24_filled,
  ),
  'playSelected': (
    AppIcons.playSelected,
    FluentIcons.play_20_filled,
    FluentIcons.play_24_filled,
  ),
};

void main() {
  test('every AppIcons glyph is the Fluent glyph of the issue 60 table', () {
    expect(_map, hasLength(69)); // 62 regular and 7 selected
    expect(AppIcons.all, unorderedEquals(_map.values.map((e) => e.$1)));
    for (final MapEntry(key: name, value: (icon, glyph, large))
        in _map.entries) {
      expect(icon, glyph, reason: name);
      expect(AppIcons.large(icon), large, reason: '$name large');
      expect(_families, contains(icon.fontFamily), reason: name);
      expect(icon.fontPackage, 'fluentui_system_icons');
    }
  });

  test('regular by default, filled for the selected state', () {
    for (final MapEntry(key: name, value: (icon, _, _)) in _map.entries) {
      expect(
        icon.fontFamily,
        name.endsWith('Selected')
            ? 'FluentSystemIcons-Filled'
            : 'FluentSystemIcons-Regular',
        reason: name,
      );
    }
  });
}
