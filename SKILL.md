---
name: claude-route-doctor
description: 诊断与修复 Clash Verge Rev 上使用 Claude 时的线路问题：检测页信任分骤降（如97→79）、Claude 出口IP变成机房、DNS 泄露显示"中国DNS"、WebRTC 泄露真实IP、TUN 模式变慢、分流被加密DNS/ECH 绕过等。Use whenever the user mentions Claude 检测、ip.net.coffee、出口IP、信任分、住宅IP、DNS 泄露、中国DNS、WebRTC 泄露、出口漂移、Clash 分流失效、sniffer、代理变慢，或让你"修 Claude 线路 / 检查代理配置 / 为什么被风控"——即使用户没说"诊断"二字。仅支持 Clash Verge Rev（Mac/Windows）；检测到其他代理客户端时停止并引导用户按手动教程操作。
---

# Claude 线路医生（仅支持 Clash Verge Rev）

帮用户把 Claude 的代理线路修到"最终形态"：检测页（https://ip.net.coffee/claude/）Claude 出口为住宅 IP、信任分 90+、DNS 无泄露、UDP 不漏真实 IP。所有结论源自 2026-10-28 真机排障实战（详见文末"背景知识"）。

## 0. 开始前：范围与护栏

- **只处理 Clash Verge Rev**。先探测客户端（见第 1 步）；如果用户用的是 ClashX / sing-box / Surge / Stash 等，停止修复，告知"本技能仅支持 Clash Verge Rev"，并把手动教程路径给用户。
- **隐私红线**：订阅配置里有节点 UUID、密码、服务器地址。读取配置做判断时，**只引用分组名、节点名、字段开关状态，绝不把凭据原文复述到回复里**。
- **四条军规**：
  1. 一次只改一个变量，改完让用户重测，否则无法归因；
  2. 改任何文件前先备份为 `原名.bak-YYYYMMDD`；
  3. 改配置 ≠ 生效：每次改动后必须让用户在「订阅」页右键订阅 →「**使用**」重新激活（或设置 → 重启内核）；
  4. GUI 动作（开关、下拉框、Chrome 设置）**是用户自己的活**——给出精确到点击路径的操作清单让用户执行，不要尝试自动化 GUI，也不要替用户点。
- Mac 与 Windows 的差异只在文件路径和个别命令，流程完全一致。

## 1. 探测环境

路径与关键文件的完整清单见 `references/config-paths.md`（读取后再继续）。要点：

- macOS：数据目录 `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/`，App 在 `/Applications/Clash Verge.app`
- Windows：数据目录 `%APPDATA%\io.github.clash-verge-rev.clash-verge-rev\`
- 找不到该目录或 App → 用户不是 Clash Verge Rev，按第 0 条停止。

## 2. 读取状态（按此顺序，读完整再下结论）

1. **开关**：`verge.yaml` → `enable_tun_mode`、`enable_system_proxy`（true/false）。
2. **运行时配置**：`clash-verge.yaml`（这是 App 生成、内核实际加载的合并结果）→
   - `tun:` 段的 `stack:`（gvisor = 慢，应建议 Mixed）
   - 是否存在 `sniffer:` 且 `enable: true`
   - `dns:` 段**只看 `nameserver:` 字段**：纯国内 IP（223.5.5.5/119.29.29.29）= 未改造；`https://1.1.1.1/dns-query#组名` = 已改造。注意 `default-nameserver` 是 DoH 的引导解析、必然是纯 IP，**不作为判定依据**，照字面判会误报
   - `proxy-groups:` 段是策略组名的**权威来源**（订阅 yaml 常是单行 JSON，直接 grep 会把节点名和组名混在一起）
   - 注意：verge.yaml 里没有 ≠ 没生效，以 clash-verge.yaml 运行时为准。
