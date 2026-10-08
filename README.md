# DayStart

macOS 菜单栏小工具：记录锁屏 / 解锁时间，并显示**每天第一次使用电脑的时间**。

数据只保存在本地，不上传、不联网。

## 功能

- 监听锁屏、解锁、睡眠、唤醒
- 菜单栏显示今天首次解锁时间
- 今天累计使用时长、解锁次数
- 最近几天首次使用时间列表
- 可选登录自启
- 数据保存在 `~/Library/Application Support/DayStart/events.json`

## 要求

- macOS 14+
- Xcode Command Line Tools / Swift 5.9+

## 构建安装

```bash
./scripts/build.sh
open ~/Applications/DayStart.app
```

也可安装到 `/Applications`：

```bash
./scripts/build.sh /Applications
```

## 使用

安装后点菜单栏时钟图标即可查看。首次解锁时间会显示在菜单栏标题上（如 `08:41`）。

## License

MIT
