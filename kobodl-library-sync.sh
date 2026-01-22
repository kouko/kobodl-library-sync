#!/bin/bash

# ========================================================
# 設定區
# ========================================================
BINARY_NAME="kobodl-macos"
DOWNLOAD_URL="https://github.com/subdavis/kobo-book-downloader/releases/latest/download/kobodl-macos"
CONVERTER="/Applications/calibre.app/Contents/MacOS/ebook-convert"
OUTPUT_DIR="kobo_downloads"  # 指定書籍儲存資料夾
CONFIG_FILE="kobodl.json"    # 指定設定檔名稱

# 設定執行指令 (包含 config 參數)
CMD="./$BINARY_NAME --config $CONFIG_FILE"

# ========================================================
# 階段一：環境檢查與工具準備
# ========================================================
echo "=============================================================="
echo "🛠️  環境檢查與工具準備"
echo "    1. kobodl (下載 Kobo 電子書 & 處理 DRM 的工具)"  
echo "       - 原始專案位置： https://github.com/subdavis/kobo-book-downloader"
echo "       - 此 Script 會自動下載執行檔並保存在當前資料夾"
echo " "
echo "    2. calibre (ePub 管理與瀏覽工具，當前用於 ePub 轉換 PDF)" 
echo "       - 原始專案位置： https://calibre-ebook.com/zh_TW/download_osx"          
echo "       - 此 Script 不會自動下載 calibre"
echo "       - 請至 calibre 網站下載 macOS 版本，並依照一般 macOS App 的安裝方式"
echo "         將程式複製到 Applications 資料夾"
echo "       - 如未安裝 calibre，則會自動略過 ePub 轉換 PDF 的步驟"
echo " "
echo "--------------------------------------------------------------"
echo " "
echo "🛠️  登入與驗證 kobo 帳號"
echo "    - kobo 登入資訊會儲存在與 script 相同資料夾的 kobodl.json 檔案內" 
echo "    - 如無該檔案，或該檔案內沒有登入資訊，會觸發登入流程"
echo "    - 登入流程模擬 Android kobo Reader App，流程為："
echo "       1. 此 Script 會提示使用者進入 kobo 頁面輸入指定的六位數字，例如： "
echo "          - Open https://www.kobo.com/activate and enter 123456."
echo "       2. 使用瀏覽器到 https://www.kobo.com/activate 網頁"
echo "       3. 在該網頁登入 kobo 帳號"
echo "       4. 輸入指定的六位數字"
echo "       5. 此 Script 會自動偵測上述動作是否完成，完成後將登入資訊記錄在"
echo "          與 script 相同資料夾的 kobodl.json 檔案內"
echo " "
echo "=============================================================="
echo " "


# 1. 檢查並下載 kobodl
if [ -f "$BINARY_NAME" ]; then
    echo "✅ 檢測到工具已存在：$BINARY_NAME"
else
    echo "⬇️  工具未安裝，正在使用 curl 下載 $BINARY_NAME ..."
    curl -L -o "$BINARY_NAME" "$DOWNLOAD_URL"
    
    if [ $? -eq 0 ]; then
        echo "   下載完成，設定執行權限..."
        chmod +x "$BINARY_NAME"
        echo "   正在解除 macOS 安全性隔離標籤..."
        xattr -d com.apple.quarantine "$BINARY_NAME" 2>/dev/null || true
    else
        echo "❌ 下載失敗，請檢查網路連線。"
        exit 1
    fi
fi

# 2. 建立下載資料夾
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "📂 建立資料夾：$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
fi

# 3. 檢查 Calibre
if [ ! -f "$CONVERTER" ]; then
    echo "⚠️  警告：找不到 Calibre ($CONVERTER)"
    echo "   將只執行下載，不執行轉檔。"
    CAN_CONVERT=false
else
    CAN_CONVERT=true
fi
echo "=============================================================="
echo ""

# ========================================================
# 階段二：自動登入檢查 (Auto Login Check)
# ========================================================
echo "🔑 正在檢查登入狀態..."

NEED_LOGIN=false

