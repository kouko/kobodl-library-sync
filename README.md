# Kobo Library Sync (kobodl-library-sync)

這是一個用於自動同步 Kobo 電子書庫並轉換為 PDF 的 Shell Script 工具。它基於 `kobodl` 以及 `calibre` 來達成自動化下載與轉檔。

## 功能特色

- **自動下載**：自動檢查並下載最新版本的 `kobodl` 工具。
- **帳號同步**：自動登入 Kobo 帳號並同步您的購書清單。
- **格式轉換**：支援透過 Calibre 自動將 EPUB 轉換為 PDF (需手動安裝 Calibre)。
- **目錄管理**：自動建立並分類存放執行檔、設定檔與下載的書籍，保持專案目錄整潔。

## 系統需求

- macOS (本腳本專為 macOS 設計)
- **Calibre** (選用)：若需要轉檔功能，請先安裝 Calibre。

## 安裝與使用

### 快速開始 (Quick Start)

開啟 Terminal，複製貼上以下指令即可自動安裝到 `~/KobodlLibrarySync` 資料夾並執行：

```bash
mkdir -p ~/KobodlLibrarySync && curl -L -o ~/KobodlLibrarySync/kobodl-library-sync.sh https://raw.githubusercontent.com/kouko/kobodl-library-sync/main/kobodl-library-sync.sh && chmod +x ~/KobodlLibrarySync/kobodl-library-sync.sh && ~/KobodlLibrarySync/kobodl-library-sync.sh
```

### 日後使用 (Future Usage)

日後要再次同步時，只需在 Terminal 執行以下指令即可：

```bash
~/KobodlLibrarySync/kobodl-library-sync.sh
```


### 首次登入
第一次執行時，腳本會引導您進行登入：
1. 腳本顯示 `Open https://www.kobo.com/activate and enter XXXXXX`。
2. 請使用瀏覽器打開該網址，登入您的 Kobo 帳號。
3. 輸入腳本顯示的六位數代碼。
4. 完成後腳本將自動繼續執行下載。

## 檔案結構說明

本腳本執行後會自動產生以下目錄，請勿提交至版本控制系統 (已包含在 `.gitignore`)：

- **`bin/`**：存放自動下載的 `kobodl-macos` 執行檔。
- **`config/`**：存放 `kobodl.json` 設定檔 (包含您的登入資訊，請妥善保管)。
- **`downloads/`**：預設的電子書下載目錄 (包含 EPUB 與轉換後的 PDF)。

## 常見問題

**Q: 為什麼沒有轉檔成 PDF？**
A: 請確認您已安裝 Calibre，並且安裝在預設路徑 `/Applications/calibre.app`。如果未安裝，腳本只會執行下載功能。

**Q: 如何重新登入？**
A: 若需切換帳號，可以刪除 `config/kobodl.json` 檔案，下次執行時即會要求重新登入。
