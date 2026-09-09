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
  String get landingTag => 'MVP ระบบประสาทขั้นทดลอง';

  @override
  String get landingHeroTitle => 'ความชาญฉลาดที่ไร้สิ่งรบกวน';

  @override
  String get landingHeroSubtitle =>
      'พื้นที่ทำงานขั้นทดลองในระยะเริ่มต้นสำหรับการให้เหตุผลและการสนทนาแบบถาวร สร้างขึ้นเพื่อการโฟกัสลึกพร้อมการปกป้องความเป็นส่วนตัว';

  @override
  String get getStarted => 'เริ่มต้นใช้งาน';

  @override
  String get ssoAuthHint => '[ ซิงเกิลไซน์ออน • ต้องมีบัญชี ]';

  @override
  String get aboutAsodya => 'เกี่ยวกับ Asodya';

  @override
  String get logIn => 'เข้าสู่ระบบ';

  @override
  String get signUp => 'ลงทะเบียน';

  @override
  String get footerWorkspace => 'ASODYA CORTEX // MVP ขั้นทดลอง (ระดับ 0)';

  @override
  String get allRightsReserved => '© 2026 ASODYA. สงวนลิขสิทธิ์ทั้งหมด';

  @override
  String get card1Number => '01 / สถาปัตยกรรม';

  @override
  String get card1Title => 'การประมวลผลเชิงเหตุผล';

  @override
  String get card1Description =>
      'การสตรีมข้อความตอบกลับตามบริบทแบบเรียลไทม์ ขับเคลื่อนโดยโมเดลระดับ 0 น้ำหนักเบาและสภาพแวดล้อมที่แยกส่วน';

  @override
  String get card2Number => '02 / ความเป็นส่วนตัว';

  @override
  String get card2Title => 'ความเป็นส่วนตัวเป็นหลัก';

  @override
  String get card2Description =>
      'ข้อมูลระบบได้รับการแยกส่วนอย่างเคร่งครัดที่ระดับโครงสร้างพื้นฐาน คำสั่งและการสนทนาของคุณจะคงความเป็นส่วนตัวอย่างสมบูรณ์';

  @override
  String get card3Number => '03 / ความต่อเนื่อง';

  @override
  String get card3Title => 'ร่างข้อความถาวร';

  @override
  String get card3Description =>
      'การแคชข้อความร่างในเครื่องและการกู้คืนเซสชันในทุกอุปกรณ์ผ่านระบบยืนยันตัวตน Asodya SSO';

  @override
  String get newConversation => 'การสนทนาใหม่';

  @override
  String get noConversationsYetTitle => 'ยังไม่มีการสนทนา';

  @override
  String get noConversationsYetBody =>
      'เริ่มการสนทนาใหม่เพื่อเริ่มแชทกับ Cortex';

  @override
  String get history => 'ประวัติการใช้งาน';

  @override
  String get clearAll => 'ล้างทั้งหมด';

  @override
  String get clearAllTitle => 'ล้างการสนทนาทั้งหมด';

  @override
  String get clearAllConfirmation =>
      'คุณแน่ใจหรือไม่ว่าต้องการลบการสนทนาทั้งหมดอย่างถาวร? การดำเนินการนี้ไม่สามารถยกเลิกได้';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get logOut => 'ออกจากระบบ';

  @override
  String get logOutTitle => 'ออกจากระบบ';

  @override
  String get logOutConfirmation =>
      'คุณจะออกจากระบบ Cortex บนอุปกรณ์นี้ และต้องเข้าสู่ระบบใหม่อีกครั้ง';

  @override
  String get delete => 'ลบ';

  @override
  String get webResearchPill => 'ค้นหาเว็บ';

  @override
  String get memoryEnginePill => 'ระบบความจำ';

  @override
  String get attachTooltip => 'แนบไฟล์หรือรูปภาพ';

  @override
  String get userBadgePro => 'PRO // ASODYA AUTH';

  @override
  String get tier0Badge => 'ระดับ 0 // CORTEX-T0';

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
  String get messageHint => 'ส่งข้อความถึง Cortex (ระดับ 0)...';

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
  String get webBrowsingSubtitle =>
      'ใช้การค้นหาเว็บประกอบคำตอบ ใช้ได้ในระดับ 0';

  @override
  String get webSearchOnTooltip =>
      'เปิดการค้นหาเว็บแล้ว: คำตอบนี้จะอ้างอิงจากการค้นหาเว็บ (needs_web)';

  @override
  String get webSearchOffTooltip =>
      'เปิดใช้การค้นหาเว็บประกอบคำตอบ (needs_web)';

  @override
  String sourcesCount(int count) {
    return 'แหล่งที่มา ($count)';
  }

  @override
  String get attachFile => 'แนบไฟล์';

  @override
  String get attachImage => 'รูปภาพ';

  @override
  String get attachDocument => 'เอกสาร';

  @override
  String get removeAttachment => 'ลบไฟล์แนบ';

  @override
  String get documentAttachmentBackendGap =>
      'ไฟล์ที่รองรับ: รูปภาพ, เสียง, PDF, Word (.docx) และไฟล์ข้อความ/JSON/XML ทั่วไป';

  @override
  String get voiceStartRecording => 'บันทึกข้อความเสียง';

  @override
  String get voiceFeatureNotReady => 'ข้อความเสียง: ยังไม่พร้อมใช้งาน';

  @override
  String get suggestionSystemTag => 'การวิเคราะห์ระบบ';

  @override
  String get suggestionSystemTitle => 'วิเคราะห์ telemetry และคอขวดของระบบ';

  @override
  String get suggestionSystemSubtitle =>
      'ระบุคอขวดของเวลาแฝงและวิเคราะห์การใช้หน่วยความจำ';

  @override
  String get suggestionSystemPrompt =>
      'วิเคราะห์เมตริกระบบปัจจุบันและระบุคอขวดของหน่วยความจำ/เวลาแฝง';

  @override
  String get suggestionArchitectureTag => 'สถาปัตยกรรม';

  @override
  String get suggestionArchitectureTitle =>
      'สำรวจข้อแลกเปลี่ยนของสถาปัตยกรรมแบบกระจาย';

  @override
  String get suggestionArchitectureSubtitle =>
      'เปรียบเทียบ streaming facade กับโมเดลการประมวลผลแบบ batch';

  @override
  String get suggestionArchitecturePrompt =>
      'อธิบายข้อแลกเปลี่ยนทางสถาปัตยกรรมระหว่าง token streaming facade กับ RPC execute';

  @override
  String get suggestionPipelineTag => 'โค้ดไปป์ไลน์';

  @override
  String get suggestionPipelineTitle => 'ร่าง API gateway แบบอะซิงโครนัส';

  @override
  String get suggestionPipelineSubtitle =>
      'สร้างบริการที่ทนทานด้วย streaming SSE และการตรวจสอบสถานะ';

  @override
  String get suggestionPipelinePrompt =>
      'เขียนบริการ Python FastAPI ที่เชื่อมต่อกับ AI gateway แบบแยกส่วนพร้อมการตรวจสอบสถานะ';

  @override
  String get voiceCancelRecording => 'ยกเลิกการบันทึก';

  @override
  String get voiceSendRecording => 'ส่งข้อความเสียง';

  @override
  String get micPermissionDenied =>
      'ไม่สามารถใช้งานไมโครโฟนได้ หรือการเข้าถึงถูกปฏิเสธ';

  @override
  String get voiceMessageTooShort => 'การบันทึกสั้นเกินไปที่จะส่ง';

  @override
  String get incognitoModeTitle => 'แชทไม่ระบุตัวตน';

  @override
  String get incognitoModeSubtitle =>
      'เซสชันชั่วคราว ไม่บันทึกประวัติและปิดใช้งานความจำอย่างชัดเจน';

  @override
  String get newIncognitoChat => 'เริ่มแชทไม่ระบุตัวตน';

  @override
  String couldNotSendMessage(String error) {
    return 'ไม่สามารถส่งข้อความได้: $error';
  }

  @override
  String get scrollToBottomTooltip => 'เลื่อนไปด้านล่างสุด';

  @override
  String get codeBlockPlainLabel => 'โค้ด';

  @override
  String get codeBlockCopyLabel => 'คัดลอก';

  @override
  String get codeBlockCopiedLabel => 'คัดลอกแล้ว!';

  @override
  String get continueGenerationLabel => 'สร้างคำตอบต่อ';

  @override
  String get continueGenerationTooltip =>
      'การเชื่อมต่อขาดหายระหว่างการตอบกลับ การกดนี้จะลองส่งคำขอใหม่ทั้งหมด (cortex_api ไม่สามารถสร้างคำตอบต่อจากส่วนที่ค้างไว้ได้) และจะแทนที่ข้อความนี้เมื่อได้คำตอบใหม่';

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get exportChatTooltip => 'ส่งออกแชทเป็น Markdown';

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

  @override
  String get improveInputLabel => 'ปรับปรุงข้อความนำเข้า';

  @override
  String get improveInputSubtitle =>
      'เขียนและปรับความชัดเจนของคำสั่งโดยอัตโนมัติด้วยโมเดลให้เหตุผลในเครื่องก่อนเริ่มสร้างคำตอบ';

  @override
  String get incognitoBadge => 'ไม่ระบุตัวตน';

  @override
  String get startIncognito => 'เริ่มการสนทนาแบบไม่ระบุตัวตน';

  @override
  String get exitIncognito => 'ออกจากการสนทนาไม่ระบุตัวตน';

  @override
  String get memoryGraphTooltip => 'กราฟความทรงจำ';

  @override
  String get memoryGraphTitle => 'กราฟความทรงจำ';

  @override
  String get memoryGraphEmptyTitle => 'ยังไม่มีความทรงจำ';

  @override
  String get memoryGraphEmptyBody =>
      'เมื่อ Cortex จดจำบางสิ่ง มันจะแสดงที่นี่เป็นกราฟ';

  @override
  String get memoryGraphTruncatedNotice =>
      'มุมมองนี้ไม่ได้แสดงกราฟทั้งหมด บางโหนดถูกละไว้';

  @override
  String get memoryGraphNoContextAvailable => 'ไม่มีบริบทสำหรับโหนดนี้';

  @override
  String get memoryGraphTimeJustNow => 'เมื่อสักครู่';

  @override
  String memoryGraphTimeMinutesAgo(int count) {
    return '$count นาทีที่แล้ว';
  }

  @override
  String memoryGraphTimeHoursAgo(int count) {
    return '$count ชั่วโมงที่แล้ว';
  }

  @override
  String memoryGraphTimeDaysAgo(int count) {
    return '$count วันที่แล้ว';
  }

  @override
  String get memoryGraphTypeMemory => 'ความทรงจำ';

  @override
  String get memoryGraphTypeAttachment => 'ไฟล์แนบ';

  @override
  String get memoryGraphTypeTag => 'แท็ก';

  @override
  String get memoryGraphTypeEntity => 'เอนทิตี';

  @override
  String get memoryGraphTypeResource => 'แหล่งข้อมูล';

  @override
  String get memoryGraphTypeCluster => 'กลุ่ม';

  @override
  String memoryGraphClusterCount(int count) {
    return 'อีก $count รายการ';
  }

  @override
  String memoryGraphClusterExpandedCount(int count) {
    return 'แสดง $count รายการ';
  }

  @override
  String get memoryGraphResetPositionsTooltip => 'รีเซ็ตตำแหน่ง';

  @override
  String get supportTitle => 'ฝ่ายสนับสนุน';

  @override
  String get newTicketAction => 'สร้างเรื่องใหม่';

  @override
  String get noSupportTicketsYetTitle => 'ยังไม่มีเรื่องแจ้งฝ่ายสนับสนุน';

  @override
  String get noSupportTicketsYetBody =>
      'สร้างเรื่องใหม่หากคุณต้องการความช่วยเหลือหรือต้องการแจ้งปัญหา';

  @override
  String get ticketStatusOpen => 'เปิดอยู่';

  @override
  String get ticketStatusPending => 'รอดำเนินการ';

  @override
  String get ticketStatusResolved => 'แก้ไขแล้ว';

  @override
  String get ticketStatusClosed => 'ปิดแล้ว';

  @override
  String get ticketSubjectLabel => 'หัวข้อ';

  @override
  String get ticketSubjectHint => 'เรื่องนี้เกี่ยวกับอะไร (ไม่บังคับ)';

  @override
  String get ticketBodyLabel => 'ข้อความ';

  @override
  String get ticketReplyHint => 'พิมพ์ข้อความของคุณ...';

  @override
  String get attachImageAction => 'แนบรูปภาพ';

  @override
  String get submitAction => 'ส่ง';

  @override
  String get supportTicketDetailTitle => 'เรื่องแจ้งฝ่ายสนับสนุน';

  @override
  String get ticketThreadUnavailableNotice =>
      'ประวัติข้อความไม่พร้อมใช้งานชั่วคราว เรื่องของคุณยังเปิดอยู่';

  @override
  String get supportTeamLabel => 'ทีมสนับสนุน';

  @override
  String get youLabel => 'คุณ';

  @override
  String get attachmentLabel => 'ไฟล์แนบ';

  @override
  String get tryAgainAction => 'ลองอีกครั้ง';

  @override
  String get errorLoadingTicketsMessage =>
      'ไม่สามารถโหลดเรื่องแจ้งฝ่ายสนับสนุนของคุณได้';

  @override
  String get ticketActionFailedMessage => 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง';

  @override
  String get genericErrorTitle => 'เกิดข้อผิดพลาดบางอย่าง';

  @override
  String get genericErrorMessage =>
      'เราพบปัญหาที่ไม่คาดคิด คุณสามารถแจ้งให้เราทราบเพื่อตรวจสอบได้';

  @override
  String get contactSupportAction => 'ติดต่อฝ่ายสนับสนุน';

  @override
  String get errorReportTicketSubject => 'ข้อผิดพลาดที่ไม่คาดคิดใน Cortex';

  @override
  String get errorReportTicketBodyIntro =>
      'ฉันพบปัญหาที่ไม่คาดคิดขณะใช้งาน Cortex รายละเอียดทางเทคนิคด้านล่างอาจช่วยได้:';
}
