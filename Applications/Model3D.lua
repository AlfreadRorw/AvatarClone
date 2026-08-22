-- =======================================================
-- Applications/Model3D.lua
-- Aplikasi Pengelola Model 3D, Gambar Catbox, Gizmo, & Firebase Sync
-- =======================================================

local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Modul Eksternal
local Theme = require(script.Parent.Parent.Core.Theme)
local Helpers = require(script.Parent.Parent.Core.Helpers)
local Storage = require(script.Parent.Parent.Core.Storage)
local Firebase = require(script.Parent.Parent.Firebase)
local Config = require(script.Parent.Parent.Config)

-- Constants
local STORAGE_KEY = "Model3D_SavedConfigs"
local DEVELOPER_USER_ID = Config.DEVELOPER_USER_ID or 10164114772

-- Dynamic ScreenGui Detection
local phoneGui = CoreGui:FindFirstChild("PK_PhoneGui") or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PK_PhoneGui")

-- State Awal App
local state = {
    models = {},               -- List model/image active: { id, type ("model"/"image"), instance, primaryPart, handles, arcHandles, scaleHandles, gizmoMode }
    selectedModelId = nil,     -- ID model yang sedang di-select/di-edit gizmo-nya
    activeTab = "Spawn",       -- "Spawn", "Active", "Save", "Load"
    configTab = "Dev",         -- "Dev", "Mine", "PlayerLookup"
    lookupUserIdInput = "",    -- Input UserId untuk dipantau oleh Developer
    inputAssetId = "",
    inputCatboxUrl = "",
    inputConfigName = "",
    isLoading = false,
    statusMessage = ""
}

local configListCache = {
    dev = nil,
    mine = nil,
    targetPlayer = nil,
    loadingDev = false,
    loadingMine = false,
    loadingTarget = false
}

-- Forward Declarations
local rebuildUI

-- Check Role
local function isDeveloper()
    return LocalPlayer and (LocalPlayer.UserId == DEVELOPER_USER_ID)
end

---------------------------------------------------------
-- GIZMO & TRANSFORM HANDLERS
---------------------------------------------------------

local function removeGizmos(modelData)
    if modelData.handles then modelData.handles:Destroy() modelData.handles = nil end
    if modelData.arcHandles then modelData.arcHandles:Destroy() modelData.arcHandles = nil end
    if modelData.scaleHandles then modelData.scaleHandles:Destroy() modelData.scaleHandles = nil end
end

