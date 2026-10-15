# 📘 NEXORA-WINDOWS v20.0 APEX OMNI-MASTER & Local Web Dashboard

منظومة الهندسة الشاملة لنظام الويندوز (**Windows 10 / 11 / Server**)، تتضمن:

1. **التقييم التقني الصارم (بلا رحمة أو مجاملة) لنسخة `NEXORA-WINDOWS v16.0`:**
   - موجود في: `docs/NEXORA_v16_RUTHLESS_EVALUATION_AR.md` (الدرجة المستحقة: **81/100** مع تفصيل الثغرات الـ 7 القاتلة وكيف تم علاجها).
2. **المخطط المعماري العملاق وخارطة الطريق (7 مراحل):**
   - موجود في: `docs/NEXORA_MEGA_ARCHITECTURE_AND_ROADMAP_AR.md`.
3. **البرومبت النهائي المستحق 100/100 بلا منازع (`NEXORA-WINDOWS v20.0 APEX OMNI-MASTER`):**
   - موجود في: `prompts/NEXORA-WINDOWS-v20_0-APEX-MASTER.txt` (يعمل بذكاء مزدوج سواء أرفقت له ملف `دليل_الجهاز_الكامل.md` أو استخدمته بدون الدليل).
4. **أداة الويندوز والداشبورد الاحترافية وأيقونة «دليل الجهاز الكامل»:**
   - `windows-agent/Generate-Complete-Device-Guide.ps1`: جامع الطبقات الـ 16 القارئ فقط (`100% Read-Only & Fault-Isolated`) الذي يخرج ملف `Complete_Device_Guide_<Hostname>_<Date>.md` على سطح المكتب أو أي مسار تحدده.
   - `windows-agent/Generate-Complete-Device-Guide-Now.bat`: أيقونة الضغطة الواحدة على سطح المكتب لتوليد الدليل فوراً.
   - `windows-agent/Start-Nexora-Dashboard.bat` + `Start-Local-WebServer.ps1` + `server.js`: لتشغيل الداشبورد التفاعلية في المتصفح على المنفذ `http://localhost:7788`.

## طريقة التشغيل السريع على الويندوز
- **لاستخراج دليل الجهاز الكامل (`Complete_Device_Guide.md`) فوراً على سطح المكتب بضغطة واحدة:**
  شغّل الملف `windows-agent/Generate-Complete-Device-Guide-Now.bat`.
- **لتشغيل الداشبورد الاحترافية في المتصفح:**
  شغّل الملف `windows-agent/Start-Nexora-Dashboard.bat` (أو `node server.js`).
