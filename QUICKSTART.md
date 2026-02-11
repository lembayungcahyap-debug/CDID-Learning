# ⚡ QUICK START GUIDE

## 🎯 3 Langkah Mudah: GitHub → Executor

### **Step 1️⃣: Upload ke GitHub** (5 menit)

1. Login ke **GitHub.com**
2. Klik **New Repository**
   - Name: `LunarV2-CDID`
   - Public ✅
   - Add README ✅
3. Klik **Upload files**
   - Upload: `LunarV2_Refactored.lua`
4. Klik file → Tombol **"Raw"**
5. **Copy URL** yang muncul

---

### **Step 2️⃣: Test di Executor** (2 menit)

1. Buka **Car Driving Indonesia** di Roblox
2. Buka **Executor** (Solara/Wave/Synapse)
3. Paste code ini:

```lua
loadstring(game:HttpGet("PASTE_URL_RAW_KAMU_DISINI"))()
```

4. Klik **Execute**
5. Tunggu **5-10 detik**
6. Tekan **RightControl** untuk toggle UI

---

### **Step 3️⃣: Enjoy!** 🎉

Script sudah jalan! Explore semua features:

- **Home Tab**: Speed, Jump, Teleport
- **Features Tab**: Side Jobs, Vehicle Tools
- **Farming Tab**: Auto Truck Farming
- **Event Tab**: CNY 2025 Features
- **Settings Tab**: Dev Tools

---

## 📌 Example URL

```lua
-- Format URL yang benar:
https://raw.githubusercontent.com/USERNAME/REPO_NAME/main/LunarV2_Refactored.lua

-- Contoh nyata:
https://raw.githubusercontent.com/johndoe/LunarV2-CDID/main/LunarV2_Refactored.lua
```

---

## 🔥 Pro Tips

### Update Script Tanpa Ganti Loader

1. Edit file di GitHub (klik ✏️)
2. Paste code baru
3. Commit
4. User cukup restart script = dapat update!

### Pakai Loader (Recommended)

Upload juga `loader.lua`, lalu pakai:

```lua
loadstring(game:HttpGet("YOUR_URL/loader.lua"))()
```

Loader punya:
- ✅ Error handling lebih baik
- ✅ Executor capability check
- ✅ Retry mechanism
- ✅ Better feedback

---

## 🆘 Troubleshooting Cepat

### "Failed to download"
- Repository tidak Public → Set ke Public
- URL salah → Copy ulang dari tombol Raw

### "HttpGet not available"
- Executor jelek → Pakai Solara/Wave

### "Script tidak muncul"
- Tunggu 10 detik
- Check console (F9) untuk error
- Tekan RightControl

### "Settings tidak save"
- Normal jika executor tidak support writefile
- Features tetap work, cuma reset tiap restart

---

## 📁 Files Overview

| File | Deskripsi | Upload? |
|------|-----------|---------|
| `LunarV2_Refactored.lua` | Main script | ✅ WAJIB |
| `loader.lua` | Advanced loader | ⭐ Recommended |
| `README.md` | Documentation | 📄 Optional |
| `SETUP_GUIDE.md` | Detailed guide | 📄 Optional |

---

## 🎓 Untuk Beginners

**Jika ini pertama kali kamu upload script:**

1. **Baca SETUP_GUIDE.md** - Ada gambar & penjelasan detail
2. **Test di local dulu** - Pastikan script work
3. **Start dengan 1 file** - Upload `LunarV2_Refactored.lua` dulu
4. **Test execute** - Setelah work, baru upload yang lain

---

## 🚀 Advanced: Auto Execute

**Jika executor support autoexec:**

1. Buka folder `autoexec` di executor
2. Buat file: `LunarV2.lua`
3. Paste loadstring
4. Script auto-run tiap join game!

---

## 💡 Need Help?

1. ✅ Baca SETUP_GUIDE.md (lengkap banget!)
2. ✅ Check troubleshooting section
3. ✅ Test dengan executor berbeda
4. ✅ Join Discord (if available)

---

## 📞 Quick Commands

```lua
-- Load langsung
loadstring(game:HttpGet("YOUR_RAW_URL"))()

-- Load dengan loader
loadstring(game:HttpGet("YOUR_RAW_URL/loader.lua"))()

-- Toggle UI
-- Tekan: RightControl
```

---

<div align="center">

**🎉 Selamat mencoba!**

Jika ada masalah, cek **SETUP_GUIDE.md** untuk solusi lengkap.

</div>