3. **订阅与增强配置**：`profiles.yaml` → `current:` 找到当前订阅 uid；该订阅条目 `option.merge` 指向的 uid 就是它的「扩展覆写配置」文件（`profiles/<merge-uid>.yaml`，通常是个空模板）。**修复一律写进这个 merge 文件，不要直接改订阅本体**（订阅更新会冲掉手改内容）。
4. **分组与规则**：当前订阅 yaml 里 grep `claude|anthropic`，确认 claude 域名是否已有锁定规则、指向哪个组；组名清单以第 2 条运行时配置的 `proxy-groups:` 段为准（第 4 步写 DNS 模板时，`#组名` 必须从这里选一个**真实存在**的组）。
5. **分组当前选择（文件化确认）**：`profiles.yaml` 中该订阅条目下的 `selected:` 列表记录了各组持久化的当前选择（`name` = 组名，`now` = 当前选中节点），可据此直接判断 claude 组是否停在住宅节点，GUI 只做复核。

把读到的情况汇总成一张状态表给用户（开关 / stack / sniffer / DNS 上游 / claude 分组），再进入第 3 步。

## 3. 对照诊断表

| 症状（检测页） | 根因 | 处置 |
|---|---|---|
| Claude 出口=机房 IP、信任分 70~80（曾经 90+） | claude.ai 流量没走锁定节点：加密 DNS/ECH 绕过分流，或分组被切 | 走第 4 步"五步排查" |
| DNS 显示"中国DNS"/运营商（电信/联通/移动） | Clash 默认上游是国内 DNS，陌生域名解析带出运营商信息 | 修复 1（DNS 上游改造），必然涉及 merge 文件 |
| UDP 出口 = 用户国内真实 IP | 只开了系统代理，UDP 绕过 | 让用户开 TUN（修复 3 清单） |
| UDP 出口 = 海外节点但有「异常」标签 | **良性**：只是 UDP 出口与 Claude 出口不同节点。claude.ai 不用 WebRTC | 告知无需处理 |
| DNS 出口显示 Google/Cloudflare，地理在香港/美国 | **良性**：任播就近应答。红线只有"中国DNS" | 告知无需处理 |
| 「中国出口IPV4」卡显示真实 IP | **良性**：检测站特意探测直连线路的展示位，Claude 看不到 | 告知无需处理 |
| TUN 模式明显变慢 | `tun.stack: gvisor`（用户态协议栈） | 修复 2：改 Mixed |
| claude.ai 延迟 250~650ms | 住宅/专线两跳链的正常水平 | 告知正常，别为此切机房节点 |
| `REALITY authentication failed` / connect EOF | 自建服务器问题（Xray v26 / 参数不符） | 超出本技能范围，引导用户查手动教程"常见故障排查"表 |

**"五步排查"**（出口漂移专用，按序执行、每步之间重测）：
1. 三个开关全开吗：TUN + 系统代理 + Chrome 安全 DNS（Cloudflare）。最常见的翻车组合：只开 TUN + Chrome 安全 DNS → 加密 DNS 绕过域名分流；
2. 「代理」页：claude 用的组/节点是否被切到机房节点？是否在负载均衡组（必须退出，负载均衡每次连接换 IP 是风控重灾区）？文件侧可先读 `profiles.yaml` 该订阅的 `selected[].now` 确认当前停在哪个节点，GUI 复核；
3. 运行时配置里 sniffer 是否存在且 enable（不存在 → 修复 1）；
4. ECH 教训：只开 TUN 时 Chrome 的加密 ClientHello 会致盲嗅探，且新版 Chrome 已移除关闭开关 → **开系统代理即解**（域名明文进 Clash）；
5. 每次改动后重新激活订阅再测。

## 4. 修复动作库

### 修复 1：写入增强配置（sniffer + DNS 上游改造）——核心修复

模板在 `references/merge-template.yaml`。流程：

1. 读取模板内容；
2. 把模板里 `#🔰国外流量` 占位组名**替换成第 2 步第 4 条列出的真实组名**（优先选承载国外流量的总组；模板注释里有选择说明）；
3. 若 merge 文件已有内容（比如已写过 sniffer），只合并缺失的段，不要盲目覆盖；改前备份 `.bak-YYYYMMDD`；
4. 写入后告诉用户：**订阅页右键订阅 →「使用」重新激活**，然后重测检测页；
5. 验证生效：重新读 `clash-verge.yaml`，确认 `sniffer` 出现且 `dns.nameserver` 已变成 DoH 写法。

