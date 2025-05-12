# MergeX - Advanced PCAP & Hash Merger Tool

<div align="center">

![MergeX Banner](https://img.shields.io/badge/MergeX-PCAP%20%26%20Hash%20Merger-blue?style=for-the-badge&logo=wireshark)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/Platform-macOS-brightgreen.svg)](https://www.apple.com/macos)
[![ARM64](https://img.shields.io/badge/Architecture-ARM64-orange.svg)](https://en.wikipedia.org/wiki/AArch64)

*A powerful interactive tool for merging and processing network capture files and hash files*

</div>

---

## 🚀 Overview

MergeX is a specialized tool designed to streamline the process of working with network capture files (PCAP/PCAPNG) and hashcat-compatible hash files (.22000). It offers both command-line and interactive interfaces, optimized specifically for macOS running on Apple Silicon (ARM64).

The tool allows you to merge multiple PCAP files, extract hashes, combine with existing hash files, and remove duplicates—all within a visually appealing, user-friendly interface.

## ✨ Features

- 🔄 **Merge Multiple PCAPs** - Combine multiple capture files into a single file
- 🔑 **Hash Extraction** - Extract WPA/WPA2 handshakes (.22000 format) from PCAP files
- 🔍 **Auto-Search** - Scan volumes for relevant files
- 🧹 **Deduplication** - Remove duplicate hashes for cleaner output
- 🖥️ **Interactive CLI** - Beautiful terminal interface with menus and progress indicators
- 🎯 **macOS Optimization** - Specially designed for Apple Silicon (M1/M2/M3/M4)
- 🛠️ **Dependency Management** - Auto-detects and helps install required software

## 📋 Requirements

- macOS (optimized for ARM64/Apple Silicon)
- Wireshark (for `mergecap` utility)
- hcxtools (for `hcxpcapngtool` utility)
- Homebrew (recommended for dependency installation)

## 📥 Installation

1. **Clone the repository**:

```bash
git clone https://github.com/yourusername/mergex.git
cd mergex
```

2. **Make the script executable**:

```bash
chmod +x mergex-interactive.sh
```

3. **Run the script to check dependencies**:

```bash
./mergex-interactive.sh
```

The script will automatically check for required dependencies and offer to install any missing components using Homebrew.

## 🔧 Usage

### Interactive Mode

The easiest way to use MergeX is through its interactive interface:

```bash
./mergex-interactive.sh
```

This will launch the interactive menu where you can:
1. Select a source directory containing PCAP and hash files
2. Specify an output file
3. Use auto-search to scan all volumes
4. Process the files
5. View statistics and more

### Command-Line Options

For automation or quick usage, MergeX supports several command-line options:

```bash
./mergex-interactive.sh [OPTIONS]
```

Options:
- `-h, --help` - Show help message
- `-d, --dir PATH` - Specify source directory containing PCAP/hash files
- `-o, --output FILE` - Specify output file path
- `-a, --auto` - Auto-search mode (will search all mounted volumes)
- `-v, --verbose` - Enable verbose output

### Examples

**Process files in a specific directory**:
```bash
./mergex-interactive.sh -d ~/Documents/captures -o ~/results.22000
```

**Auto-search and process all files**:
```bash
./mergex-interactive.sh --auto -o ~/results.22000
```
<img width="1191" alt="Screenshot 2025-05-12 at 17 59 50" src="https://github.com/user-attachments/assets/4bd30687-5a64-49da-a2a2-bf0efaf231a0" />

**Interactive mode with verbose output**:
```bash
./mergex-interactive.sh -v
```

## 📊 Workflow

MergeX follows this process:

1. **File Discovery** - Locates PCAP/PCAPNG and .22000 files
2. **PCAP Processing** - Merges PCAP files using `mergecap`
3. **Hash Extraction** - Extracts WPA/WPA2 handshakes using `hcxpcapngtool`
4. **Hash Merging** - Combines extracted hashes with existing .22000 files
5. **Deduplication** - Removes duplicate entries using `sort -u`
6. **Output** - Saves the final result to the specified location

## 🖼️ Screenshots

<div align="center">
<i>Main Menu</i><br>
  <img width="1191" alt="Screenshot 2025-05-12 at 17 59 50" src="https://github.com/user-attachments/assets/181b15ac-6ee2-487a-850d-3f4411a9e25a" />

</div>

<div align="center">
<i>Processing Files</i><br>
[Screenshot of processing]
</div>

<div align="center">
<i>Results Summary</i><br>
[Screenshot of results]
</div>

## ❓ Troubleshooting

### Common Issues

#### Dependencies Not Found

If you see errors about missing tools:

```
[!] mergecap not found (part of Wireshark).
[!] hcxpcapngtool not found (part of hcxtools).
```

Allow the script to install them or manually install using:

```bash
brew install --cask wireshark
brew install hcxtools
```

#### Permission Issues

If you encounter permission problems:

```
[!] Cannot write to the specified path.
```

Make sure you have proper permissions for the target directory, or use `sudo` if necessary.

#### No Hashes Extracted

If no hashes are extracted from your PCAP files:

```
[!] No hashes extracted from PCAP files.
```

This usually means the PCAP files don't contain WPA/WPA2 handshakes, or they are in an incompatible format.

## 🔁 Compatibility

While MergeX is optimized for macOS on ARM64 (Apple Silicon), it may work on Intel-based Macs with warnings. The core functionality should also work on Linux systems with appropriate dependencies, but the user experience might be different.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Original idea by sadhuroot
- Enhanced interactive version optimized for macOS ARM64
- Utilizes Wireshark's mergecap and hcxtools for processing

---

<div align="center">
<p>Made with ❤️ for the security research community</p>
</div>

