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
# 更新所有 inputs（nixpkgs、home-manager 等）到最新版本
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
