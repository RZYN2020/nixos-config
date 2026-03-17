# NixOS Configuration (Flake)

本仓库使用 [Nix Flakes](https://nixos.wiki/wiki/Flakes) 管理 NixOS 系统配置。

## 前置要求

确保你的 Nix 已启用 Flake 支持。在 `/etc/nix/nix.conf` 或 `~/.config/nix/nix.conf` 中添加：

```ini
experimental-features = nix-command flakes
```


## 常用命令

### 系统重建

```bash
# 构建并切换到新配置（最常用）
sudo nixos-rebuild switch --flake .#<hostname>

# 构建并在下次重启时切换（不立即生效）
sudo nixos-rebuild boot --flake .#<hostname>

# 仅构建，不切换（用于验证配置是否正确）
sudo nixos-rebuild build --flake .#<hostname>

# 构建并切换，但不写入 bootloader（临时测试，重启后回滚）
sudo nixos-rebuild test --flake .#<hostname>
```

> **提示**：如果 `<hostname>` 与当前系统的 hostname 一致，可省略 `#<hostname>`，直接使用 `--flake .`。

### 依赖管理

```bash
# 更新所有 inputs（如 nixpkgs）到最新版本
nix flake update

# 仅更新指定 input
nix flake update nixpkgs

# 查看当前 flake 的所有 inputs 及其锁定版本
nix flake metadata

# 查看 flake 提供的所有 outputs
nix flake show
```

### 开发与调试

```bash
# 进入一个包含当前 flake 依赖的 nix shell
nix develop

# 以当前 flake 的 nixpkgs 启动一个 REPL，方便交互式调试
nix repl .

# 在 REPL 中查看某个配置项的值（示例）
# nix-repl> nixosConfigurations.<hostname>.config.services.openssh.enable

# 检查 flake 语法是否正确
nix flake check

# 快速构建某个 package（如果 flake 有定义 packages output）
nix build .#<package-name>

# 不安装直接运行某个 package
nix run .#<package-name>
```

### 回滚与历史

```bash
# 查看所有系统 generation
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# 回滚到上一个 generation
sudo nixos-rebuild switch --rollback

# 切换到指定 generation
sudo nix-env --switch-generation <number> --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### 垃圾回收

```bash
# 删除 15 天前的旧 generation
sudo nix-collect-garbage --delete-older-than 15d

# 删除所有旧 generation（仅保留当前）
sudo nix-collect-garbage -d

# 优化 Nix Store（硬链接去重，节省磁盘空间）
nix store optimise
```

## 远程部署

Flake 支持直接从远程仓库构建：

```bash
# 从 GitHub 仓库部署
sudo nixos-rebuild switch --flake github:<user>/<repo>#<hostname>

# 从私有仓库（需配置 access token）
sudo nixos-rebuild switch --flake git+ssh://git@github.com/<user>/<repo>#<hostname>
```

也可以配合 [deploy-rs](https://github.com/serokell/deploy-rs) 或 [colmena](https://github.com/zhaofengli/colmena) 进行多机远程部署。

## 工作流建议

1. **所有改动先提交到 Git**——Flake 默认只追踪 Git 已跟踪的文件。新增文件至少需要 `git add` 之后才能被 Flake 识别。
2. **先 `build` 再 `switch`**——确认构建无报错后再切换，避免进入不可用的配置。
3. **定期 `nix flake update`**——保持依赖更新，但建议每次更新后充分测试。
4. **提交 `flake.lock`**——锁文件确保团队或多台机器使用完全一致的依赖版本。
5. **善用 `git diff` + `nixos-rebuild build`**——在 switch 前 review 变更。

## 配置约定

- flake 主机名：当前 outputs 提供 `mond` 与 `sonne` 两台主机，命令示例：`sudo nixos-rebuild switch --flake .#mond`
- 开发环境开关：可在主机配置中设置 `develop.enable = false;` 以避免安装 common/develop 下的开发工具（适合 server）
- GUI 开关：`gui.enable = false;` 会关闭 GUI 相关配置；common/daily 下桌面包仅在 GUI 启用时生效
- 密钥与敏感信息：不要在仓库里明文保存 Wi-Fi/Token 等；建议使用 sops-nix/age 管理运行时密钥文件（解密落到 `/run/secrets`）

## sops-nix（机器密钥/Token）

### 从零拉取代码与配置密钥流程

当你在 NixOS 主机上全新拉取本仓库时，请按以下步骤配置你的加密环境，**切勿直接提交明文密钥**。

1. **拉取代码**：
   ```bash
   git clone <你的仓库地址> /etc/nixos-config  # 或其他目录
   cd /etc/nixos-config
   ```

2. **获取/配置解密公钥（Age Recipient）**：
   - 获取目标主机（如 `mond`）的 SSH Host Key：
     ```bash
     nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
     ```
     你会得到一个 `age1...` 开头的字符串。
   - 编辑项目根目录的 `.sops.yaml`，将该字符串填入 `age:` 列表下。
   - *(可选)* 如果你想在其他机器上也能解密，可以把其他机器的 `age` 公钥一并追加进去。

3. **创建并加密你的 `secrets.yaml`**：
   - 运行 sops 创建加密文件：
     ```bash
     nix-shell -p sops --run "sops secrets/secrets.yaml"
     ```
   - 在弹出的编辑器中填入你的敏感信息（参考下方的**密钥清单**）。
   - 保存退出后，`sops` 会自动用 `.sops.yaml` 中配置的公钥将文件加密。

4. **将加密后的文件提交到 Git**：
   - Flake **只会识别 Git 追踪的文件**。你必须先将新增的加密文件和修改添加到 Git：
     ```bash
     git add .sops.yaml secrets/secrets.yaml
     ```
   - *（注意：只提交被 sops 加密过的文件，绝对不要提交未加密的临时文件）*

5. **在主机配置中启用并重建**：
   - 修改 `profiles/mond/configuration.nix`（或其他主机），开启你需要的功能：
     ```nix
     secrets.enable = true;
     secrets.sopsFile = ./secrets/secrets.yaml;
     
     secrets.anthropic.enable = true; # 开启 Claude Code 密钥
     secrets.wifi.enable = true;      # 开启 Wi-Fi 自动配置
     secrets.wifi.connectionFileName = "ziroom201.nmconnection";
     ```
   - 重建系统：
     ```bash
     sudo nixos-rebuild switch --flake .#mond
     ```

### 密钥清单（建议字段）

当你运行 `sops secrets/secrets.yaml` 时，建议按以下 YAML 结构填入密钥：

```yaml
anthropic-api-key: "sk-ant-..."
wifi-nmconnection: |
  [connection]
  id=ziroom201
  type=wifi
  interface-name=wlp1s0

  [wifi]
  mode=infrastructure
  ssid=ziroom201

  [wifi-security]
  key-mgmt=wpa-psk
  auth-alg=open
  psk=你的密码

  [ipv4]
  method=auto

  [ipv6]
  addr-gen-mode=default
  method=auto
```

> **后续更新密钥的注意点**：  
> 每次使用 `sops secrets/secrets.yaml` 修改完密钥后，记得执行 `git add secrets/secrets.yaml` 才能被 flake 识别，然后再 `nixos-rebuild switch`。

## AI 编程工具 (Claude Code)

- 本仓库已通过 `sadjow/claude-code-nix` overlay 提供了最新版、免 npx 的 Claude Code 原生包
- 启用方式（写在某个 profile 里）：

```nix
develop.ai.enable = true;
# 可选：切换运行时为 node 或 bun，默认是 native（无依赖单文件）
# develop.ai.claudeCode.runtime = "node"; 
```

- **依赖 API Key 才能工作**：必须同时开启 `secrets.anthropic.enable = true;` 并在 `secrets.yaml` 中配置好 `anthropic-api-key`。
- 运行：`claude` （包装命令会自动从 `/run/secrets` 读取 key 并注入环境变量，然后调用原生二进制）。

> **构建加速（可选）**：  
> `claude-code-nix` 提供了 Cachix 缓存。如果你不想在本地从源码编译/下载打包，可以在系统层面添加：
> ```bash
> nix-env -iA cachix -f https://cachix.org/api/v1/install
> cachix use claude-code
> ```

## Wi-Fi（建议不要声明式存 PSK）

- 不建议把 Wi-Fi PSK 写进 Nix 配置或 Git（包括明文写进 Nix 字符串）
- 本仓库提供一个可选方案：把 NetworkManager 的连接文件（包含 SSID/PSK）作为 sops secret 解密落盘到 `/etc/NetworkManager/system-connections`
- 启用方式（写在 `profiles/mond/configuration.nix` 里）：

```nix
secrets.enable = true;
secrets.sopsFile = ./secrets/secrets.yaml;
secrets.wifi.enable = true;
secrets.wifi.connectionFileName = "ziroom201.nmconnection";
```

- 或者最简单：在机器上用 NetworkManager 命令式管理一次连接，然后不放入仓库
  - `nmcli dev wifi connect "<ssid>" password "<password>"`

## SSH（通过 Tailscale 访问）

- 建议：禁用 SSH 密码登录，仅允许公钥，并只在 `tailscale0` 接口放行 22 端口
- 本仓库的 `mond` 已按此方式收紧

## 常见问题

| 问题 | 解决方案 |
|---|---|
| `error: path '/xxx' is not in the Nix store` | 新增文件未 `git add`，Flake 无法识别 |
| `error: experimental Nix feature 'flakes' is disabled` | 在 `nix.conf` 中添加 `experimental-features = nix-command flakes` |
| 构建耗时过长 | 考虑配置 [binary cache](https://nixos.wiki/wiki/Binary_Cache) 或使用 `cachix` |
| `nixos-rebuild` 提示权限不足 | 系统级操作需要 `sudo`，但编辑配置文件不需要 |
| 想回到非 Flake 模式 | `sudo nixos-rebuild switch` 不带 `--flake` 即可回到 `/etc/nixos/configuration.nix` |

## 参考资料

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes Wiki](https://nixos.wiki/wiki/Flakes)
- [nix.dev 官方教程](https://nix.dev/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)

---

可以根据你的实际项目结构（比如是否用了 home-manager、是否多主机等）做进一步裁剪或补充。
