# Clash Verge Rev 路径与关键文件（参考手册）

## 数据目录

| 平台 | 数据目录 |
|---|---|
| macOS | `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/` |
| Windows | `%APPDATA%\io.github.clash-verge-rev.clash-verge-rev\`（即 `C:\Users\<用户名>\AppData\Roaming\...`） |

App 本体：macOS `/Applications/Clash Verge.app`；Windows 开始菜单 "Clash Verge"。

## 目录内关键文件

| 文件 | 作用 | 排障时看什么 |
|---|---|---|
| `verge.yaml` | App 设置 | `enable_tun_mode`、`enable_system_proxy`、`verge_mixed_port`（默认 7897） |
| `profiles.yaml` | 订阅索引 | `current:` 当前订阅 uid；各条目 `option.merge` 指向该订阅的「扩展覆写配置」uid |
| `profiles/<uid>.yaml` | 订阅本体 / 增强配置 | type: remote=机场订阅、local=本地；merge=扩展覆写配置（修复写这里） |
| `clash-verge.yaml` | **运行时配置**（App 生成、内核实际加载） | `tun.stack`、`sniffer` 是否存在、`dns.nameserver` —— 判断"是否生效"以它为准 |
| `logs/latest.log` | App 日志（非内核连接日志） | 配置重载、验证记录；内核连接记录只在 App「日志」页实时显示，不落盘 |
| `dns_config.yaml` | 「DNS 覆写」功能的配置 | 仅当 App 设置里开了 DNS 覆写才有意义 |

## 常用检查命令

macOS（bash/zsh）：

```bash
D=~/Library/Application\ Support/io.github.clash-verge-rev.clash-verge-rev
grep -nE "enable_tun_mode|enable_system_proxy" "$D/verge.yaml"
grep -nE "stack:" "$D/clash-verge.yaml"
grep -n "sniffer" "$D/clash-verge.yaml" | head -3
grep -nA 6 "^dns:" "$D/clash-verge.yaml" | head -12
grep -n "current:" "$D/profiles.yaml"
# 策略组名清单以运行时配置的 proxy-groups 为准
# （订阅 yaml 常是单行 JSON，直接 grep "name" 会把节点名混进来）：
awk '/^proxy-groups:/{f=1;next} /^[^ -]/{f=0} f && /- name:/{sub(/^[- ]+name: */,""); print}' "$D/clash-verge.yaml"
# claude 域名规则（订阅本体）：
grep -inE "claude|anthropic" "$D/profiles/<订阅uid>.yaml" | head -20
# 各组当前选定节点（文件化确认，GUI 复核）：
grep -A 14 "uid: <订阅uid>" "$D/profiles.yaml" | grep -E "name:|now:"
```

Windows（PowerShell）：

```powershell
$D = "$env:APPDATA\io.github.clash-verge-rev.clash-verge-rev"
Select-String "$D\verge.yaml" -Pattern "enable_tun_mode|enable_system_proxy"
Select-String "$D\clash-verge.yaml" -Pattern "stack:|sniffer"
Select-String "$D\profiles.yaml" -Pattern "current:"
```

## 生效机制（重要）

- 「扩展覆写配置」= merge 文件，App 在激活订阅时把它与订阅本体、脚本叠加生成 `clash-verge.yaml`。
- 对 merge 里列表型字段（如 `rules`）做合并会**整体替换**订阅原列表——所以不要用 merge 追加 claude 分流规则，锁节点走「代理」页手动选择。
- 修改任何 profiles/ 下的文件后，必须让用户：订阅页右键订阅 →「使用」重新激活（或 设置 → 重启内核），改动才会进入 `clash-verge.yaml`。
