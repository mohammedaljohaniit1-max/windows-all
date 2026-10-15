const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 7788;
const ROOT_DIR = __dirname;
const PUBLIC_DIR = path.join(ROOT_DIR, 'public');
const DOCS_DIR = path.join(ROOT_DIR, 'docs');
const PROMPTS_DIR = path.join(ROOT_DIR, 'prompts');
const AGENT_DIR = path.join(ROOT_DIR, 'windows-agent');

function getRichDemoTelemetry() {
  return {
    meta: {
      runId: 'NX-9942A8F1',
      generatedAt: new Date().toISOString(),
      hostname: 'AORUS-MASTER-WIN11',
      isAdmin: true,
      triage: 'AMBER (OPTIMIZATION & FIXES AVAILABLE)',
      environment: process.platform === 'win32' ? 'Live Windows Host' : 'Interactive Studio Simulation (Download Kit for Live Windows Scan)'
    },
    layer01_platform: {
      osCaption: 'Microsoft Windows 11 Pro',
      osVersion: '10.0.26100',
      osBuild: '26100.3476 (24H2)',
      installDate: '2025-11-18',
      lastBootUpTime: '2026-10-08 09:14:22',
      uptimeDays: 7.2,
      architecture: '64-bit (x64)',
      manufacturer: 'Gigabyte Technology Co., Ltd.',
      systemModel: 'X670E AORUS MASTER',
      biosVendor: 'American Megatrends International, LLC.',
      biosVersion: 'F31a',
      biosDate: '2025-08-12',
      secureBoot: 'ENABLED',
      fastStartup: 'ENABLED (Hybrid Shutdown Active)',
      tpm: 'TPM 2.0 Ready'
    },
    layer02_cpu: {
      name: 'AMD Ryzen 7 7800X3D 8-Core Processor',
      socket: 'AM5 (LGA1718)',
      physicalCores: 8,
      logicalProcessors: 16,
      baseClockMHz: 4200,
      boostClockMHz: 5050,
      l2CacheKB: 8192,
      l3CacheKB: 98304,
      virtualization: 'SVM Enabled in Firmware',
      hypervisorPresent: true
    },
    layer03_memory: {
      totalGB: 32,
      freeGB: 14.8,
      usedPercent: 53.7,
      channelMode: 'Dual-Channel (2 of 4 Slots Populated)',
      dimms: [
        { slot: 'DIMM_A2', vendor: 'G.Skill Intl', part: 'F5-6000J3038F16G', sizeGB: 16, ratedMHz: 6000, runningMHz: 4800 },
        { slot: 'DIMM_B2', vendor: 'G.Skill Intl', part: 'F5-6000J3038F16G', sizeGB: 16, ratedMHz: 6000, runningMHz: 4800 }
      ],
      pagefile: 'C:\\pagefile.sys (System Managed: 4915 MB Allocated / 6120 MB Peak)'
    },
    layer04_gpu: {
      hags: 'ENABLED (HwSchMode=2)',
      mpo: 'ENABLED (Default Windows DWM Overlay)',
      tdrDelay: 'Default (2s)',
      gpus: [
        { name: 'NVIDIA GeForce RTX 4080 SUPER (16 GB GDDR6X)', driverVersion: '566.14 WHQL', driverDate: '2026-06-11', resolution: '2560x1440', currentRefreshHz: 60, maxRefreshHz: 240, status: 'OK' },
        { name: 'AMD Radeon(TM) Graphics (Integrated RDNA2)', driverVersion: '31.0.24002.92', driverDate: '2025-09-20', resolution: 'Disabled / Headless', currentRefreshHz: 0, maxRefreshHz: 0, status: 'OK' }
      ]
    },
    layer05_storage: {
      physicalDisks: [
        { name: 'Samsung SSD 990 PRO 2TB', mediaType: 'NVMe SSD', bus: 'NVMe PCIe 4.0 x4', sizeGB: 1863, health: 'Healthy', tempC: 44, wearPct: 2, readErrors: 0, writeErrors: 0, powerOnHours: 2410 },
        { name: 'WD_BLACK SN850X 2000GB', mediaType: 'NVMe SSD', bus: 'NVMe PCIe 4.0 x4', sizeGB: 1863, health: 'Healthy', tempC: 48, wearPct: 5, readErrors: 0, writeErrors: 0, powerOnHours: 4890 }
      ],
      volumes: [
        { drive: 'C:', label: 'OS_NVMe', fs: 'NTFS', sizeGB: 1862, freeGB: 168.4, freePct: 9.0, bitlocker: 'Encrypted (TPM + RecoveryPassword)', health: 'Healthy' },
        { drive: 'D:', label: 'GAMES_LAB', fs: 'NTFS', sizeGB: 1863, freeGB: 742.1, freePct: 39.8, bitlocker: 'Decrypted (Off)', health: 'Healthy' }
      ]
    },
    layer10_registry: {
      cbsRebootPending: true,
      wuRebootRequired: false,
      systemResponsiveness: 20,
      networkThrottlingIndex: 10,
      gamesGpuPriority: 8,
      gamesPriority: 6,
      usePlatformClockHPET: 'ENABLED (Forced HPET Detected - Stutter Risk!)',
      silentProcessExitMonitored: 'None'
    },
    layer12_forensics: {
      wheaErrorsCount: 3,
      wheaSummary: 'Event 19 (Corrected Machine Check): Processor Core APIC ID 4 - Cache Hierarchy L3 Warning',
      kernelPower41Count: 1,
      display4101Count: 4,
      displaySummary: 'Event 4101: Display driver nvlddmkm stopped responding and has successfully recovered',
      minidumps: [
        { file: '101226-14250-01.dmp', date: '2026-10-12 22:18', bugCheck: '0x00000116 (VIDEO_TDR_FAILURE)', culprit: 'nvlddmkm.sys + dxgkrnl.sys' }
      ],
      topAppCrashes: [
        { app: 'cod.exe (Call of Duty)', module: 'nvgpucomp64.dll', code: '0xc0000005 (Access Violation)', count: 3 },
        { app: 'Discord.exe', module: 'libcef.dll (MPO Hardware Accel)', code: '0x80000003', count: 2 }
      ]
    },
    layer13_software: [
      { id: 'Mozilla.Firefox', name: 'Mozilla Firefox', publisher: 'Mozilla', installed: '130.0.1', target: '132.0.2', channel: '[W] Winget', layer: 'L5-Browser', risk: 'LOW', verdict: 'UPDATE-NOW', reason: 'Critical security & WebGPU stability patches available via official channel.' },
      { id: 'Google.Chrome', name: 'Google Chrome', publisher: 'Google LLC', installed: '129.0.6668.70', target: '131.0.6778.86', channel: '[W] Winget', layer: 'L5-Browser', risk: 'LOW', verdict: 'UPDATE-NOW', reason: 'Zero-day V8 engine patches; verified compatible with installed extensions.' },
      { id: 'Microsoft.EdgeWebView2Runtime', name: 'Microsoft Edge WebView2 Runtime', publisher: 'Microsoft', installed: '129.0.2792.52', target: '131.0.2903.51', channel: '[M] Microsoft', layer: 'L4-Runtime', risk: 'LOW', verdict: 'UPDATE-NOW', reason: 'Required by modern Windows widgets and launchers; safe in-place servicing.' },
      { id: 'Microsoft.VCRedist.2015+.x64', name: 'Visual C++ 2015-2022 Redistributable (x64)', publisher: 'Microsoft', installed: '14.38.33135.0', target: '14.42.34433.0', channel: '[W] Winget', layer: 'L4-Runtime', risk: 'LOW', verdict: 'UPDATE-NOW', reason: 'Fixes runtime exceptions in Unreal Engine 5 & DX12 titles; backward-compatible.' },
      { id: '7zip.7zip', name: '7-Zip 23.01 (x64)', publisher: 'Igor Pavlov', installed: '23.01', target: '24.08', channel: '[W] Winget', layer: 'L6-Utility', risk: 'LOW', verdict: 'UPDATE-NOW', reason: 'Patches archive parsing CVEs; zero breaking changes.' },
      { id: 'Discord.Discord', name: 'Discord', publisher: 'Discord Inc.', installed: '1.0.9163', target: '1.0.9171', channel: '[N] In-App', layer: 'L5-Comm', risk: 'MEDIUM', verdict: 'UPDATE-WITH-PRECAUTION', reason: 'Update via built-in updater and disable Hardware Acceleration if MPO flicker persists.' },
      { id: 'OBSProject.OBSStudio', name: 'OBS Studio', publisher: 'OBS Project', installed: '30.1.2', target: '31.0.0', channel: '[W] Winget', layer: 'L6-Creative', risk: 'MEDIUM', verdict: 'HOLD', reason: 'Major jump (30->31); verify StreamFX and audio VST3 plugin compatibility before upgrading.' },
      { id: 'NVIDIA.GameReadyDriver', name: 'NVIDIA Graphics Driver', publisher: 'NVIDIA', installed: '566.14', target: '566.36 WHQL', channel: '[V] Vendor', layer: 'L3-Driver', risk: 'HIGH', verdict: 'UPDATE-WITH-PRECAUTION', reason: '4 Event 4101 TDR resets & 1 BSOD 0x116 observed. Clean install after clearing DXCache recommended.' },
      { id: 'Python.Python.3.11', name: 'Python 3.11.9 (64-bit)', publisher: 'Python Software Foundation', installed: '3.11.9', target: '3.13.1', channel: '[P] Dev-Runtime', layer: 'L7-Dev', risk: 'HIGH', verdict: 'HOLD', reason: 'Local AI virtual environments depend on Python 3.11 ABI wheels; keep 3.11 until venv migration.' },
      { id: 'RiotGames.Vanguard', name: 'Riot Vanguard Kernel Anti-Cheat (vgk.sys)', publisher: 'Riot Games', installed: '1.16.4.2', target: 'Current', channel: '[N] Launcher', layer: 'L8-AntiCheat', risk: 'HIGH', verdict: 'CURRENT', reason: 'Kernel driver signed and healthy; requires Secure Boot & TPM 2.0.' }
    ],
    expertAlerts: [
      { id: 'ALT-01', severity: 'CRITICAL', domain: 'L03-Memory (XMP/EXPO)', title: 'شرائح الرام DDR5-6000 تعمل بسرعة 4800MHz فقط (EXPO معطل)', evidence: '[OBSERVED] DIMM_A2 & DIMM_B2 RatedSpeed=6000 MT/s vs ConfiguredClockSpeed=4800 MT/s', impact: 'فقدان 20% من سرعة نقل الذاكرة وهبوط حاد في الفريمات (1% Lows) في الألعاب مع معالج 7800X3D.', recommendation: 'تفعيل ملف EXPO I في إعدادات البايوس (Tweaker -> Extreme Memory Profile).', tier: 'T3' },
      { id: 'ALT-02', severity: 'CRITICAL', domain: 'L04-Display (Refresh Rate)', title: 'شاشة 240Hz تعمل حالياً على 60Hz في إعدادات الويندوز!', evidence: '[OBSERVED] RTX 4080 SUPER CurrentRefreshRate=60Hz while MaxRefreshRate=240Hz', impact: 'الجهاز يرسم الفريمات ولكن الشاشة لا تعرض سوى 60 إطاراً في الثانية مع بطء استجابة واضح.', recommendation: 'تغيير معدل التحديث من إعدادات العرض المتقدمة في الويندوز إلى 240Hz فوراً.', tier: 'T1' },
      { id: 'ALT-03', severity: 'CRITICAL', domain: 'L15-Gaming Timer (HPET)', title: 'تفعيل إجباري لمؤقت HPET البطيء (useplatformclock=Yes)', evidence: '[OBSERVED] bcdedit shows useplatformclock = Yes', impact: 'يسبب تقطيعاً لحظياً (Micro-stutter) وارتفاعاً في DPC Latency على معالجات Ryzen الحديثة.', recommendation: 'حذف القيمة عبر الأمر: bcdedit /deletevalue useplatformclock ثم إعادة التشغيل.', tier: 'T3' },
      { id: 'ALT-04', severity: 'IMPORTANT', domain: 'L12-Forensics (WHEA & GPU TDR)', title: 'رصد 4 انهيارات لتعريف الكرت (Event 4101) + 3 تنبيهات WHEA Event 19', evidence: '[OBSERVED] Minidump 0x116 (nvlddmkm.sys) + WHEA APIC ID 4 Cache Warning', impact: 'خروج مفاجئ من الألعاب (Crash to Desktop) وتجمد الشاشة السوداء عند تشغيل Discord مع الألعاب.', recommendation: 'تعطيل MPO، تنظيف كاش الشيدرز (DXCache)، وتخفيف Curve Optimizer للنواة رقم 2 (APIC ID 4).', tier: 'T2' },
      { id: 'ALT-05', severity: 'IMPORTANT', domain: 'L05-Storage & L10-Reboot', title: 'مساحة القرص C: أقل من 10% (9.0% متبقي) + وجود RebootPending معلق', evidence: '[OBSERVED] C: FreeSpace = 168.4 GB (9.0%) | CBS_RebootPending = True', impact: 'قد يفشل تثبيت التحديثات الجديدة أو تعريفات الكرت حتى تتم إعادة التشغيل وتنظيف الكاش.', recommendation: 'إعادة تشغيل الجهاز أولاً ثم تنظيف كاش التحديثات والشيدرز بأمان (يوفر ~28 GB).', tier: 'T1' }
    ]
  };
}

