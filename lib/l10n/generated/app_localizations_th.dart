// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Cortex';

  @override
  String get landingTagline =>
      'พื้นที่สงบสีขาวดำสำหรับคิดออกเสียง โดยมีสีสันพลิ้วไหวอยู่เบื้องหลัง';

  @override
  String get signInWithAsodya => 'เข้าสู่ระบบด้วย Asodya';

  @override
  String get continueAsGuest => 'ดำเนินการต่อในฐานะผู้เยี่ยมชม';

  @override
  String get guestModeNotice =>
      'โหมดผู้เยี่ยมชมข้ามการเข้าสู่ระบบทั้งหมด เป็นเพียงทางลัดในเครื่อง ไม่ใช่บัญชี Asodya';

  @override
  String get collapseSidebar => 'ย่อแถบด้านข้าง';

  @override
  String get expandSidebar => 'ขยายแถบด้านข้าง';

  @override
  String get openSettings => 'ตั้งค่า';

  @override
  String get sessionOptions => 'ตัวเลือกเซสชัน';

  @override
  String get tierZeroLabel => 'ระดับ 0 - ฟรีและรวดเร็ว';

  @override
  String get messageHint => 'ส่งข้อความถึง Cortex...';

  @override
  String lockedFeatureNotice(String tier) {
    return '$tier: ฟีเจอร์นี้จะปลดล็อกในระดับที่สูงขึ้น';
  }

  @override
  String attachFileLocked(String tier) {
    return 'แนบไฟล์ (ล็อกอยู่ที่ $tier)';
  }

  @override
  String webBrowsingLocked(String tier) {
    return 'การท่องเว็บ (ล็อกอยู่ที่ $tier)';
  }

  @override
  String get memoryRecallOnTooltip =>
      'เปิดใช้งานความจำแล้ว: คำตอบนี้จะใช้ /execute แบบเนทีฟของ cortex_api พร้อมการเรียกคืนความจำฝั่งเซิร์ฟเวอร์';

  @override
  String get memoryRecallOffTooltip =>
      'เปิดใช้งานการเรียกคืนความจำ (/execute แบบเนทีฟ)';

  @override
  String get memoryRecallTitle => 'การเรียกคืนความจำ';

  @override
  String get memoryRecallSubtitle =>
      'ใช้ /execute แบบเนทีฟของ cortex_api พร้อมการเรียกคืนความจำฝั่งเซิร์ฟเวอร์ ใช้ได้ในระดับ 0';

  @override
  String get webBrowsingTitle => 'การท่องเว็บ';

  @override
  String get webBrowsingSubtitle => 'ล็อกอยู่ในระดับ 0';

  @override
  String get liveLogsTooltip => 'บันทึกสด (สำหรับการพัฒนาในเครื่องเท่านั้น)';

  @override
  String get liveLogsTitle => 'บันทึกสดของ Cortex';

  @override
  String get liveLogsDescription =>
      'สำหรับการพัฒนาในเครื่องเท่านั้น: เชื่อมต่อโดยตรงกับ /logs/stream ของ cortex_api ซึ่งข้ามพร็อกซีของ api_for_apps (ที่ไม่รองรับ WebSocket)';

  @override
  String liveLogsConnectionError(String error) {
    return 'ไม่สามารถเชื่อมต่อได้: $error';
  }

  @override
  String get liveLogsWaiting => 'กำลังรอบรรทัดบันทึก...';

  @override
  String couldNotSendMessage(String error) {
    return 'ไม่สามารถส่งข้อความได้: $error';
  }

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get themeLabel => 'ธีม';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get themeSystem => 'ตามระบบ';

  @override
  String get languageLabel => 'ภาษา';

  @override
  String get languageEnglish => 'อังกฤษ';

  @override
  String get languagePortuguese => 'โปรตุเกส';

  @override
  String get languageThai => 'ไทย';
}