⚠️ 不要通过 merge 文件给 claude 加域名锁定规则——Verge 的 merge 对列表是整体替换，会冲掉订阅原有全部规则。锁定节点请让用户在「代理」页手动选定（组类型为 select/fallback 且出口为住宅的），并远离 load-balance。

### 修复 2：TUN 堆栈 gvisor → Mixed（提速）

这是 GUI 设置：让用户打开 设置 → 「虚拟网卡模式」（TUN 设置）→ **TUN 模式堆栈选 Mixed** → 保存。给出这段点击路径即可，不要手改配置文件（该值由 App 管理）。

### 修复 3：开关清单（交付给用户手动执行）

- Clash Verge 设置页：**TUN 模式开**、**系统代理开**（两者共存，是实战验证的最终形态：系统代理保证域名明文进 Clash 分流最稳，TUN 兜底接管 UDP）；
- Chrome：设置 → 隐私和安全 → 安全 → 使用安全 DNS → **Cloudflare (1.1.1.1)**；
- 顺带检查 TUN 设置里 IPv6 = 关、严格路由建议开（导致内网访问异常可关，由修复 1 的 DNS 改造兜底）。

### 修复 4：分组锁定

让用户在「代理」页找到承载 claude 的组，手动选定住宅/AI 专线节点。若订阅本身没有 claude 域名锁定规则、也没有住宅节点，说明该机场不满足条件，建议用户换带住宅专线的订阅（如实告知，不要硬凑）。

**收尾分支（重要）**：如果第 2 步读到的配置已全部达标（双开 ✓、sniffer ✓、DNS 已改造 ✓、claude 锁定住宅组且非 load-balance ✓），但用户症状（机房出口/低分）依然存在——**本地已无可修项**，归因于住宅供应商侧（出口漂移、健康检查已切到备用出口、或该 IP 被检测方改判）。如实告知：先重测一次（可能自愈），仍不行就联系供应商或更换住宅线路；不要为此切机房节点硬凑，也不要继续无意义的本地改动。

## 5. 验证循环

每次修复后让用户刷新 https://ip.net.coffee/claude/ 并把结果（截图或文字）反馈，按第 3 步判定表解读。**全绿验收标准**：

- Claude 出口 = 住宅/专线节点 IP，信任分 90+；
- DNS = 「未检测到泄露」，服务商为海外（Google/Cloudflare，地理位置香港/美国均可）；
- UDP 出口 = 海外节点（「异常」标签忽略）；
- 时区/语言一致（时区不一致属系统设置，引导用户改系统时区：美国 IP 改当地时区，新加坡 IP 免改；语言把 English 置顶）。

达标后提醒用户三条日常纪律：三开关常开；Claude 分组永不切机房节点/负载均衡；改配置必重新激活。

## 6. 背景知识（为什么是这样，给模型的理解底座）

- **双开的原理**：系统代理模式下浏览器把域名明文交给 Clash（CONNECT），域名分流最可靠且免疫 ECH；TUN 接管全部流量含 UDP 防漏。只开 TUN 时浏览器自己握手，加密 DNS（DoH）绕过 fake-ip、ECH 连嗅探都致盲，claude.ai 在 Cloudflare 后面必然触发。新版 Chrome 已移除关闭 ECH 的 flags 开关，所以"只开 TUN"没有可靠解，双开是唯一稳态。
- **住宅 vs 机房**：家庭住宅（ISP）IP 信任分普遍 90+，机房（Hosting）只有 50~80；97→79 的分数骤降几乎都是出口漂移，不是 IP 被封。
- 完整教程（含从零自建、注册养号、支付）在用户的教程包 `01-完整教程-双平台通用.md`，本技能只管诊断修复。
