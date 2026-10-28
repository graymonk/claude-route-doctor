# claude-route-doctor 🩺

> **Claude 线路医生** —— 一个诊断与修复 Clash Verge Rev 上 Claude 代理线路问题的 AI 智能体技能（skill）。
> 让 AI 替你完成排障中最难的部分：自动读取配置、定位问题、安全地修改，并告诉你哪几个开关需要手动点。

**一句话场景**：检测页信任分从 97 掉到 79、DNS 显示"中国DNS"泄露、出口 IP 变成机房、TUN 模式变慢——以前要折腾几小时，装了这个技能，对 AI 说一句话就行。

---

## 它能做什么

- 🔍 **自动诊断**：读取 Clash Verge Rev 的应用设置、运行时配置、订阅与增强配置，定位分流失灵 / DNS 泄露 / 出口漂移的根因
- 🛠 **安全修复**：自动备份后写入"扩展覆写配置"（防加密 DNS 绕过分流的 sniffer + 经代理的加密 DNS 上游），改完指导你重新激活
- 📋 **人机分工**：需要手动点击的开关（TUN / 系统代理 / Chrome 安全 DNS）给出精确到点击路径的清单，AI 不越权代劳
- 🧠 **内置实战经验**：三模式原理对照、97→79 五步排查、ECH 加密致盲嗅探的对策、"真泄露 vs 假警告"判定、TUN 堆栈 gVisor→Mixed 提速——全部来自真机多轮调试
- 🛡 **护栏**：改文件必先备份、一次只改一个变量、不外泄节点凭据、仅支持 Clash Verge Rev（检测到其他客户端自动停止）

## 安装

### 一键安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/graymonk/claude-route-doctor/main/install.sh | bash
```

<details>
<summary>可选参数</summary>

```bash
# 同时安装一份到 ~/.claude/skills（Claude Code）
curl -fsSL https://raw.githubusercontent.com/graymonk/claude-route-doctor/main/install.sh | bash -s -- --claude

# 额外安装到其他智能体的技能目录（例如 workbuddy）
curl -fsSL https://raw.githubusercontent.com/graymonk/claude-route-doctor/main/install.sh | bash -s -- --dir ~/.workbuddy/skills
```

</details>

### 手动安装

把本仓库的 `claude-route-doctor/` 文件夹（即 `SKILL.md` + `references/`）复制到技能目录：

| 智能体 | 位置 |
|---|---|
| ZCode / 通用标准 | `~/.agents/skills/claude-route-doctor/` |
| Claude Code | `~/.claude/skills/claude-route-doctor/` |
| 其他（workbuddy 等） | 其技能目录，或用 `install.sh --dir` |

安装后**重启一次 AI 工具**（新开会话）即可。

## 使用

装好后直接说人话，技能会自动触发：

- "我的 Claude 检测页信任分从 97 掉到 79 了，帮我修一下"
- "检测页 DNS 显示中国 DNS，泄露了，怎么办"
- "帮我检查一下 Clash Verge 的 Claude 线路配置"
- "开 TUN 模式之后感觉网速变慢了"

配合检测页 [ip.net.coffee/claude](https://ip.net.coffee/claude/) 使用，技能会指导你修复 → 重测 → 循环直到全绿。

### 全绿验收标准

| 项目 | 目标 |
|---|---|
| Claude 出口 IP | 住宅/专线节点，信任分 90+ |
| DNS | 未检测到泄露（海外服务商即可） |
| WebRTC UDP | 出口为海外节点 |
| 时区 / 语言 | 与出口地区一致 |

## 工作原理（为什么值得信）

本技能的全部结论来自 2026-10-28 的一次完整真机排障（信任分 97 → 79 → 97 的完整复原过程）：

1. **只开 TUN 会翻车**：浏览器"安全 DNS"让 Chrome 自己解析出真实 IP，绕过 fake-ip 域名分流；而 claude.ai 在 Cloudflare 后面，Chrome 的 ECH（加密 ClientHello）连嗅探都能致盲，且新版 Chrome 已移除关闭开关 → claude.ai 掉进普通机房节点（97 → 79 的真相）
2. **双开是唯一稳态**：TUN + 系统代理同开——系统代理让浏览器把域名明文交给 Clash（分流最可靠、免疫 ECH），TUN 兜底接管 UDP 防泄露
3. **DNS 泄露的根治**：Clash 默认国内上游 DNS 会把运营商信息带出去，把默认解析改为经代理的 Cloudflare/Google 加密 DNS 即可，国内域名照走国内解析不受影响

更多细节直接看 [SKILL.md](SKILL.md)，没有隐藏逻辑。

## 适用范围与限制

- ✅ Clash Verge Rev（macOS / Windows）
- ❌ ClashX、sing-box、Surge、Stash 等其他客户端（技能检测到后会自动停止）
- GUI 开关和检测页重测需要用户本人动手，AI 负责诊断、改配置和给出点击清单
- 注册、养号、支付等话题不在本技能范围内

## License

[MIT](LICENSE)
