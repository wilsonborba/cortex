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
  String get stageAccept => 'รับ';

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
  String get builtBy => 'สร้างโดย Wilson Borba';

  @override
  String version(String v) {
    return 'เวอร์ชัน $v';
  }

  @override
  String get logoDescription => 'โลโก้ Cortex';
}
