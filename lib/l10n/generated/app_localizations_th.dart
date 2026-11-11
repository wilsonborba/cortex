// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get logIn => 'เข้าสู่ระบบ';

  @override
  String get logOut => 'ออกจากระบบ';

  @override
  String get newChat => 'แชทใหม่';

  @override
  String get temporaryChat => 'แชทชั่วคราว';

  @override
  String get chats => 'แชท';

  @override
  String get memory => 'ความจำ';

  @override
  String get personas => 'เพอร์โซนา';

  @override
  String get usage => 'การใช้งาน';

  @override
  String get timing => 'เวลา';

  @override
  String get stats => 'สถิติ';

  @override
  String get events => 'เหตุการณ์';

  @override
  String get newPersona => 'เพอร์โซนาใหม่';

  @override
  String get details => 'รายละเอียด';

  @override
  String get close => 'ปิด';

  @override
  String get notFoundTitle => 'ไม่พบหน้านี้';

  @override
  String get notFoundMessage => 'ไม่มีเส้นทางหรือรายการนี้';

  @override
  String get goToChats => 'ไปที่แชท';

  @override
  String get signingIn => 'กำลังเปิดหน้าเข้าสู่ระบบ';

  @override
  String get noChatsYet => 'ยังไม่มีแชท';

  @override
  String get output => 'คำตอบ';

  @override
  String get product => 'ผลิตภัณฑ์';

  @override
  String get howItWorks => 'ทำงานอย่างไร';

  @override
  String get engineering => 'วิศวกรรม';

  @override
  String get faq => 'คำถามที่พบบ่อย';

  @override
  String get language => 'ภาษา';

  @override
  String get themeSwitch => 'ธีม';

  @override
  String get menu => 'เมนู';

  @override
  String get heroLabel => 'พื้นที่แชท AI';

  @override
  String get heroTitle => 'แชทกับความจำ ไฟล์ และเว็บของคุณ';

  @override
  String get heroLead =>
      'Cortex ตอบด้วยโมเดลในเครื่องและแสดงทุกขั้นตอน: ความจำ ไฟล์ แหล่งข้อมูลเว็บ และการคิด';

  @override
  String get startChat => 'เริ่มแชท';

  @override
  String get seeHow => 'ดูวิธีการทำงาน';

  @override
  String get example => 'ตัวอย่าง';

  @override
  String get demoMemoryPrompt => 'ฉันตัดสินใจอะไรเกี่ยวกับตัวจัดสรรการใช้งาน';

  @override
  String get demoFastPrompt => 'Rust เวอร์ชันเสถียรล่าสุดคืออะไร';

  @override
  String get demoDeepPrompt =>
      'เปรียบเทียบ SQLite และ PostgreSQL สำหรับเว็บแอปขนาดเล็ก';

  @override
  String get demoThinkPrompt => 'รถไฟออก 09:40 ถึง 13:05 ใช้เวลากี่นาที';

  @override
  String get demoMemoryAnswer =>
      'คุณตัดสินใจแบ่งอย่างยุติธรรมต่อผู้ใช้ใน 24 ชั่วโมง โดยผู้ใช้ใหม่มีน้ำหนักพื้นฐาน 1';

  @override
  String get demoFastAnswer =>
      'คำตอบมาจากหน้าเว็บที่อ่านตอนนี้ และแต่ละแหล่งอยู่ใต้คำตอบ';

  @override
  String get demoDeepAnswer =>
      'สำหรับแอปเล็กที่มีผู้เขียนน้อย SQLite ง่ายกว่า ส่วนผู้เขียนพร้อมกันจำนวนมาก PostgreSQL ปลอดภัยกว่า';

  @override
  String get demoThinkAnswer => 'การเดินทางใช้เวลา 205 นาที';

  @override
  String get demoReplay => 'เล่นซ้ำ';

  @override
  String get stepSecurity => 'ตรวจความปลอดภัยผ่าน';

  @override
  String get stepMemorySearch => 'กำลังค้นหาความจำของคุณ';

  @override
  String get stepMemoriesFound => 'พบความจำ';

  @override
  String get stepQueries => 'กำลังเตรียมคำค้น';

  @override
  String get stepWebSearch => 'กำลังค้นหาเว็บ';

  @override
  String get stepPageRead => 'กำลังอ่านหน้าเว็บ';

  @override
  String get stepThinking => 'ขั้นตอนการคิด';

  @override
  String get stepAnswer => 'กำลังเขียนคำตอบ';

  @override
  String get sources => 'แหล่งข้อมูล';

  @override
  String get whatTitle => 'ทำอะไรได้บ้าง';

  @override
  String get whatMemory => 'แชทพร้อมความจำ';

  @override
  String get whatMemoryText =>
      'Cortex หาความจำของคุณที่ตรงกับคำถามได้สูงสุด 5 รายการ และแสดงว่าใช้รายการใด';

  @override
  String get whatWeb => 'ค้นคว้าเว็บ';

  @override
  String get whatWebText =>
      'เร็ว กลาง หรือลึก: คำค้นและหน้าเว็บมากขึ้นสำหรับคำถามที่ยาก พร้อมแสดงทุกแหล่ง';

  @override
  String get whatFiles => 'ไฟล์';

  @override
  String get whatFilesText =>
      'PDF (มี OCR สำหรับหน้าที่สแกน) DOCX พร้อมตาราง เสียงยาวถึง 10 นาที และรูปภาพ';

  @override
  String get whatThinking => 'การคิด';

  @override
  String get whatThinkingText =>
      'ขั้นวางแผน ทำงาน และตรวจสอบก่อนคำตอบสุดท้าย สูงสุด 2 รอบ และหยุดการคิดได้ทุกเมื่อ';

  @override
  String get pipelineTitle => 'คำขอหนึ่งครั้งทำงานอย่างไร';

  @override
  String get stageAccept => 'รับคำขอ';

  @override
  String get stageGather => 'รวบรวม';

  @override
  String get stageAssemble => 'ประกอบ';

  @override
  String get stageThink => 'คิด';

  @override
  String get stageAnswer => 'ตอบ';

  @override
  String get stageSave => 'บันทึก';

  @override
  String get stageAcceptText => 'ตรวจขนาดและโทเค็น แล้วตรวจความปลอดภัย';

  @override
  String get stageGatherText => 'ไฟล์ ความจำ และเว็บพร้อมกัน';

  @override
  String get stageAssembleText => 'เติมบริบท 8192 โทเค็นตามลำดับที่กำหนด';

  @override
  String get stageThinkText => 'วางแผน ทำงาน และตรวจสอบ (ไม่บังคับ)';

  @override
  String get stageAnswerText => 'เรียกโมเดลหนึ่งครั้ง ส่งทีละโทเค็น';

  @override
  String get stageSaveText => 'ประวัติ ความจำ การใช้งาน และบันทึกการทำงาน';

  @override
  String get pipelineDescription =>
      'แผนภาพหกขั้นตอนของคำขอ: รับ รวบรวมไฟล์ ความจำ และเว็บพร้อมกัน ประกอบ คิด ตอบ และบันทึก';

  @override
  String get pause => 'หยุดชั่วคราว';

  @override
  String get play => 'เล่น';

  @override
  String get memoryTitle => 'ความจำด้วย Hippocampus';

  @override
  String get memoryScope =>
      'ทุกความจำมีขอบเขต: เวิร์กสเปซ แอป และผู้ใช้ การค้นหาไม่ออกนอกขอบเขต';

  @override
  String get memorySearch =>
      'การค้นหาด้วยคำและการค้นหาเชิงความหมายรวมกันด้วย Reciprocal Rank Fusion (RRF)';

  @override
  String get memoryPersonas =>
      'เพอร์โซนา: ตัวคุณเอง เสียงบอทของแชท และบุคคลที่คุณเอ่ยถึงในคำถาม';

  @override
  String get memoryRepo => 'ที่เก็บโค้ด Hippocampus';

  @override
  String get scopeDescription =>
      'แผนผังขอบเขตความจำ: เวิร์กสเปซมีแอป และแอปมีผู้ใช้';

  @override
  String get graphDescription =>
      'ตัวอย่างกราฟความจำ: ความจำเชื่อมกับแท็ก เอนทิตี และไฟล์';

  @override
  String get webTitle => 'การค้นคว้าเว็บ';

  @override
  String get webMode => 'โหมด';

  @override
  String get webQueries => 'คำค้น';

  @override
  String get webPages => 'หน้า';

  @override
  String get webDepth => 'ความลึกของลิงก์';

  @override
  String get webTime => 'เวลาจำกัด';

  @override
  String get webFast => 'เร็ว';

  @override
  String get webMedium => 'กลาง';

  @override
  String get webDeep => 'ลึก';

  @override
  String get webFastPages => '5';

  @override
  String get webMediumPages => '5 ต่อระดับ';

  @override
  String get webMethod =>
      'หน้าเว็บถูกตัดเป็นส่วนละประมาณ 500 โทเค็นและจัดอันดับด้วย BM25 และ RRF ข้อความเว็บไม่ใช้ embedding และแหล่งข้อมูลแยกจากความจำของคุณ';

  @override
  String seconds(int n) {
    return '$n วินาที';
  }

  @override
  String get liveTitle => 'ควบคุมแบบสด';

  @override
  String get liveSteps => 'ขั้นตอนสด: ทุกขั้นตอนถูกส่งขณะเกิดขึ้น';

  @override
  String get liveReconnect =>
      'เชื่อมต่อใหม่: คำตอบยังทำงานบนเซิร์ฟเวอร์ และคุณกลับมาดูได้';

  @override
  String get liveStop => 'หยุด: คุณหยุดคำตอบได้ทุกเมื่อ';

  @override
  String get liveStopThinking => 'หยุดคิด: ไปที่คำตอบสุดท้ายพร้อมบันทึกที่มี';

  @override
  String get engTitle => 'วิศวกรรม';

  @override
  String get engMachines =>
      'เครื่องในเครือข่ายเดียวกัน: GPU ของ MSI รันโมเดลภาษา Pong รัน embedding, FSM เก็บไฟล์ และเซิร์ฟเวอร์ฐานข้อมูลเก็บข้อมูล';

  @override
  String get engRust => 'API ของ Cortex และ Hippocampus เขียนด้วย Rust';

  @override
  String get engLocal => 'ใช้โมเดลในเครื่องเท่านั้น ไม่มีโมเดลภาษาบนคลาวด์';

  @override
  String get machinesDescription =>
      'แผนภาพเครื่อง: API ของ Cortex ส่งการเรียกโมเดลไปที่ GPU ของ MSI และการเรียกความจำไปที่ Hippocampus ซึ่งใช้ Pong สำหรับ embedding, FSM สำหรับไฟล์ และเซิร์ฟเวอร์ฐานข้อมูล';

  @override
  String get codeTitle => 'โค้ดจริง';

  @override
  String get codeRrf => 'Reciprocal Rank Fusion ของรายการค้นหาเว็บ';

  @override
  String get codeGather => 'รวบรวมไฟล์ ความจำ และเว็บพร้อมกัน';

  @override
  String get codeNames => 'ค้นหาแท็กภายในขอบเขตเดียว';

  @override
  String get researchTitle => 'พื้นฐานงานวิจัย';

  @override
  String get securityTitle => 'ความปลอดภัยและความเป็นส่วนตัว';

  @override
  String get securityShield =>
      'ทุกข้อความผ่านการตรวจความปลอดภัยด้วยกฎตายตัวและตัวจำแนกก่อนบันทึก';

  @override
  String get securityIsolation =>
      'ผู้ใช้แต่ละคนเห็นเฉพาะแชท ไฟล์ และความจำของตนในแต่ละแอป';

  @override
  String get securityLogs => 'บันทึกระบบและบันทึกการทำงานไม่มีข้อความแชท';

  @override
  String get faqLoginQ => 'ต้องมีบัญชีไหม';

  @override
  String get faqLoginA => 'ใช่ คุณเข้าสู่ระบบด้วยบัญชี Asodya ก่อนแชทครั้งแรก';

  @override
  String get faqModelQ => 'โมเดลใดเป็นผู้ตอบ';

  @override
  String get faqModelA =>
      'โมเดลข้อความในเครื่อง และโมเดลภาพในเครื่องเมื่อคุณส่งรูปภาพ';

  @override
  String get faqDataQ => 'ข้อมูลของฉันอยู่ที่ไหน';

  @override
  String get faqDataA =>
      'บนเครื่องของ Asodya: แชทในฐานข้อมูล ความจำใน Hippocampus และไฟล์ใน FSM';

  @override
  String get faqTempQ => 'แชทชั่วคราวคืออะไร';

  @override
  String get faqTempA =>
      'แชทที่ไม่ถูกบันทึก: สิ้นสุดหลังหนึ่งชั่วโมงหรือเมื่อคุณปิด และไม่สร้างความจำ';

  @override
  String get faqLangQ => 'รองรับภาษาใดบ้าง';

  @override
  String get faqLangA => 'แอปมีภาษาอังกฤษ โปรตุเกส และไทย';

  @override
  String get finalLine => 'ถามคำถามแรกของคุณ';

  @override
  String version(String v) {
    return 'เวอร์ชัน $v';
  }

  @override
  String get logoDescription => 'โลโก้ Cortex';

  @override
  String get chatGreeting => 'คุณอยากรู้อะไร';

  @override
  String get composerHint => 'พิมพ์ข้อความ';

  @override
  String get attach => 'แนบไฟล์';

  @override
  String get webLabel => 'เว็บ';

  @override
  String get webOff => 'ปิด';

  @override
  String get memoryToggle => 'ความจำ';

  @override
  String get topicHint => 'หัวข้อ (ไม่บังคับ)';

  @override
  String get thinkingToggle => 'การคิด';

  @override
  String get personaPicker => 'เพอร์โซนาของบอท';

  @override
  String get noPersona => 'ไม่มีเพอร์โซนา';

  @override
  String get send => 'ส่ง';

  @override
  String get stop => 'หยุด';

  @override
  String get stopThinking => 'หยุดคิด';

  @override
  String usuallyAbout(int n) {
    return 'ปกติประมาณ $n วินาที';
  }

  @override
  String elapsed(int n) {
    return '$n วินาที';
  }

  @override
  String get stagesTimeline => 'ขั้นตอน';

  @override
  String get thinkingSection => 'การคิด';

  @override
  String get rolePlan => 'วางแผน';

  @override
  String get roleWork => 'ทำงาน';

  @override
  String get roleCheck => 'ตรวจสอบ';

  @override
  String get roleNotes => 'บันทึก';

  @override
  String roundN(int n) {
    return 'รอบ $n';
  }

  @override
  String usedMemories(int n) {
    return 'ใช้ความจำ $n รายการ';
  }

  @override
  String get copy => 'คัดลอก';

  @override
  String get copied => 'คัดลอกแล้ว';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get jumpToLatest => 'ไปที่ล่าสุด';

  @override
  String get reconnecting => 'กำลังเชื่อมต่อใหม่...';

  @override
  String get rename => 'เปลี่ยนชื่อ';

  @override
  String get pin => 'ปักหมุด';

  @override
  String get unpin => 'เลิกปักหมุด';

  @override
  String get delete => 'ลบ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get save => 'บันทึก';

  @override
  String get deleteChatTitle => 'ลบแชทนี้ไหม';

  @override
  String get deleteChatMessage =>
      'แชทและความจำของแชทจะถูกลบ ไม่สามารถย้อนกลับได้';

  @override
  String tokenCounter(int n, int max) {
    return '$n จาก $max โทเค็น';
  }

  @override
  String get overLimit => 'ข้อความเกินขีดจำกัดอินพุต';

  @override
  String get uploading => 'กำลังอัปโหลด';

  @override
  String statsLine(String time, String s, int input, int output) {
    return '$time · $s วินาที · เข้า $input ออก $output โทเค็น';
  }

  @override
  String get cancelledLine => 'หยุดแล้ว';

  @override
  String get steps_web_queries => 'กำลังเตรียมคำค้น';

  @override
  String get steps_queue_wait => 'กำลังรอโมเดล';

  @override
  String get steps_model_load => 'กำลังโหลดโมเดล';

  @override
  String get steps_model_ready => 'โมเดลพร้อมแล้ว';

  @override
  String get steps_security_ok => 'ตรวจความปลอดภัยผ่าน';

  @override
  String get steps_file_read_page => 'กำลังอ่านหน้าไฟล์';

  @override
  String get steps_file_ocr_page => 'กำลังอ่านภาพของหน้า';

  @override
  String get steps_file_transcribe => 'กำลังถอดเสียง';

  @override
  String get steps_memory_search => 'กำลังค้นหาความจำของคุณ';

  @override
  String get steps_memory_found => 'พบความจำ';

  @override
  String get steps_web_search => 'กำลังค้นหาเว็บ';

  @override
  String get steps_web_page_read => 'กำลังอ่านหน้าเว็บ';

  @override
  String get steps_chunks_selected => 'เลือกส่วนข้อความแล้ว';

  @override
  String get steps_thinking_step => 'ขั้นตอนการคิด';

  @override
  String get steps_thinking_stopped => 'ผู้ใช้หยุดการคิด';

  @override
  String get temporaryBanner => 'ชั่วคราว: ไม่ถูกบันทึก และหายไปเมื่อรีเฟรช';

  @override
  String get justNow => 'เมื่อสักครู่';

  @override
  String minutesAgo(int n) {
    return '$n นาทีที่แล้ว';
  }

  @override
  String hoursAgo(int n) {
    return '$n ชั่วโมงที่แล้ว';
  }

  @override
  String daysAgo(int n) {
    return '$n วันที่แล้ว';
  }

  @override
  String get running => 'กำลังทำงาน';

  @override
  String get chatActions => 'การทำงานของแชท';

  @override
  String get deleteFailed => 'ยังไม่ได้ลบแชท';

  @override
  String get chatsLoadFailed => 'โหลดแชทไม่ได้';

  @override
  String get graphView => 'กราฟ';

  @override
  String get listView => 'รายการ';

  @override
  String get depthLabel => 'ความลึก';

  @override
  String get limitLabel => 'จำนวนสูงสุด';

  @override
  String get legendMemory => 'ความจำ';

  @override
  String get legendTag => 'แท็ก';

  @override
  String get legendEntity => 'เอนทิตี';

  @override
  String get legendFile => 'ไฟล์';

  @override
  String get noMemories => 'ยังไม่มีความจำ';

  @override
  String get memoryLoadFailed => 'โหลดความจำไม่ได้';

  @override
  String get memoryNotFound => 'ไม่พบความจำนี้';

  @override
  String get superseded => 'ถูกแทนที่';

  @override
  String get detailsLabel => 'รายละเอียด';

  @override
  String get linkedFiles => 'ไฟล์';

  @override
  String get linkedMemories => 'ความจำที่เชื่อมโยง';

  @override
  String get typeChat => 'แชท';

  @override
  String get typeFile => 'ไฟล์';

  @override
  String get typeNote => 'บันทึก';

  @override
  String get graphTruncated =>
      'แสดงกราฟเพียงบางส่วน เพิ่มจำนวนสูงสุดเพื่อดูเพิ่ม';

  @override
  String get memoryGraphDescription =>
      'กราฟความจำ มุมมองรายการแสดงโหนดเดียวกันเป็นข้อความ';

  @override
  String get legendPersona => 'เพอร์โซนา';

  @override
  String get linkedPersonas => 'เพอร์โซนาที่เชื่อมโยง';

  @override
  String get searchPersonas => 'ค้นหาเพอร์โซนา';

  @override
  String get allPersonaTypes => 'ทุกประเภท';

  @override
  String get personType => 'บุคคล';

  @override
  String get botType => 'บอต';

  @override
  String get you => 'คุณ';

  @override
  String get noPersonas => 'ยังไม่มีเพอร์โซนา';

  @override
  String get personasLoadFailed => 'โหลดเพอร์โซนาไม่ได้';

  @override
  String get personaFormFailed => 'โหลดแบบฟอร์มเพอร์โซนาไม่ได้';

  @override
  String get personaSaveFailed =>
      'บันทึกเพอร์โซนาไม่ได้ โปรดตรวจช่องที่ทำเครื่องหมายไว้';

  @override
  String get editPersona => 'แก้ไขเพอร์โซนา';

  @override
  String get personaType => 'ประเภท';

  @override
  String get personaName => 'ชื่อ';

  @override
  String get personaAliases => 'ชื่อเรียกอื่น';

  @override
  String get personaIsSelf => 'เพอร์โซนานี้คือคุณ';

  @override
  String get personaRequiredLegend => '* ช่องที่ต้องกรอก';

  @override
  String get personaSaved => 'บันทึกเพอร์โซนาแล้ว';

  @override
  String get deletePersona => 'ลบเพอร์โซนา';

  @override
  String get deletePersonaConfirm => 'ลบเพอร์โซนานี้และคุณลักษณะทั้งหมดหรือไม่';

  @override
  String get personaFieldRequired => 'ต้องกรอกช่องนี้';

  @override
  String get personaFieldUnknown => 'ช่องนี้ไม่อยู่ในสคีมาที่บันทึกไว้';

  @override
  String get personaFieldType => 'ใช้ชนิดข้อมูลที่แสดงสำหรับช่องนี้';

  @override
  String get personaFieldInvalid => 'โปรดตรวจช่องนี้';

  @override
  String get addPersonaItem => 'เพิ่มรายการ';

  @override
  String get removePersonaItem => 'ลบรายการ';

  @override
  String get choosePersonaDate => 'เลือกวันที่';

  @override
  String get clear => 'ล้าง';

  @override
  String get personaYes => 'ใช่';

  @override
  String get personaNo => 'ไม่ใช่';

  @override
  String get personaInteger => 'จำนวนเต็ม';

  @override
  String get personaNumber => 'ตัวเลข';

  @override
  String get personaActionFailed => 'ทำรายการไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get usageLoadFailed => 'โหลดข้อมูลการใช้งานไม่ได้';

  @override
  String get notAvailableYet => 'ยังไม่มีข้อมูล';

  @override
  String usageWindow(int hours) {
    return 'การใช้งานของคุณใน $hours ชั่วโมงที่ผ่านมา';
  }

  @override
  String get usageInputTokens => 'โทเคนขาเข้า';

  @override
  String get usageOutputTokens => 'โทเคนขาออก';

  @override
  String get usageTotalTokens => 'โทเคนทั้งหมด';

  @override
  String get usageImages => 'รูปภาพ';

  @override
  String get usageAudio => 'รายการเสียง';

  @override
  String get usagePriority => 'ลำดับความสำคัญของคุณ';

  @override
  String get usagePriorityHelp =>
      'การเรียกโมเดลครั้งถัดไปจะเป็นของผู้ใช้ที่รออยู่และมีการใช้โทเคนหารด้วยค่าน้ำหนักต่ำที่สุด การเรียกที่เริ่มแล้วจะทำงานจนเสร็จ';

  @override
  String get usageWeight => 'ค่าน้ำหนัก';

  @override
  String get usageAccountAge => 'ส่วนอายุบัญชี';

  @override
  String get usageFrequency => 'ส่วนความถี่ในการเข้าสู่ระบบ';

  @override
  String get usageAccountDays => 'อายุบัญชีเป็นวัน';

  @override
  String get usageSignInDays => 'วันที่เข้าสู่ระบบใน 90 วันที่ผ่านมา';

  @override
  String get usageWeightFormula =>
      'ค่าน้ำหนัก = 1 + ส่วนอายุบัญชี + ส่วนความถี่ในการเข้าสู่ระบบ';

  @override
  String usageKind(String mode, String thinking) {
    return '$mode, $thinking';
  }

  @override
  String get usageThinkingOn => 'เปิดการคิด';

  @override
  String get usageThinkingOff => 'ปิดการคิด';

  @override
  String usageSeconds(String value) {
    return '$value วินาที';
  }

  @override
  String get usageTimingHelp =>
      'ค่าเฉลี่ยของคำตอบที่เสร็จสมบูรณ์ 20 รายการล่าสุดในแต่ละประเภท ไม่รวมคำตอบที่ล้มเหลวหรือถูกยกเลิก';

  @override
  String get usageEmpty => 'ยังไม่มีบันทึกการใช้งาน';

  @override
  String get usageMetric => 'ตัวชี้วัด';

  @override
  String get usageRuns => 'คำตอบทั้งหมด';

  @override
  String get usageAverageTime => 'เวลาเฉลี่ย';

  @override
  String get usageAverageInput => 'โทเคนขาเข้าเฉลี่ย';

  @override
  String get usageAverageOutput => 'โทเคนขาออกเฉลี่ย';

  @override
  String get usageAverageTotal => 'โทเคนทั้งหมดเฉลี่ย';

  @override
  String get usageSuccessRate => 'อัตราความสำเร็จ';

  @override
  String get usageRequest => 'รหัสคำขอ';

  @override
  String get usageOutput => 'รหัสคำตอบ';

  @override
  String get usageUser => 'ผู้ใช้';

  @override
  String get usageModel => 'โมเดล';

  @override
  String get usageRole => 'หน้าที่';

  @override
  String get usageStarted => 'เริ่ม';

  @override
  String get usageFinished => 'เสร็จ';

  @override
  String get usageNoUser => 'ไม่มีผู้ใช้';

  @override
  String get loadMore => 'โหลดเพิ่ม';

  @override
  String get loading => 'กำลังโหลด';

  @override
  String get process1001 => 'ไม่พบเส้นทางนี้';

  @override
  String get process1002 => 'ไม่อนุญาตให้ใช้วิธีนี้';

  @override
  String get process1003 => 'ข้อมูลคำขอไม่ถูกต้อง';

  @override
  String get process1004 => 'เนื้อหา JSON ไม่ถูกต้อง';

  @override
  String get process1005 => 'เข้าสู่ระบบเพื่อดำเนินการต่อ';

  @override
  String get process1006 => 'ไม่รองรับประเภทเนื้อหานี้';

  @override
  String get process1007 => 'คำขอมีขนาดใหญ่เกินไป';

  @override
  String get process1008 => 'เซิร์ฟเวอร์ดำเนินการตามคำขอไม่สำเร็จ';

  @override
  String get process1009 => 'ไม่อนุญาตให้ใช้แอปนี้';

  @override
  String get process1010 => 'เซิร์ฟเวอร์มีภาระงานสูง โปรดลองภายหลัง';

  @override
  String get process1011 => 'คิวการเรียกโมเดลภายในล้มเหลว';

  @override
  String get process1012 => 'การเรียกโมเดลภายในล้มเหลว';

  @override
  String get process1201 => 'ข้อมูลขาเข้าเกินขีดจำกัดโทเคน';

  @override
  String get process1013 => 'ไม่มีข้อมูลการใช้งาน';

  @override
  String get process1014 => 'ล้อเล่นกันหรือไง เจ้าตัวตลก?';

  @override
  String get process1015 => 'การตรวจสอบความปลอดภัยไม่พร้อมใช้งาน';

  @override
  String get process1016 => 'ไม่พบแชต';

  @override
  String get process1017 => 'โหลดหรือแก้ไขประวัติแชตไม่ได้';

  @override
  String get process1018 => 'ไม่พบคำตอบ';

  @override
  String get process1019 => 'บันทึกความจำของแชตไม่ได้';

  @override
  String get process1020 => 'การค้นหาเว็บไม่พร้อมใช้งาน';

  @override
  String get process1021 => 'หมดเวลารอหน้าเว็บ';

  @override
  String get process1022 => 'หน้าเว็บมีขนาดเกินขีดจำกัด';

  @override
  String get process1023 => 'หน้าเว็บไม่ใช่ HTML';

  @override
  String get process1024 => 'อ่านหน้าเว็บไม่ได้';

  @override
  String get process1025 => 'หน้าเว็บไม่มีข้อความหลักที่อ่านได้';

  @override
  String get process1026 => 'ถึงขีดจำกัดเวลาค้นหาเว็บแล้ว';

  @override
  String get process1027 => 'ถึงขีดจำกัดจำนวนหน้าเว็บแล้ว';

  @override
  String get process1028 => 'โหลดกฎการรวบรวมข้อมูลเว็บไม่ได้';

  @override
  String get process1029 => 'โหลดความจำไม่ได้';

  @override
  String get process1030 => 'ไม่รองรับประเภทไฟล์นี้';

  @override
  String get process1031 => 'ไฟล์มีขนาดเกินขีดจำกัด';

  @override
  String get process1032 => 'อ่านข้อความในไฟล์ไม่ได้';

  @override
  String get process1033 => 'ไฟล์มีจำนวนหน้าเกินขีดจำกัด OCR';

  @override
  String get process1034 => 'อ่านข้อความในรูปภาพไม่ได้';

  @override
  String get process1035 => 'พื้นที่จัดเก็บแชตชั่วคราวไม่พร้อมใช้งาน';

  @override
  String get process1036 => 'ถึงขีดจำกัดเวลาคิดแล้ว';

  @override
  String get process1037 => 'สตรีมบันทึกพร้อมใช้งานเฉพาะในเครือข่ายภายใน';

  @override
  String get process1038 => 'โหลดข้อมูลการวัดผลไม่ได้';

  @override
  String get process1039 => 'ไม่พบโหนดความจำ';

  @override
  String get process1040 => 'ไม่ได้บันทึกไฟล์';

  @override
  String get process1041 => 'ไม่พบไฟล์';

  @override
  String get process1042 => 'เหตุการณ์ของคำตอบไม่พร้อมใช้งาน';

  @override
  String get process1043 => 'คำตอบไม่ได้กำลังทำงาน';

  @override
  String get process1044 => 'ลบความจำของแชตไม่ได้';

  @override
  String get process1045 => 'ไม่พบเพอร์โซนา';

  @override
  String get process1046 => 'ข้อมูลเพอร์โซนาไม่ถูกต้อง';

  @override
  String get process1047 => 'โหลดหรือแก้ไขเพอร์โซนาไม่ได้';

  @override
  String get process1048 => 'เสียงมีความยาวเกินขีดจำกัด 10 นาที';

  @override
  String get process1049 => 'ถอดเสียงไม่ได้';

  @override
  String get process1050 => 'กระบวนการจัดการไฟล์ไม่ตอบสนอง';

  @override
  String processUnknown(int number) {
    return 'เกิดปัญหา ($number)';
  }

  @override
  String get processGeneric => 'เกิดปัญหา โปรดลองอีกครั้ง';

  @override
  String get networkOffline =>
      'คุณออฟไลน์อยู่ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get stepUnknown => 'กำลังทำงาน';

  @override
  String get statusStarted => 'เริ่มแล้ว';

  @override
  String get statusDone => 'เสร็จแล้ว';

  @override
  String get statusFailed => 'ล้มเหลว';

  @override
  String get statusCancelled => 'ยกเลิกแล้ว';

  @override
  String get statusSkipped => 'ข้ามแล้ว';

  @override
  String get expandThinking => 'ขยายการคิด';

  @override
  String get collapseThinking => 'ย่อการคิด';

  @override
  String get noPersonaMatches => 'ไม่พบเพอร์โซนาที่ตรงกับตัวกรองเหล่านี้';

  @override
  String get account => 'บัญชี';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get appearance => 'รูปแบบการแสดงผล';

  @override
  String get systemChoice => 'ระบบ';

  @override
  String get lightChoice => 'สว่าง';

  @override
  String get darkChoice => 'มืด';

  @override
  String get browserPreferenceNote =>
      'ตัวเลือกเหล่านี้จะถูกบันทึกในเบราว์เซอร์นี้';

  @override
  String get collapseSidebar => 'ย่อแถบด้านข้าง';

  @override
  String get expandSidebar => 'ขยายแถบด้านข้าง';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortugueseBrazil => 'Português (Brasil)';

  @override
  String get languageThai => 'ไทย';
}
