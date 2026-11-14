import 'package:flutter/widgets.dart';

/// Fluent UI System Icons (Microsoft, MIT, package fluentui_system_icons
/// 1.1.273), named by their purpose in Cortex (issue #60).
///
/// Regular 20 px glyphs by default; `<name>Selected` is the filled glyph for
/// selected nav items and active toggles. Use [large] for 24 px icons:
/// Fluent icons are drawn for their exact size.
///
/// The glyphs are declared here by code point, with the Fluent glyph name above
/// each one, instead of through the package class `FluentIcons`. That class
/// is not marked `@staticIconProvider`, so the release build keeps almost all
/// of its 8,000 glyphs. With these constants only the used glyphs ship.
/// `test/design/icons_test.dart` checks every code point against `FluentIcons`.
abstract final class AppIcons {
  /// `FluentIcons.chat_multiple_20_regular`
  static const chats = IconData(
    0xF8C8,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.brain_circuit_20_regular`
  static const memory = IconData(
    0xF1EE,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.people_20_regular`
  static const personas = IconData(
    0xF5A8,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.data_bar_vertical_20_regular`
  static const usage = IconData(
    0xF33F,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.compose_20_regular`
  static const newChat = IconData(
    0xF314,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.eye_off_20_regular`
  static const temporaryChat = IconData(
    0xE5F5,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.person_circle_20_regular`
  static const account = IconData(
    0xE928,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.settings_20_regular`
  static const settings = IconData(
    0xF6A9,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.desktop_20_regular`
  static const systemTheme = IconData(
    0xF359,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.weather_sunny_20_regular`
  static const lightTheme = IconData(
    0xF8A1,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.weather_moon_20_regular`
  static const darkTheme = IconData(
    0xF87D,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.local_language_20_regular`
  static const language = IconData(
    0xF4F3,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.sign_out_20_regular`
  static const logOut = IconData(
    0xEAFA,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.search_20_regular`
  static const search = IconData(
    0xF68F,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.attach_20_regular`
  static const attach = IconData(
    0xF1A9,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.send_20_regular`
  static const send = IconData(
    0xF699,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.stop_20_regular`
  static const stop = IconData(
    0xF72A,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.copy_20_regular`
  static const copy = IconData(
    0xF32B,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.checkmark_20_regular`
  static const copied = IconData(
    0xF294,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.dismiss_20_regular`
  static const close = IconData(
    0xF369,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.more_horizontal_20_regular`
  static const more = IconData(
    0xE824,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.document_text_20_regular`
  static const file = IconData(
    0xE557,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.tag_20_regular`
  static const tag = IconData(
    0xF77C,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.person_20_regular`
  static const entity = IconData(
    0xF5BD,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.lightbulb_20_regular`
  static const note = IconData(
    0xF4D6,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.bot_20_regular`
  static const bot = IconData(
    0xE1B8,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.open_20_regular`
  static const externalLink = IconData(
    0xF582,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.pin_20_regular`
  static const pin = IconData(
    0xF601,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.pin_off_20_regular`
  static const unpin = IconData(
    0xF603,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.delete_20_regular`
  static const delete = IconData(
    0xF34C,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.arrow_clockwise_20_regular`
  static const retry = IconData(
    0xF13D,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.edit_20_regular`
  static const rename = IconData(
    0xF3DD,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.play_20_regular`
  static const play = IconData(
    0xF605,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.pause_20_regular`
  static const pause = IconData(
    0xF5A1,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.zoom_in_20_regular`
  static const zoomIn = IconData(
    0xF8C4,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.zoom_out_20_regular`
  static const zoomOut = IconData(
    0xF8C6,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.zoom_fit_20_regular`
  static const fit = IconData(
    0xEE8C,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.chevron_down_20_regular`
  static const expand = IconData(
    0xF2A3,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.chevron_up_20_regular`
  static const collapse = IconData(
    0xF2B6,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.warning_20_regular`
  static const warning = IconData(
    0xF869,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.error_circle_20_regular`
  static const error = IconData(
    0xF3F1,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.info_20_regular`
  static const info = IconData(
    0xF4A3,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.shield_error_20_regular`
  static const securityBlock = IconData(
    0xF6C2,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.globe_20_regular`
  static const web = IconData(
    0xF45A,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.arrow_down_20_regular`
  static const jumpToLatest = IconData(
    0xF148,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.add_20_regular`
  static const add = IconData(
    0xF109,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.calendar_ltr_20_regular`
  static const calendar = IconData(
    0xE24E,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.navigation_20_regular`
  static const menu = IconData(
    0xF560,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.text_bullet_list_ltr_20_regular`
  static const list = IconData(
    0xECD9,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.folder_20_regular`
  static const folder = IconData(
    0xF418,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.apps_20_regular`
  static const apps = IconData(
    0xF133,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.arrow_left_20_regular`
  static const back = IconData(
    0xF15B,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// `FluentIcons.arrow_right_20_regular`
  static const next = IconData(
    0xF181,
    fontFamily: _regular,
    fontPackage: _package,
    matchTextDirection: true,
  );

  /// `FluentIcons.hourglass_20_regular`
  static const loading = IconData(
    0xEF6B,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.cloud_off_20_regular`
  static const offline = IconData(
    0xE3A8,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.tray_item_remove_20_regular`
  static const empty = IconData(
    0xEDA0,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.search_info_20_regular`
  static const notFound = IconData(
    0xF692,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.person_arrow_right_20_regular`
  static const login = IconData(
    0xF5C7,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.pulse_20_regular`
  static const activity = IconData(
    0xE9DC,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.record_20_regular`
  static const active = IconData(
    0xF661,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.shapes_20_regular`
  static const category = IconData(
    0xF6AD,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.note_20_regular`
  static const document = IconData(
    0xF56B,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.checkmark_circle_20_regular` (success status)
  static const success = IconData(
    0xF298,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// `FluentIcons.checkmark_12_filled` (checkbox mark, 12 px only)
  static const checkboxMark = IconData(
    0xF293,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// `FluentIcons.chat_multiple_20_filled` (selected state)
  static const chatsSelected = IconData(
    0xF8E0,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// `FluentIcons.brain_circuit_20_filled` (selected state)
  static const memorySelected = IconData(
    0xF1EE,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// `FluentIcons.people_20_filled` (selected state)
  static const personasSelected = IconData(
    0xF5B2,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// `FluentIcons.data_bar_vertical_20_filled` (selected state)
  static const usageSelected = IconData(
    0xF33F,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// `FluentIcons.settings_20_filled` (selected state)
  static const settingsSelected = IconData(
    0xF6B2,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// `FluentIcons.pin_20_filled` (selected state)
  static const pinSelected = IconData(
    0xF60B,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// `FluentIcons.play_20_filled` (selected state)
  static const playSelected = IconData(
    0xF60F,
    fontFamily: _filled,
    fontPackage: _package,
  );

  /// Every 20 px icon above with its 24 px glyph of the same name.
  static final Map<IconData, IconData> _large = {
    success: const IconData(
      0xF299,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    chats: const IconData(0xF8D3, fontFamily: _regular, fontPackage: _package),
    chatsSelected: const IconData(
      0xF8EB,
      fontFamily: _filled,
      fontPackage: _package,
    ),
    memory: const IconData(0xF83B, fontFamily: _regular, fontPackage: _package),
    memorySelected: const IconData(
      0xF853,
      fontFamily: _filled,
      fontPackage: _package,
    ),
    personas: const IconData(
      0xF5A9,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    personasSelected: const IconData(
      0xF5B3,
      fontFamily: _filled,
      fontPackage: _package,
    ),
    usage: const IconData(0xF340, fontFamily: _regular, fontPackage: _package),
    usageSelected: const IconData(
      0xF340,
      fontFamily: _filled,
      fontPackage: _package,
    ),
    newChat: const IconData(
      0xF315,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    temporaryChat: const IconData(
      0xE5F6,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    account: const IconData(
      0xE929,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    settings: const IconData(
      0xF6AA,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    settingsSelected: const IconData(
      0xF6B3,
      fontFamily: _filled,
      fontPackage: _package,
    ),
    systemTheme: const IconData(
      0xF35A,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    lightTheme: const IconData(
      0xF8A2,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    darkTheme: const IconData(
      0xF87E,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    language: const IconData(
      0xF4F4,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    logOut: const IconData(0xF6DA, fontFamily: _regular, fontPackage: _package),
    search: const IconData(0xF690, fontFamily: _regular, fontPackage: _package),
    attach: const IconData(0xF1AA, fontFamily: _regular, fontPackage: _package),
    send: const IconData(0xF69A, fontFamily: _regular, fontPackage: _package),
    stop: const IconData(0xF72B, fontFamily: _regular, fontPackage: _package),
    copy: const IconData(0xF32C, fontFamily: _regular, fontPackage: _package),
    copied: const IconData(0xF295, fontFamily: _regular, fontPackage: _package),
    close: const IconData(0xF36A, fontFamily: _regular, fontPackage: _package),
    more: const IconData(0xE825, fontFamily: _regular, fontPackage: _package),
    file: const IconData(0xE558, fontFamily: _regular, fontPackage: _package),
    tag: const IconData(0xF77D, fontFamily: _regular, fontPackage: _package),
    entity: const IconData(0xF5BE, fontFamily: _regular, fontPackage: _package),
    note: const IconData(0xF4D7, fontFamily: _regular, fontPackage: _package),
    bot: const IconData(0xF1F9, fontFamily: _regular, fontPackage: _package),
    externalLink: const IconData(
      0xF583,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    pin: const IconData(0xF602, fontFamily: _regular, fontPackage: _package),
    pinSelected: const IconData(
      0xF60C,
      fontFamily: _filled,
      fontPackage: _package,
    ),
    unpin: const IconData(0xF604, fontFamily: _regular, fontPackage: _package),
    delete: const IconData(0xF34D, fontFamily: _regular, fontPackage: _package),
    retry: const IconData(0xF13E, fontFamily: _regular, fontPackage: _package),
    rename: const IconData(0xF3DE, fontFamily: _regular, fontPackage: _package),
    play: const IconData(0xF606, fontFamily: _regular, fontPackage: _package),
    playSelected: const IconData(
      0xF610,
      fontFamily: _filled,
      fontPackage: _package,
    ),
    pause: const IconData(0xF5A2, fontFamily: _regular, fontPackage: _package),
    zoomIn: const IconData(0xF8C5, fontFamily: _regular, fontPackage: _package),
    zoomOut: const IconData(
      0xF8C7,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    fit: const IconData(0xEE8D, fontFamily: _regular, fontPackage: _package),
    expand: const IconData(0xF2A4, fontFamily: _regular, fontPackage: _package),
    collapse: const IconData(
      0xF2B7,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    warning: const IconData(
      0xF86A,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    error: const IconData(0xF3F2, fontFamily: _regular, fontPackage: _package),
    info: const IconData(0xF4A4, fontFamily: _regular, fontPackage: _package),
    securityBlock: const IconData(
      0xF6C3,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    web: const IconData(0xF45B, fontFamily: _regular, fontPackage: _package),
    jumpToLatest: const IconData(
      0xF149,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    add: const IconData(0xF10A, fontFamily: _regular, fontPackage: _package),
    calendar: const IconData(
      0xE24F,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    menu: const IconData(0xF561, fontFamily: _regular, fontPackage: _package),
    list: const IconData(0xECDA, fontFamily: _regular, fontPackage: _package),
    folder: const IconData(0xF419, fontFamily: _regular, fontPackage: _package),
    apps: const IconData(0xF134, fontFamily: _regular, fontPackage: _package),
    back: const IconData(
      0xF15C,
      fontFamily: _regular,
      fontPackage: _package,
      matchTextDirection: true,
    ),
    next: const IconData(
      0xF182,
      fontFamily: _regular,
      fontPackage: _package,
      matchTextDirection: true,
    ),
    loading: const IconData(
      0xEF6C,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    offline: const IconData(
      0xF2EA,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    empty: const IconData(0xEDA1, fontFamily: _regular, fontPackage: _package),
    notFound: const IconData(
      0xF693,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    login: const IconData(0xF5C8, fontFamily: _regular, fontPackage: _package),
    activity: const IconData(
      0xE9DD,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    active: const IconData(0xF662, fontFamily: _regular, fontPackage: _package),
    category: const IconData(
      0xF6AE,
      fontFamily: _regular,
      fontPackage: _package,
    ),
    document: const IconData(
      0xF56C,
      fontFamily: _regular,
      fontPackage: _package,
    ),
  };

  /// The 24 px glyph of [icon], for large touch controls at compact width.
  static IconData large(IconData icon) => _large[icon] ?? icon;

  /// All 20 px icons, for tests.
  static Iterable<IconData> get all => _large.keys;
}

const _package = 'fluentui_system_icons';
const _regular = 'FluentSystemIcons-Regular';
const _filled = 'FluentSystemIcons-Filled';
