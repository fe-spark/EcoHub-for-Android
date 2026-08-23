# EcoHub for Android

[EcoHub](https://github.com/fe-spark/EcoHub) 的 Android 客户端（Flutter）。装到手机后，连接你自己部署的 EcoHub 服务。

本仓库 **不是 EcoHub 本体**。EcoHub 是自托管影视聚合的服务端和 Web；这里只做 Android App。

同级还有 [EcoHub for OHOS](https://github.com/fe-spark/app-for-ohos)。

| | EcoHub | EcoHub for Android |
| --- | --- | --- |
| 是什么 | 服务端 + Web | Android App |
| 仓库 | [fe-spark/EcoHub](https://github.com/fe-spark/EcoHub) | [fe-spark/app-for-android](https://github.com/fe-spark/app-for-android) |
| 产物 | Docker 镜像 / 网站 | `.apk` / `.aab` |
| 设备显示名 | — | EcoHub |
| 包名 | — | `com.ecohub.ecohub` |

在 EcoHub 主仓里作为 git submodule，路径为 `app-for-android/`。

## 开发

```bash
flutter pub get
flutter run
```