# 情況 A: 設定檔完全不存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "   ⚠️  找不到設定檔 ($CONFIG_FILE)。"
    NEED_LOGIN=true
else
    # 情況 B: 設定檔存在，但沒有使用者 (檢查 list 輸出是否包含 @)
    # 2>/dev/null 隱藏錯誤訊息，若 grep 找不到 @ 則回傳非 0 狀態
    if ! $CMD user list 2>/dev/null | grep -q "@"; then
        echo "   ⚠️  設定檔存在但無使用者資料。"
        NEED_LOGIN=true
    else
        echo "   ✅ 已登入使用者: $($CMD user list | head -n 3)"
    fi
fi

# 如果需要登入，則執行 user add
if [ "$NEED_LOGIN" = true ]; then
    echo "---------------------------------------------------"
    echo "🚀 啟動自動登入程序"
    echo "   請依照提示輸入您的 Kobo 帳號 (Email) 與密碼。"
    echo "   (注意：輸入密碼時畫面上不會顯示字元)"
    echo "---------------------------------------------------"
    
    # 執行互動式登入
    $CMD user add
    
    # 登入後再次檢查是否成功
    if [ $? -eq 0 ] && [ -f "$CONFIG_FILE" ]; then
        echo ""
        echo "   ✅ 登入成功！繼續執行同步..."
    else
        echo ""
        echo "❌ 登入失敗或被取消，程式終止。"
        exit 1
    fi
fi
echo ""

# ========================================================
# 階段三：主流程 (下載 -> 轉檔)
# ========================================================
echo "☁️  正在獲取書籍清單..."

REMOTE_LIST=$($CMD book list 2>/dev/null | grep -oE '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}')

if [ $? -ne 0 ]; then
    echo "❌ 獲取清單失敗 (可能原因: 網路錯誤或 Session 過期)。"
    exit 1
fi

if [ -z "$REMOTE_LIST" ]; then
    echo "⚠️  警告：您的帳號內似乎沒有任何書籍。"
    exit 0
fi

shopt -s nullglob
echo "🚀 開始執行同步作業 (儲存至 ./$OUTPUT_DIR)..."
echo "---------------------------------------------------"

while IFS= read -r full_id; do
    if [ -n "$full_id" ]; then
        short_id="${full_id%%-*}"
        current_epub=""
        
        # --- 下載檢查 ---
        existing_files=( "$OUTPUT_DIR"/*"${short_id}.epub" )
        
        if [ ${#existing_files[@]} -gt 0 ]; then
            current_epub="${existing_files[0]}"
            echo "📘 [EPUB 已存在] ${current_epub##*/}"
        else
            echo "⬇️  [下載 EPUB] ID: $full_id"
            $CMD book get --output-dir "$OUTPUT_DIR" "$full_id"
            
            if [ $? -eq 0 ]; then
                echo "   ✅ 下載成功"
                downloaded_files=( "$OUTPUT_DIR"/*"${short_id}.epub" )
                if [ ${#downloaded_files[@]} -gt 0 ]; then
                    current_epub="${downloaded_files[0]}"
                else
                    echo "   ❌ 錯誤：找不到剛下載的檔案。"
                    continue
                fi
            else
                echo "   ❌ 下載失敗。"
                continue
            fi
            sleep 1
        fi
        
        # --- 轉檔檢查 ---
        if [ "$CAN_CONVERT" = true ] && [ -n "$current_epub" ]; then
            pdf_file="${current_epub%.epub}.pdf"
            
            if [ -f "$pdf_file" ]; then
                echo "   ⏭️  [PDF 已存在] 跳過"
            else
                echo "   ⚙️  [轉換 PDF] 轉換中..."
                "$CONVERTER" "$current_epub" "$pdf_file" > /dev/null
                if [ $? -eq 0 ]; then
                    echo "   ✅ 轉換完成"
                else
                    echo "   ❌ 轉換失敗"
                fi
            fi
        fi
        echo "---------------------------------------------------"
    fi
done <<< "$REMOTE_LIST"

echo "🎉 作業結束！"
exit 0