# 🎵 MusicPlayerCMake

一个基于 Qt6 和 CMake 构建的现代化音乐播放器，具有美观的用户界面和丰富的功能。

![Music Player](https://img.shields.io/badge/Qt-6.6.3-green?style=flat-square&logo=qt)
![CMake](https://img.shields.io/badge/CMake-3.16+-blue?style=flat-square&logo=cmake)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?style=flat-square&logo=windows)

## ✨ 特性

### 🎧 核心功能
- **多格式支持**: 支持 MP3、FLAC、WAV、M4A 等常见音频格式
- **播放控制**: 播放、暂停、上一首、下一首、停止
- **播放模式**: 顺序播放、循环播放
- **音量控制**: 精确音量调节、静音功能
- **进度控制**: 可拖拽的进度条，实时显示播放进度

### 🎨 用户界面
- **现代化设计**: 简洁美观的用户界面
- **自定义标题栏**: 无边框窗口设计，支持窗口拖拽
- **系统托盘**: 最小化到系统托盘，支持托盘控制
- **播放列表**: 可折叠的播放列表，支持拖拽排序
- **主题样式**: 自定义 QSS 样式表

### 🔧 高级功能
- **均衡器**: 内置多种预设和自定义均衡器
- **键盘快捷键**: 丰富的快捷键支持
- **窗口置顶**: 支持窗口始终置顶
- **通知系统**: 音量、均衡器等操作提示
- **设置保存**: 自动保存播放列表和用户设置

### ⌨️ 快捷键
- `空格键`: 播放/暂停
- `←/→`: 上一首/下一首
- `↑/↓`: 音量增减
- `M`: 静音/取消静音
- `L`: 显示/隐藏播放列表
- `E`: 打开均衡器

## 🚀 快速开始

### 📋 系统要求
- **操作系统**: Windows 10/11
- **Qt版本**: Qt 6.6.3 或更高版本
- **编译器**: MSVC 2019/2022 或 MinGW
- **CMake**: 3.16 或更高版本

### 🛠️ 编译和安装

1. **克隆仓库**
   ```bash
   git clone https://github.com/Sqhh99/MusicPlayer.git
   cd MusicPlayer
   ```

2. **安装依赖**
   - 确保已安装 Qt 6.6.3+ 开发环境
   - 确保已安装 CMake 3.16+
   - 确保已安装 Visual Studio 2019/2022 或 MinGW

3. **配置项目**
   ```bash
   mkdir build
   cd build
   cmake .. -G "Visual Studio 17 2022" -A x64
   ```

4. **编译项目**
   ```bash
   cmake --build . --config Release
   ```

5. **运行程序**
   ```bash
   ./Release/MusicPlayerCMake.exe
   ```

### 📦 预编译版本
您也可以从 [Releases](https://github.com/Sqhh99/MusicPlayer/releases) 页面下载预编译的可执行文件。

## 🎯 使用方法

### 基本操作
1. **添加音乐**: 点击文件夹图标选择音频文件
2. **播放音乐**: 双击播放列表中的歌曲或点击播放按钮
3. **控制播放**: 使用播放控制按钮或键盘快捷键
4. **调节音量**: 点击音量按钮或使用音量滑块

### 高级功能
- **均衡器**: 点击菜单或按 `E` 键打开均衡器
- **播放模式**: 点击模式按钮切换顺序/循环播放
- **系统托盘**: 最小化后可通过托盘图标控制播放

## 🏗️ 项目结构

```
MusicPlayerCMake/
├── src/
│   ├── main.cpp              # 程序入口
│   ├── playwidget.h/cpp      # 主窗口界面
│   ├── musicplayer.h/cpp     # 音乐播放器核心
│   ├── musicsettings.h/cpp   # 设置管理
│   ├── volumepopup.h/cpp     # 音量弹窗
│   └── stylemanager.h        # 样式管理
├── styles/                   # QSS 样式文件
│   ├── base.qss             # 基础样式
│   ├── player.qss           # 播放器样式
│   ├── playlist.qss         # 播放列表样式
│   ├── slider.qss           # 滑块样式
│   ├── scrollbar.qss        # 滚动条样式
│   └── volume.qss           # 音量样式
├── resources/               # 资源文件
│   └── tubiao/             # 图标文件
├── CMakeLists.txt          # CMake 配置
├── playwidget.ui           # UI 界面文件
├── musicFile.qrc           # 资源文件
├── Icon.rc                 # Windows 图标资源
├── LICENSE                 # MIT 许可证
└── README.md              # 项目说明
```

## 🎨 截图

### 主界面
![主界面](docs/screenshots/main-interface.png)

### 播放列表
![播放列表](docs/screenshots/playlist.png)

### 均衡器
![均衡器](docs/screenshots/equalizer.png)

## 🤝 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

### 开发指南
- 代码风格：遵循 Qt 编码规范
- 提交信息：使用清晰的提交信息
- 测试：确保新功能经过测试

## 🐛 问题报告

如果您遇到问题或有建议，请：
1. 查看 [Issues](https://github.com/Sqhh99/MusicPlayer/issues) 页面
2. 如果问题未被报告，请创建新的 Issue
3. 提供详细的问题描述和复现步骤

## 📝 更新日志

### v2.0.0 (2025-06-19)
- ✨ 重构为 CMake 项目
- 🎨 全新的用户界面设计
- 🔧 添加均衡器功能
- ⌨️ 完善的键盘快捷键支持
- 🔄 改进的进度条同步机制
- 📱 系统托盘功能增强
- 🎵 播放列表交互优化

### v1.0.0
- 🎵 基础音乐播放功能
- 📋 播放列表管理
- 🔊 音量控制
- 🎨 基础用户界面

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 👨‍💻 作者

- **Sqhh99** - *初始开发* - [GitHub](https://github.com/Sqhh99)

## 🙏 致谢

- [Qt Framework](https://www.qt.io/) - 提供强大的 C++ 框架
- [CMake](https://cmake.org/) - 跨平台构建工具
- 所有贡献者和用户的支持

## 📞 联系方式

- 项目主页: https://github.com/Sqhh99/MusicPlayer
- 问题反馈: https://github.com/Sqhh99/MusicPlayer/issues

---

⭐ 如果这个项目对您有帮助，请给它一个星标！