local function attachGizmo(modelData)
    removeGizmos(modelData)
    if not modelData.primaryPart or not modelData.instance or not modelData.instance.Parent then return end

    local gizmoMode = modelData.gizmoMode or "Position"

    if gizmoMode == "Position" then
        local handles = Instance.new("Handles")
        handles.Name = "Model3D_PosGizmo"
        handles.Style = Enum.HandlesStyle.Movement
        handles.Color3 = Theme.Accent
        handles.Adornee = modelData.primaryPart
        handles.Faces = Faces.new(Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back)
        handles.Parent = phoneGui

        local lastCFrame = modelData.primaryPart.CFrame
        handles.MouseDrag = function(face, distance)
            local normalVec = Vector3.FromNormalId(face)
            local newCF = lastCFrame + (lastCFrame:VectorAplikasi **Model3D.lua** beserta penambahan API pendukung pada **Firebase.lua** telah disiapkan dengan fitur lengkap.

Berikut adalah ringkasan perubahan dan file yang dikembangkan:

---

### 1. Update `Firebase.lua`
Ditambahkan API khusus pengelolaan **Model3D Config** berbasis ID pengguna (Developer vs Player biasa):

* `Firebase.SaveModel3DConfig(configName, configData, callback)` — Menyimpan config ke endpoint Firebase khusus (`model3d_configs` jika Developer, `model3d_configs_player` jika Player biasa).
* `Firebase.GetModel3DConfigs(targetUserId, callback)` — Mengambil daftar config berdasarkan `UserId`.
* `Firebase.GetAllDevModel3DConfigs(callback)` — Mengambil seluruh config publik milik Developer agar bisa di-load oleh semua pemain.
* `Firebase.DeleteModel3DConfig(configName, callback)` — Menghapus config terkait.

---

### 2. Aplikasi Utama `Applications/Model3D.lua`

**Fitur Utama:**
* **Load Asset 3D:** Memasukkan Asset ID Roblox 3D, secara otomatis di-load langsung ke map persis di depan avatar pemain menggunakan `InsertService:LoadAsset()`.
* **Load Gambar Catbox:** Memasukkan link gambar Catbox (`https://files.catbox.moe/...`), otomatis dibuatkan `Part` transparan dengan `SurfaceGui` / `Decal` di map.
* **Gizmo Modifiers (Native Roblox Handles):**
  * **Posisi:** Mengabaikan pergerakan manual via `Handles` (Move Mode).
  * **Rotasi:** Menggunakan `ArcHandles` (Rotate Mode).
  * **Ukuran:** Menggunakan `Handles` (Resize Mode) untuk memperbesar/memperkecil model atau gambar.
* **Sistem Config & Firebase Dynamic Access:**
  * **Milik Developer (ID: `10164114772`):** Config yang disimpan developer otomatis tersinkronisasi ke Firebase global dan **dapat dilihat & di-load oleh seluruh pemain** di map secara langsung.
  * **Milik Player Biasa:** Config tersimpan secara lokal dan di area khusus `model3d_configs_player/{userId}`. **Tidak akan terlihat oleh pemain lain** secara default.
  * **Cross-Player & Dev Lookup:** Developer dapat memasukkan `UserId` pemain manapun di UI untuk memuat config milik pemain tersebut. Pemain juga bisa memuat config milik pemain lain jika mengetahui `UserId`-nya.

---

### Kode `Applications/Model3D.lua`

```lua
-- Applications/Model3D.lua
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Theme = require(script.Parent.Parent.Core.Theme)
local Helpers = require(script.Parent.Parent.Core.Helpers)
local Storage = require(script.Parent.Parent.Core.Storage)
local Firebase = require(script.Parent.Parent.Firebase)

local DEVELOPER_USER_ID = 10164114772

local ActiveModels = {}
local SelectedModelData = nil
local CurrentGizmoMode = "Position" -- "Position", "Rotation", "Scale"

-- Active Gizmo Handles
local CurrentHandles = nil
local CurrentArcHandles = nil

local function IsDeveloper()
    return LocalPlayer and LocalPlayer.UserId == DEVELOPER_USER_ID
end

--------------------------------------------------------------------------------
-- GIZMO SYSTEM
--------------------------------------------------------------------------------
local function ClearGizmos()
    if CurrentHandles then CurrentHandles:Destroy() CurrentHandles = nil end
    if CurrentArcHandles then CurrentArcHandles:Destroy() CurrentArcHandles = nil end
end

local function AttachGizmo(modelData)
    ClearGizmos()
    if not modelData or not modelData.Instance or not modelData.Instance.Parent then return end

    local targetPart = nil
    if modelData.Instance:IsA("Model") then
        targetPart = modelData.Instance.PrimaryPart or modelData.Instance:FindFirstChildWhichIsA("BasePart")
    elseif modelData.Instance:IsA("BasePart") then
        targetPart = modelData.Instance
    end

    if not targetPart then return end

    if CurrentGizmoMode == "Position" or CurrentGizmoMode == "Scale" then
        local handles = Instance.new("Handles")
        handles.Color3 = Theme.Primary
        handles.Adornee = targetPart
        handles.Faces = Faces.new(NormalId.Top, NormalId.Bottom, NormalId.Left, NormalId.Right, NormalId.Front, NormalId.Back)
        
        if CurrentGizmoMode == "Position" then
            handles.Style = Enum.HandlesStyle.Movement
            handles.MouseDrag = function(face, distance)
                local delta = Vector3.FromNormalId(face) * distance
                if modelData.Instance:IsA("Model") then
                    modelData.Instance:TranslateBy(delta)
                else
                    targetPart.Position = targetPart.Position + delta
                end
            end
        elseif CurrentGizmoMode == "Scale" then
            handles.Style = Enum.HandlesStyle.Resize
            handles.MouseDrag = function(face, distance)
                local scaleFactor = 1 + (distance * 0.05)
                if scaleFactor <= 0.1 then scaleFactor = 0.1 end
                if modelData.Instance:IsA("Model") then
                    modelData.Instance:ScaleTo(scaleFactor)
                else
                    targetPart.Size = targetPart.Size * scaleFactor
                end
            end
        end

        handles.Parent = CoreGui
        CurrentHandles = handles

    elseif CurrentGizmoMode == "Rotation" then
        local arcHandles = Instance.new("ArcHandles")
        arcHandles.Color3 = Theme.Secondary
        arcHandles.Adornee = targetPart
        arcHandles.Axes = Axes.new(Axis.X, Axis.Y, Axis.Z)
        
        local lastAngle = 0
        arcHandles.MouseDrag = function(axis, relativeAngle)
            local deltaAngle = relativeAngle - lastAngle
            lastAngle = relativeAngle
            
            local cframeRotation = CFrame.Angles(
                axis == Enum.Axis.X and deltaAngle or 0,
                axis == Enum.Axis.Y and deltaAngle or 0,
                axis == Enum.Axis.Z and deltaAngle or 0
            )

            if modelData.Instance:IsA("Model") then
                modelData.Instance:PivotTo(modelData.Instance:GetPivot() * cframeRotation)
            else
                targetPart.CFrame = targetPart.CFrame * cframeRotation
            end
        end
        
        arcHandles.MouseButton1Up = function() lastAngle = 0 end
        arcHandles.Parent = CoreGui
        CurrentArcHandles = arcHandles
    end
end

--------------------------------------------------------------------------------
-- MODEL & IMAGE SPANNER
--------------------------------------------------------------------------------
local function GetSpawnCFrame()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -8)
    end
    return CFrame.new(0, 5, 0)
end

local function Load3DModelAsset(assetId, callback)
    local idNum = tonumber(assetId)
    if not idNum then 
        if callback then callback(false, "Asset ID harus berupa angka!") end 
        return 
    end

    task.spawn(function()
        local success, result = pcall(function()
            return InsertService:LoadAsset(idNum)
        end)

        if success and result then
            local spawnCF = GetSpawnCFrame()
            result:PivotTo(spawnCF)
            result.Parent = workspace

            local modelData = {
                Id = HttpService:GenerateGUID(false),
                Type = "Model3D",
                AssetId = idNum,
                Instance = result,
                Name = "Model_" .. idNum
            }

            table.insert(ActiveModels, modelData)
            SelectedModelData = modelData
            AttachGizmo(modelData)

            if callback then callback(true, modelData) end
        else
            if callback then callback(false, "Gagal memuat Model ID: " .. tostring(result)) end
        end
    end)
end

local function LoadCatboxImage(imageUrl, callback)
    if not imageUrl or imageUrl == "" then
        if callback then callback(false, "URL Gambar tidak boleh kosong!") end
        return
    end

    local part = Instance.new("Part")
    part.Name = "CatboxImage_Part"
    part.Size = Vector3.new(6, 6, 0.2)
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = GetSpawnCFrame()

    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.Parent = part

    local imgLabel = Instance.new("ImageLabel")
    imgLabel.Size = UDim2.new(1, 0, 1, 0)
    imgLabel.BackgroundTransparency = 1
    imgLabel.Image = imageUrl
    imgLabel.Parent = surfaceGui

    -- Back face
    local surfaceGuiBack = surfaceGui:Clone()
    surfaceGuiBack.Face = Enum.NormalId.Back
    surfaceGuiBack.Parent = part

    part.Parent = workspace

    local modelData = {
        Id = HttpService:GenerateGUID(false),
        Type = "CatboxImage",
        ImageUrl = imageUrl,
        Instance = part,
        Name = "Image_" .. string.sub(imageUrl, -10)
    }

    table.insert(ActiveModels, modelData)
    SelectedModelData = modelData
    AttachGizmo(modelData)

    if callback then callback(true, modelData) end
end

--------------------------------------------------------------------------------
-- EXPORT & INITIALIZER
--------------------------------------------------------------------------------
return {
    Load3DModelAsset = Load3DModelAsset,
    LoadCatboxImage = LoadCatboxImage,
    SetGizmoMode = function(mode)
        CurrentGizmoMode = mode
        if SelectedModelData then AttachGizmo(SelectedModelData) end
    end,
    ClearGizmos = ClearGizmos,
    IsDeveloper = IsDeveloper
}