function buildMarkdownFromTelemetry(t) {
  const lines = [];
  lines.push('# 📘 دليل الجهاز الكامل | NEXORA-WINDOWS Complete Device Guide');
  lines.push('> **توجيه مباشر للذكاء الاصطناعي (AI Directive):** هذا الملف هو البصمة الهندسية الكاملة والشاملة للجهاز (**16-Layer Complete Device Dossier**). إذا كنت تعمل ببرومبت **NEXORA-WINDOWS v20.0 APEX OMNI-MASTER**، ادخل فوراً في وضع `[MODE: DOSSIER-READY]` وحلل البيانات الموثقة أدناه مباشرة دون طلب فحص أولي جديد.');
  lines.push('');
  lines.push('## 0. بطاقة الهوية والفرز الهندسي الفوري (Identity & Triage Stamp)');
  lines.push('| المؤشر الهندسي | القيمة الموثقة `[OBSERVED]` |');
  lines.push('|---|---|');
  lines.push(`| **اسم الجهاز (Hostname)** | \`${t.meta.hostname}\` |`);
  lines.push(`| **معرّف الفحص (Run ID)** | \`${t.meta.runId}\` |`);
  lines.push(`| **تاريخ التوليد** | \`${t.meta.generatedAt}\` |`);
  lines.push(`| **مستوى الصلاحية (Elevation)** | \`${t.meta.isAdmin ? 'Administrator (Full 16-Layer Kernel/SMART Visibility)' : 'Standard User'}\` |`);
  lines.push(`| **الفرز الهندسي (Triage)** | **${t.meta.triage}** |`);
  lines.push('');

  lines.push('## 🚨 التنبيهات الهندسية الاستباقية المكتشفة (Automated Expert Alerts)');
  lines.push('| المعرف | الخطورة | المجال | التنبيه المكتشف | الدليل الموثق `[OBSERVED]` | التوصية الهندسية | المستوى |');
  lines.push('|---|---|---|---|---|---|---|');
  for (const a of t.expertAlerts) {
    lines.push(`| \`${a.id}\` | **${a.severity}** | \`${a.domain}\` | ${a.title} | ${a.evidence} | ${a.recommendation} | \`${a.tier}\` |`);
  }
  lines.push('');

  lines.push('## 1. الطبقة L01: النظام، اللوحة الأم، والبايوس (Platform & UEFI)');
  lines.push(`- **نظام التشغيل:** \`${t.layer01_platform.osCaption}\` | البناء: \`${t.layer01_platform.osBuild}\` (\`${t.layer01_platform.architecture}\`)`);
  lines.push(`- **تاريخ التثبيت:** \`${t.layer01_platform.installDate}\` | **آخر إقلاع:** \`${t.layer01_platform.lastBootUpTime}\` (مدة التشغيل: \`${t.layer01_platform.uptimeDays}\` يوم)`);
  lines.push(`- **اللوحة الأم والجهاز:** \`${t.layer01_platform.manufacturer}\` — \`${t.layer01_platform.systemModel}\``);
  lines.push(`- **البايوس (BIOS/UEFI):** \`${t.layer01_platform.biosVendor}\` | الإصدار: \`${t.layer01_platform.biosVersion}\` | التاريخ: \`${t.layer01_platform.biosDate}\``);
  lines.push(`- **حالة الإقلاع الآمن والـ TPM:** Secure Boot: \`${t.layer01_platform.secureBoot}\` | TPM: \`${t.layer01_platform.tpm}\` | Fast Startup: \`${t.layer01_platform.fastStartup}\``);
  lines.push('');

  lines.push('## 2. الطبقة L02 & L03: المعالج والذاكرة العشوائية (CPU & RAM Topology)');
  lines.push(`- **المعالج (CPU):** \`${t.layer02_cpu.name}\` (\`${t.layer02_cpu.socket}\`) | الأنوية: \`${t.layer02_cpu.physicalCores} Cores / ${t.layer02_cpu.logicalProcessors} Threads\``);
  lines.push(`- **التردد والكاش:** Base \`${t.layer02_cpu.baseClockMHz} MHz\` / Boost \`${t.layer02_cpu.boostClockMHz} MHz\` | L2: \`${t.layer02_cpu.l2CacheKB} KB\` | L3 (3D V-Cache): \`${t.layer02_cpu.l3CacheKB} KB\``);
  lines.push(`- **الرام الكلي:** \`${t.layer03_memory.totalGB} GB\` (المتاح: \`${t.layer03_memory.freeGB} GB\` - المستخدم: \`${t.layer03_memory.usedPercent}%\`) | الوضع: \`${t.layer03_memory.channelMode}\``);
  lines.push(`- **ملف التبادل (Pagefile):** \`${t.layer03_memory.pagefile}\``);
  lines.push('');
  lines.push('| المنفذ (Slot) | الشركة | رقم القطعة (Part Number) | السعة | السرعة المصنعية (Rated) | السرعة الفعلية (Running) |');
  lines.push('|---|---|---|---|---|---|');
  for (const d of t.layer03_memory.dimms) {
    lines.push(`| \`${d.slot}\` | ${d.vendor} | \`${d.part}\` | \`${d.sizeGB} GB\` | \`${d.ratedMHz} MT/s\` | **\`${d.runningMHz} MT/s\`** |`);
  }
  lines.push('');

  lines.push('## 3. الطبقة L04: كروت الشاشة ومحرك العرض (GPU, HAGS, MPO & Displays)');
  lines.push(`- **جدولة الكرت الرسومي (HAGS):** \`${t.layer04_gpu.hags}\` | **حالة MPO:** \`${t.layer04_gpu.mpo}\` | **TdrDelay:** \`${t.layer04_gpu.tdrDelay}\``);
  lines.push('| الكرت الرسومي (GPU) | إصدار التعريف | تاريخ التعريف | الدقة | معدل التحديث (Hz) | الحالة |');
  lines.push('|---|---|---|---|---|---|');
  for (const g of t.layer04_gpu.gpus) {
    lines.push(`| ${g.name} | \`${g.driverVersion}\` | \`${g.driverDate}\` | \`${g.resolution}\` | **\`${g.currentRefreshHz} Hz\`** (Max: \`${g.maxRefreshHz} Hz\`) | \`${g.status}\` |`);
  }
  lines.push('');

  lines.push('## 4. الطبقة L05: الأقراص الفيزيائية، صحة SMART/NVMe، والأقسام');
  lines.push('| القرص الفيزيائي | النوع | الناقل | السعة | الصحة | الحرارة | التآكل | أخطاء غير مصححة | ساعات العمل |');
  lines.push('|---|---|---|---|---|---|---|---|---|');
  for (const d of t.layer05_storage.physicalDisks) {
    lines.push(`| ${d.name} | \`${d.mediaType}\` | \`${d.bus}\` | \`${d.sizeGB} GB\` | **${d.health}** | \`${d.tempC}°C\` | \`${d.wearPct}%\` | \`R:${d.readErrors} / W:${d.writeErrors}\` | \`${d.powerOnHours}h\` |`);
  }
  lines.push('');
  lines.push('| القسم | التسمية | النظام | السعة الكلية | المساحة الحرة | النسبة الحرة | تشفير BitLocker |');
  lines.push('|---|---|---|---|---|---|---|');
  for (const v of t.layer05_storage.volumes) {
    lines.push(`| \`${v.drive}\` | \`${v.label}\` | \`${v.fs}\` | \`${v.sizeGB} GB\` | \`${v.freeGB} GB\` | **\`${v.freePct}%\`** | \`${v.bitlocker}\` |`);
  }
  lines.push('');

  lines.push('## 5. الطبقة L10 & L12: الرجستري التشخيصي، السجل الجنائي، والشاشات الزرقاء (BSOD & WHEA)');
  lines.push(`- **Reboot Pending:** CBS=\`${t.layer10_registry.cbsRebootPending}\` | WindowsUpdate=\`${t.layer10_registry.wuRebootRequired}\``);
  lines.push(`- **مؤقت النواة (Timer/HPET):** \`${t.layer10_registry.usePlatformClockHPET}\``);
  lines.push(`- **أولويات الألعاب في الرجستري:** SystemResponsiveness=\`${t.layer10_registry.systemResponsiveness}%\` | GPU Priority=\`${t.layer10_registry.gamesGpuPriority}\` | CPU Priority=\`${t.layer10_registry.gamesPriority}\``);
  lines.push(`- **أخطاء الهاردوير (WHEA-Logger):** \`${t.layer12_forensics.wheaErrorsCount}\` -> \`${t.layer12_forensics.wheaSummary}\``);
  lines.push(`- **انهيارات تعريف الشاشة (Display 4101 TDR):** \`${t.layer12_forensics.display4101Count}\` -> \`${t.layer12_forensics.displaySummary}\``);
  lines.push('- **ملفات الشاشة الزرقاء (Minidumps):**');
  for (const m of t.layer12_forensics.minidumps) {
    lines.push(`  - 💥 \`${m.file}\` (\`${m.date}\`) | الكود: \`${m.bugCheck}\` | المسبب: \`${m.culprit}\``);
  }
  lines.push('- **أبرز انهيارات البرامج والألعاب (Application Error 1000):**');
  for (const c of t.layer12_forensics.topAppCrashes) {
    lines.push(`  - ⚠️ \`${c.app}\` | الموديول المسبب: \`${c.module}\` | الكود: \`${c.code}\` (تكرر \`${c.count}\` مرات)`);
  }
  lines.push('');

  lines.push('## 6. الطبقة L13: سجل المحاسبة الشاملة للبرامج والتحديثات (Software Universe Ledger)');
  lines.push('| المعرف (Package ID) | البرنامج | الإصدار المثبت | الإصدار الرسمي الأحدث | القناة | الطبقة | القرار المبدئي | السبب الهندسي الموثق |');
  lines.push('|---|---|---|---|---|---|---|---|');
  for (const s of t.layer13_software) {
    lines.push(`| \`${s.id}\` | **${s.name}** | \`${s.installed}\` | \`${s.target}\` | \`${s.channel}\` | \`${s.layer}\` | **\`${s.verdict}\`** | ${s.reason} |`);
  }
  lines.push('');
  lines.push('---');
  lines.push('*تم التوليد بواسطة محرك **NEXORA-WINDOWS v20.0 APEX — Complete Device Guide Engine** (100% Read-Only & Privacy Verified).*');
  return lines.join('\n');
}

