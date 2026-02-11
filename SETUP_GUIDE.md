# 📖 LunarV2 - Complete Setup Guide

## 🚀 Step-by-Step: Upload ke GitHub dan Run dengan Executor

### **Part 1: Upload Script ke GitHub**

#### **Langkah 1: Buat Repository Baru**
1. Login ke [GitHub.com](https://github.com)
2. Klik tombol **"+"** di pojok kanan atas → **"New repository"**
3. Isi detail repository:
   - **Repository name**: `LunarV2-CDID` (atau nama lain yang kamu suka)
   - **Description**: `Car Driving Indonesia Script - Refactored Edition`
   - Pilih **Public** (agar bisa diakses via raw link)
   - ✅ Centang **"Add a README file"**
4. Klik **"Create repository"**

#### **Langkah 2: Upload File Script**
1. Di halaman repository yang baru dibuat, klik **"Add file"** → **"Upload files"**
2. Drag & drop file `LunarV2_Refactored.lua` atau klik **"choose your files"**
3. Tunggu upload selesai
4. Di bagian bawah, isi commit message: `Initial commit - Refactored script`
5. Klik **"Commit changes"**

#### **Langkah 3: Dapatkan Raw URL**
1. Klik pada file `LunarV2_Refactored.lua` yang sudah diupload
2. Klik tombol **"Raw"** di pojok kanan atas
3. Copy URL dari address bar (contoh format):
   ```
   https://raw.githubusercontent.com/USERNAME/LunarV2-CDID/main/LunarV2_Refactored.lua
   ```
4. **SIMPAN URL INI** - ini yang akan digunakan untuk load script!

---

### **Part 2: Membuat Loader Script**

Buat file baru bernama `loader.lua` dengan isi:

```lua
--[[
    LunarV2 Loader
    Paste this into your executor
]]

-- Configuration
local SCRIPT_URL = "https://raw.githubusercontent.com/USERNAME/LunarV2-CDID/main/LunarV2_Refactored.lua"
local SCRIPT_NAME = "LunarV2"

-- Loading function with error handling
local function LoadScript()
    print("[" .. SCRIPT_NAME .. "] Starting to load...")
    
    local success, result = pcall(function()
        return game:HttpGet(SCRIPT_URL, true)
    end)
    
    if success then
        print("[" .. SCRIPT_NAME .. "] Script downloaded successfully!")
        
        local executeSuccess, executeError = pcall(function()
            loadstring(result)()
        end)
        
        if executeSuccess then
            print("[" .. SCRIPT_NAME .. "] Script loaded successfully!")
        else
            warn("[" .. SCRIPT_NAME .. "] Execution error:", executeError)
        end
    else
        warn("[" .. SCRIPT_NAME .. "] Failed to download script:", result)
        warn("[" .. SCRIPT_NAME .. "] Make sure the URL is correct and repository is public!")
    end
end

-- Execute
LoadScript()
```

**PENTING**: Ganti `USERNAME` dan `LunarV2-CDID` dengan username GitHub dan nama repository kamu!

Upload file `loader.lua` ini ke repository yang sama.

---

### **Part 3: Cara Menggunakan dengan Executor**

#### **Metode 1: Load Langsung (Recommended)**

Paste code ini ke executor kamu:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/LunarV2-CDID/main/LunarV2_Refactored.lua"))()
```

#### **Metode 2: Pakai Loader (Lebih Aman)**

Paste code ini ke executor kamu:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/LunarV2-CDID/main/loader.lua"))()
```

#### **Metode 3: Auto Execute (Advanced)**

Jika executor kamu support auto-execute folder:

1. Buka folder autoexec di executor kamu (biasanya `workspace/autoexec` atau `autoexec`)
2. Buat file baru: `LunarV2.lua`
3. Paste salah satu code di atas
4. Script akan auto-run setiap kali join game

---

### **Part 4: Testing Script**

#### **Langkah Test:**

1. **Join Game**: Car Driving Indonesia di Roblox
2. **Buka Executor**: (Solara, Wave, Synapse X, dll)
3. **Paste Code Loader**:
   ```lua
   loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()
   ```
4. **Execute**
5. **Cek Console**: Seharusnya muncul pesan:
   ```
   [LunarV2] Successfully loaded! Version 1.0.0
   ```
6. **Tekan RightControl** untuk show/hide UI
7. **Test Fitur**: Coba aktifkan salah satu fitur dari UI

---

### **Part 5: Update Script (Future Updates)**

Ketika ada update:

1. Edit file di GitHub:
   - Buka repository → Klik file → Klik icon **✏️ (Edit)**
   - Paste code baru
   - Commit changes
2. **TIDAK PERLU** ganti URL loader!
3. User tinggal restart script untuk dapat update terbaru

---

## 🔧 Troubleshooting

### **Error: "HttpGet is not available"**
- Executor kamu tidak support http requests
- Solusi: Gunakan executor yang lebih baik (Solara, Wave, Synapse)

### **Error: "Failed to download script"**
- Repository tidak public
- URL salah
- GitHub sedang down
- Solusi: Cek repository settings → pastikan Public

### **Error: "loadstring is not available"**
- Executor tidak support loadstring
- Solusi: Gunakan executor yang support loadstring

### **Script tidak muncul UI**
- Tunggu 5-10 detik setelah execute
- Cek console untuk error messages
- Pastikan game sudah fully loaded
- Tekan RightControl untuk toggle UI

### **Settings tidak tersimpan**
- Executor tidak support filesystem functions
- Beberapa fitur akan tetap work tapi settings reset tiap restart
- Solusi: Gunakan executor dengan writefile/readfile support

---

## 📝 Tips & Best Practices

### **1. Version Control**
Buat branches untuk features baru:
```bash
main (stable)
└── dev (development)
    ├── feature/new-farming
    └── bugfix/teleport-issue
```

### **2. Changelog**
Buat file `CHANGELOG.md` untuk track updates:
```markdown
## [1.0.0] - 2024-XX-XX
### Added
- Modular architecture
- New UI system
- Better error handling

### Fixed
- Truck farming reliability
- Memory leaks
```

### **3. Documentation**
Buat `README.md` yang informatif:
- Features list
- Installation guide
- Screenshots/GIFs
- Support/Discord link

### **4. Security**
- ❌ JANGAN upload executor files
- ❌ JANGAN hardcode sensitive data
- ✅ Gunakan obfuscation untuk private scripts
- ✅ Add license file

---

## 🎯 Quick Start (TL;DR)

```lua
-- Paste ini ke executor, ganti USERNAME dan REPO_NAME:
loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO_NAME/main/LunarV2_Refactored.lua"))()
```

**Done!** 🎉

---

## 📞 Support

Jika ada masalah:
1. Check console untuk error messages
2. Verify URL nya benar
3. Pastikan game dan executor fully loaded
4. Test dengan executor yang berbeda

---

## ⚠️ Disclaimer

Script ini untuk **educational purposes only**. Penggunaan script dapat melanggar Terms of Service Roblox. Use at your own risk!

---

**Made with ❤️ by LunarV2 Team**
