<div align="center">

![](https://repository-images.githubusercontent.com/728714946/42abb677-a9ff-45e6-820f-d517dc615ec2)

# Morpheus Launcher GUI

**A modern Flutter interface for Morpheus Launcher.**

![Flutter](https://img.shields.io/badge/Flutter-3.19.0-02569B?logo=flutter\&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-Windows%20%7C%20Linux%20%7C%20macOS-4B5563)
![Engineering Confidence: 7/10](https://img.shields.io/badge/Engineering%20Confidence-7%2F10-7CB342)

</div>

---

## 📃 Description

**Morpheus Launcher GUI** is the Flutter-based graphical interface for [Morpheus Launcher](https://github.com/Lampadina17/MorpheusLauncher).

It provides a modern desktop experience on top of the launcher core, with account management, mod-loader installation, Java setup, skin customization and other quality-of-life features.

The GUI is designed for users who want the flexibility of Morpheus Launcher without interacting directly with its command-line interface.

## ⚡ Features

* ✅ **Multiple account support**

  * Microsoft / Premium accounts
  * SP / offline accounts
* ✅ **One-click Forge installation**
* ✅ **One-click Fabric installation**
* ✅ **One-click OptiFine installation**
* ✅ **Automatic Java installation**
* ✅ **Premium account skin changer**
* ✅ **Minecraft changelog browser**
* ✅ **Interactive 3D skin viewer**
* ✅ **Frosted glass interface**
* ✅ **Material You-inspired themes**
* ✅ **Windows, Linux and macOS support**

## 🧠 Engineering confidence

**7/10 — Serious AI-assisted project**

Morpheus Launcher GUI is a serious, maintained project developed through a combination of manual engineering and AI-assisted implementation.

Approximately **40% of the development work has been AI-assisted**, particularly for implementation and repetitive development tasks. AI-generated changes are reviewed, adapted and tested before being integrated into the project.

The overall architecture, project direction and behavior remain manually controlled, but the heavier reliance on AI compared with the Morpheus Launcher core reduces confidence in complete code ownership and long-term maintainability.

The score reflects the **engineering process, verification depth, code ownership and maintainability of the project**, not simply whether the application works.

## 🧩 Relationship with Morpheus Launcher

The GUI acts as the user-facing frontend for the main Morpheus Launcher project:

```text
Morpheus Launcher GUI
        ↓
Account / version / configuration management
        ↓
Morpheus Launcher
        ↓
Minecraft: Java Edition
```

The launcher core remains responsible for the actual Minecraft launch process and compatibility logic, while the Flutter application provides the graphical interface around it.

## 🎨 Interface

Morpheus Launcher GUI focuses on providing a modern desktop interface while remaining usable across different platforms.

The UI includes:

* frosted-glass visual effects;
* Material You-inspired styling;
* responsive layouts;
* account and profile management;
* integrated Minecraft information;
* visual skin management.

## 👤 Account support

The GUI supports multiple Minecraft accounts and allows users to switch between them without manually reconfiguring the launcher.

Supported account types include:

| Account type        | Support |
| ------------------- | :-----: |
| Microsoft / Premium |    ✅    |
| SP / Offline        |    ✅    |

Premium accounts can also use the integrated skin changer.

## 🧱 Mod loaders

Morpheus Launcher GUI can automate the installation of common Minecraft mod loaders and modifications.

| Platform | Installation |
| -------- | :----------: |
| Forge    |  ✅ One-click |
| Fabric   |  ✅ One-click |
| OptiFine |  ✅ One-click |

Compatibility ultimately depends on the Minecraft version and on support provided by the underlying Morpheus Launcher core.

## ☕ Automatic Java installation

Different Minecraft versions require different Java runtimes.

The GUI can automatically install the appropriate Java environment instead of requiring the user to configure it manually.

This allows the launcher runtime and the Minecraft runtime to be managed independently.

## 🧍 3D skin viewer

The integrated skin viewer allows Minecraft skins to be inspected directly inside the launcher.

Premium users can also modify their skin through the account management interface.

## ⚙️ Compiling from source

### Requirements

To build Morpheus Launcher GUI you need:

* **Flutter 3.19.0**
* **IntelliJ IDEA Community or Ultimate**
* one of the supported desktop platforms:

  * Windows 10 or Windows 11;
  * Ubuntu 20.04 or newer;
  * macOS 11.3 or newer.

Make sure Flutter is correctly installed and available from your terminal:

```bash
flutter --version
flutter doctor
```

### Get the source

Clone the repository:

```bash
git clone <repository-url>
cd <repository-directory>
```

Fetch the project dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

### Build a desktop release

Use the appropriate Flutter target for your operating system.

#### Windows

```bash
flutter build windows
```

#### Linux

```bash
flutter build linux
```

#### macOS

```bash
flutter build macos
```

Generated artifacts will be placed inside Flutter's `build/` directory.

## 📚 Documentation

Installation instructions, launcher documentation and additional information are available through the official wiki:

[**Morpheus Launcher Wiki →**](https://morpheus-launcher.gitbook.io/home/)

## 📣 Community

Need help, found a bug or want to discuss Morpheus Launcher?

* **Wiki:** https://morpheus-launcher.gitbook.io/home/
* **Discord:** https://discord.com/invite/aerXnBe

## ⚖️ Open-source licensing

This project is distributed under **Creative Commons BY-NC-SA** terms.

In short:

* **BY — Attribution**
  The original author of this software must remain credited.

* **NC — NonCommercial**
  The project may not be used for commercial purposes.

* **SA — ShareAlike**
  Adaptations must be distributed under the same conditions as the original work.

> [!IMPORTANT]
> Review the complete license terms before redistributing or modifying the project.

## Warranty

> [!CAUTION]
> This software is provided **as-is**, without warranty of any kind.
>
> The author is not responsible for damage, data loss, incompatibilities or other issues resulting from use of the software.

---

<div align="center">

**Morpheus Launcher, without the command line.**

</div>