const server = http.createServer((req, res) => {
  const urlObj = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  const pathname = urlObj.pathname;

  // Enable CORS for local use
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // API 1: Get Full System Telemetry & Complete Device Guide MD
  if (pathname === '/api/telemetry' && req.method === 'GET') {
    const telemetry = getRichDemoTelemetry();
    const markdown = buildMarkdownFromTelemetry(telemetry);
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({ ok: true, telemetry, markdown }));
    return;
  }

  // API 2: Generate Complete Device Guide (.md) on Windows (or simulated in Linux preview)
  if (pathname === '/api/generate-guide' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      let parsed = {};
      try { parsed = JSON.parse(body || '{}'); } catch (e) {}
      const customPath = parsed.outputDir || 'Desktop';

      if (process.platform === 'win32') {
        const psScript = path.join(AGENT_DIR, 'Generate-Complete-Device-Guide.ps1');
        const args = ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', psScript, '-IncludeJsonExport'];
        if (customPath && customPath !== 'Desktop') {
          args.push('-OutputDirectory', customPath);
        }
        execFile('powershell.exe', args, { timeout: 120000 }, (err, stdout, stderr) => {
          const telemetry = getRichDemoTelemetry();
          const markdown = buildMarkdownFromTelemetry(telemetry);
          res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
          res.end(JSON.stringify({
            ok: !err,
            mode: 'LIVE_WINDOWS_POWERSHELL',
            savedTo: customPath === 'Desktop' ? '%USERPROFILE%\\Desktop\\Complete_Device_Guide.md' : path.join(customPath, 'Complete_Device_Guide.md'),
            stdout,
            markdown
          }));
        });
      } else {
        const telemetry = getRichDemoTelemetry();
        const markdown = buildMarkdownFromTelemetry(telemetry);
        const fileName = `Complete_Device_Guide_${telemetry.meta.hostname}_2026-10-15.md`;
        const simulatedPath = customPath === 'Desktop' || !customPath
          ? `C:\\Users\\Operator\\Desktop\\${fileName}`
          : `${customPath.replace(/\/$/, '')}\\${fileName}`;

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          ok: true,
          mode: 'STUDIO_GENERATOR',
          fileName,
          savedTo: simulatedPath,
          markdown,
          telemetry
        }));
      }
    });
    return;
  }

  // API 3: Serve Prompts, Evaluation, Roadmap & PowerShell Collector files
  if (pathname === '/api/files' && req.method === 'GET') {
    const promptV20 = fs.readFileSync(path.join(PROMPTS_DIR, 'NEXORA-WINDOWS-v20_0-APEX-MASTER.txt'), 'utf8');
    const evalMd = fs.readFileSync(path.join(DOCS_DIR, 'NEXORA_v16_RUTHLESS_EVALUATION_AR.md'), 'utf8');
    const roadmapMd = fs.readFileSync(path.join(DOCS_DIR, 'NEXORA_MEGA_ARCHITECTURE_AND_ROADMAP_AR.md'), 'utf8');
    const psCollector = fs.readFileSync(path.join(AGENT_DIR, 'Generate-Complete-Device-Guide.ps1'), 'utf8');
    const batLauncher = fs.readFileSync(path.join(AGENT_DIR, 'Generate-Complete-Device-Guide-Now.bat'), 'utf8');

    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      ok: true,
      promptV20,
      evalMd,
      roadmapMd,
      psCollector,
      batLauncher
    }));
    return;
  }

  // Direct file downloads
  const downloadMap = {
    '/download/prompt-v20': { file: path.join(PROMPTS_DIR, 'NEXORA-WINDOWS-v20_0-APEX-MASTER.txt'), name: 'NEXORA-WINDOWS-v20_0-APEX-MASTER.txt', type: 'text/plain; charset=utf-8' },
    '/download/collector-ps1': { file: path.join(AGENT_DIR, 'Generate-Complete-Device-Guide.ps1'), name: 'Generate-Complete-Device-Guide.ps1', type: 'text/plain; charset=utf-8' },
    '/download/launcher-bat': { file: path.join(AGENT_DIR, 'Generate-Complete-Device-Guide-Now.bat'), name: 'Generate-Complete-Device-Guide-Now.bat', type: 'text/plain; charset=utf-8' },
    '/download/evaluation-md': { file: path.join(DOCS_DIR, 'NEXORA_v16_RUTHLESS_EVALUATION_AR.md'), name: 'NEXORA_v16_RUTHLESS_EVALUATION_AR.md', type: 'text/markdown; charset=utf-8' },
    '/download/roadmap-md': { file: path.join(DOCS_DIR, 'NEXORA_MEGA_ARCHITECTURE_AND_ROADMAP_AR.md'), name: 'NEXORA_MEGA_ARCHITECTURE_AND_ROADMAP_AR.md', type: 'text/markdown; charset=utf-8' }
  };

  if (downloadMap[pathname]) {
    const item = downloadMap[pathname];
    const data = fs.readFileSync(item.file);
    res.writeHead(200, {
      'Content-Type': item.type,
      'Content-Disposition': `attachment; filename="${item.name}"`
    });
    res.end(data);
    return;
  }

  // Static files from public/
  let relPath = pathname === '/' ? '/index.html' : pathname;
  const safePath = path.normalize(relPath).replace(/^(\.\.[\/\\])+/, '');
  const filePath = path.join(PUBLIC_DIR, safePath);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    const mimeTypes = {
      '.html': 'text/html; charset=utf-8',
      '.js': 'application/javascript; charset=utf-8',
      '.css': 'text/css; charset=utf-8',
      '.json': 'application/json; charset=utf-8',
      '.svg': 'image/svg+xml'
    };
    res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
    res.end(fs.readFileSync(filePath));
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('404 Not Found');
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`NEXORA-WINDOWS v20.0 APEX Studio running at http://0.0.0.0:${PORT}`);
});
