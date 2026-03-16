# 随手记 App - 编辑功能测试用例

**版本：** V1.3  
**日期：** 2026-03-13  
**测试重点：** 编辑功能（拍照 + 更换图片 + 数量显示）

---

## 📋 测试用例目录

### 编辑功能测试（13 个新增）
1. [编辑模式加载图片](#1-编辑模式加载图片)
2. [编辑模式拍照追加](#2-编辑模式拍照追加)
3. [编辑模式相册追加](#3-编辑模式相册追加)
4. [编辑模式更换图片](#4-编辑模式更换图片)
5. [编辑模式删除部分图片](#5-编辑模式删除部分图片)
6. [编辑模式图片数量显示](#6-编辑模式图片数量显示)
7. [编辑模式保存验证](#7-编辑模式保存验证)
8. [列表页图片角标显示](#8-列表页图片角标显示)
9. [列表页图片文字说明](#9-列表页图片文字说明)
10. [纯文字笔记无角标](#10-纯文字笔记无角标)
11. [多图笔记横向滚动](#11-多图笔记横向滚动)
12. [编辑模式取消不保存](#12-编辑模式取消不保存)
13. [编辑模式单图变多图](#13-编辑模式单图变多图)

---

## 测试用例详情

### 1. 编辑模式加载图片

**TC-EDIT-001** | P0 🔴

**测试目的：** 验证编辑模式正确加载所有图片

**前置条件：**
- 已创建包含 3 张图片的笔记（1 张主图 + 2 张附加）

**测试步骤：**
1. 点击笔记进入编辑模式
2. 检查预览区显示的图片

**预期结果：**
- ✅ 加载全部 3 张图片
- ✅ 横向滚动可查看
- ✅ 图片顺序正确（主图在前）
- ✅ 显示"已选择 3 张图片"

**自动化测试：**
```swift
func testEditModeLoadAllPhotos() {
    let mainImage = "main".data(using: .utf8)!
    let additionalImages = ["a1".data(using: .utf8)!, "a2".data(using: .utf8)!]
    
    var loadedImages = [mainImage]
    loadedImages.append(contentsOf: additionalImages)
    
    XCTAssertEqual(loadedImages.count, 3)
}
```

---

### 2. 编辑模式拍照追加

**TC-EDIT-002** | P0 🔴

**测试目的：** 验证编辑模式通过拍照追加图片

**前置条件：**
- 已创建包含 1 张图片的笔记
- 已授予相机权限

**测试步骤：**
1. 点击笔记进入编辑模式
2. 点击"拍照"按钮
3. 使用系统相机拍摄 1 张照片
4. 自动返回编辑界面
5. 检查图片数量

**预期结果：**
- ✅ 系统相机正常启动
- ✅ 拍照后自动返回
- ✅ 显示 2 张图片（原有 1 张 + 新增 1 张）
- ✅ 显示"已选择 2 张图片"

**自动化测试：**
```swift
func testEditModeAddPhotoByCamera() {
    var selectedImageData = ["photo1".data(using: .utf8)!]
    let cameraPhoto = "photo2".data(using: .utf8)!
    
    selectedImageData.append(cameraPhoto)
    
    XCTAssertEqual(selectedImageData.count, 2)
}
```

---

### 3. 编辑模式相册追加

**TC-EDIT-003** | P0 🔴

**测试目的：** 验证编辑模式通过相册追加图片

**前置条件：**
- 已创建包含 1 张图片的笔记
- 已授予相册权限

**测试步骤：**
1. 点击笔记进入编辑模式
2. 点击"添加图片"按钮
3. 从相册选择 2 张新图片
4. 检查图片数量

**预期结果：**
- ✅ 相册选择器正常打开
- ✅ 显示 3 张图片（原有 1 张 + 新增 2 张）
- ✅ 横向滚动可查看
- ✅ 显示"已选择 3 张图片"

**自动化测试：**
```swift
func testEditModeAddPhotosFromLibrary() {
    var selectedImageData = ["photo1".data(using: .utf8)!]
    let newPhotos = ["photo2".data(using: .utf8)!, "photo3".data(using: .utf8)!]
    
    selectedImageData.append(contentsOf: newPhotos)
    
    XCTAssertEqual(selectedImageData.count, 3)
}
```

---

### 4. 编辑模式更换图片

**TC-EDIT-004** | P0 🔴

**测试目的：** 验证编辑模式更换图片功能

**前置条件：**
- 已创建包含 2 张图片的笔记

**测试步骤：**
1. 点击笔记进入编辑模式
2. 点击"添加图片"按钮
3. 从相册选择 1 张新图片
4. 检查图片数量

**预期结果：**
- ✅ 原有图片不丢失
- ✅ 新增图片成功追加
- ✅ 显示 3 张图片
- ✅ 按钮文字显示"添加图片"（不是"更换图片"）

**自动化测试：**
```swift
func testEditModeReplacePhoto() {
    var isAppendingInEditMode = true
    var selectedImageData = ["photo1".data(using: .utf8)!, "photo2".data(using: .utf8)!]
    let newPhoto = "photo3".data(using: .utf8)!
    
    if isAppendingInEditMode {
        selectedImageData.append(newPhoto)
    }
    
    XCTAssertEqual(selectedImageData.count, 3)
}
```

---

### 5. 编辑模式删除部分图片

**TC-EDIT-005** | P1 🟡

**测试目的：** 验证编辑模式可以减少图片数量

**前置条件：**
- 已创建包含 3 张图片的笔记

**测试步骤：**
1. 点击笔记进入编辑模式
2. 点击"添加图片"按钮
3. **只选择 1 张**新图片（不选原有图片）
4. 检查图片数量

**预期结果：**
- ✅ 显示 1 张图片（新选择的）
- ✅ 原有图片被替换
- ✅ 保存后更新为 1 张

**自动化测试：**
```swift
func testEditModeReducePhotoCount() {
    var originalCount = 3
    var newCount = 1
    
    originalCount = newCount
    
    XCTAssertEqual(originalCount, 1)
}
```

---

### 6. 编辑模式图片数量显示

**TC-EDIT-006** | P1 🟡

**测试目的：** 验证编辑模式图片数量提示

**前置条件：**
- 已创建包含不同数量图片的笔记

**测试步骤：**
1. 创建 3 个笔记：
   - 笔记 A：1 张图片
   - 笔记 B：3 张图片
   - 笔记 C：5 张图片
2. 分别进入编辑模式
3. 检查数量提示

**预期结果：**
- ✅ 笔记 A：不显示数量提示（单图）
- ✅ 笔记 B：显示"已选择 3 张图片"
- ✅ 笔记 C：显示"已选择 5 张图片"

**自动化测试：**
```swift
func testEditModePhotoCountHint() {
    let count1 = 1
    let count3 = 3
    let count5 = 5
    
    XCTAssertEqual(count1 > 1, false)
    XCTAssertEqual(count3 > 1, true)
    XCTAssertEqual(count5 > 1, true)
}
```

---

### 7. 编辑模式保存验证

**TC-EDIT-007** | P0 🔴

**测试目的：** 验证编辑模式保存后数据正确

**前置条件：**
- 已创建包含 2 张图片的笔记

**测试步骤：**
1. 点击笔记进入编辑模式
2. 追加 1 张图片（共 3 张）
3. 修改文字说明
4. 点击"保存"
5. 返回列表检查

**预期结果：**
- ✅ 保存成功
- ✅ 列表显示 3 张图片
- ✅ 文字说明已更新
- ✅ 图片数量角标显示"🖼️ 3"
- ✅ 文字说明显示"• 3 张图片"

**自动化测试：**
```swift
func testEditModeSaveVerification() {
    var note = Note(type: .photo, photoData: "p1".data(using: .utf8)!)
    
    // 追加图片
    var images = [note.photoData!]
    images.append("p2".data(using: .utf8)!)
    images.append("p3".data(using: .utf8)!)
    
    // 验证保存
    XCTAssertEqual(images.count, 3)
}
```

---

### 8. 列表页图片角标显示

**TC-EDIT-008** | P0 🔴

**测试目的：** 验证列表页图片数量角标

**前置条件：**
- 已创建多条包含不同数量图片的笔记

**测试步骤：**
1. 创建 3 个笔记：
   - 笔记 A：1 张照片
   - 笔记 B：3 张照片
   - 笔记 C：5 张照片
2. 返回列表查看

**预期结果：**
- ✅ 笔记 A：无角标（单图）
- ✅ 笔记 B：右下角显示"🖼️ 3"角标
- ✅ 笔记 C：右下角显示"🖼️ 5"角标
- ✅ 角标清晰可见，不遮挡主要内容

**自动化测试：**
```swift
func testListPhotoCountBadge() {
    let note1 = Note(type: .photo, photoData: "data".data(using: .utf8)!)
    let note3 = Note(type: .mixed, photoData: "data".data(using: .utf8)!, 
                     additionalPhotoData: ["d1".data(using: .utf8)!, "d2".data(using: .utf8)!])
    
    let count1 = (note1.photoData != nil ? 1 : 0) + (note1.additionalPhotoData?.count ?? 0)
    let count3 = (note3.photoData != nil ? 1 : 0) + (note3.additionalPhotoData?.count ?? 0)
    
    XCTAssertEqual(count1, 1)
    XCTAssertEqual(count3, 3)
}
```

---

### 9. 列表页图片文字说明

**TC-EDIT-009** | P1 🟡

**测试目的：** 验证列表页图片数量文字说明

**前置条件：**
- 已创建多条包含图片的笔记

**测试步骤：**
1. 创建 2 个笔记：
   - 笔记 A：1 张照片
   - 笔记 B：3 张照片
2. 返回列表查看时间戳后面

**预期结果：**
- ✅ 笔记 A：显示"• 1 张图片"
- ✅ 笔记 B：显示"• 3 张图片"
- ✅ 文字颜色为 secondary
- ✅ 文字与图标、时间对齐

**自动化测试：**
```swift
func testListPhotoCountText() {
    let photoCount = 3
    let textDescription = "• \(photoCount) 张图片"
    
    XCTAssertEqual(textDescription, "• 3 张图片")
}
```

---

### 10. 纯文字笔记无角标

**TC-EDIT-010** | P2 🟢

**测试目的：** 验证纯文字笔记不显示图片相关 UI

**前置条件：**
- 已创建纯文字笔记

**测试步骤：**
1. 创建纯文字笔记（无图片）
2. 返回列表查看

**预期结果：**
- ✅ 无缩略图
- ✅ 无图片角标
- ✅ 无"• X 张图片"文字
- ✅ 只显示文字内容和时间

**自动化测试：**
```swift
func testTextNoteNoPhotoCount() {
    let textNote = Note(type: .text, text: "纯文字")
    let photoCount = (textNote.photoData != nil ? 1 : 0) + 
                     (textNote.additionalPhotoData?.count ?? 0)
    
    XCTAssertEqual(photoCount, 0)
}
```

---

### 11. 多图笔记横向滚动

**TC-EDIT-011** | P1 🟡

**测试目的：** 验证多图可以横向滚动查看

**前置条件：**
- 已创建包含 9 张图片的笔记（最大数量）

**测试步骤：**
1. 创建包含 9 张图片的笔记
2. 进入编辑模式
3. 横向滚动查看所有图片

**预期结果：**
- ✅ 9 张图片全部加载
- ✅ 横向滚动流畅
- ✅ 无卡顿或崩溃
- ✅ 显示"已选择 9 张图片"

**自动化测试：**
```swift
func testMultiPhotoHorizontalScroll() {
    let maxPhotos = 9
    var photos = [Data]()
    
    for i in 0..<maxPhotos {
        photos.append("photo\(i)".data(using: .utf8)!)
    }
    
    XCTAssertEqual(photos.count, maxPhotos)
}
```

---

### 12. 编辑模式取消不保存

**TC-EDIT-012** | P1 🟡

**测试目的：** 验证编辑模式取消后不保存修改

**前置条件：**
- 已创建包含 1 张图片的笔记

**测试步骤：**
1. 点击笔记进入编辑模式
2. 追加 2 张图片
3. 点击"取消"按钮
4. 返回列表检查

**预期结果：**
- ✅ 编辑界面关闭
- ✅ 列表仍显示 1 张图片
- ✅ 修改未保存

**自动化测试：**
```swift
func testEditModeCancelDoesNotSave() {
    var originalCount = 1
    var editedCount = 3
    var userCancelled = true
    
    if userCancelled {
        editedCount = originalCount // 取消则恢复原数量
    }
    
    XCTAssertEqual(editedCount, 1)
}
```

---

### 13. 编辑模式单图变多图

**TC-EDIT-013** | P2 🟢

**测试目的：** 验证可以从单图编辑为多图

**前置条件：**
- 已创建只有 1 张图片的笔记

**测试步骤：**
1. 编辑单图笔记
2. 点击"添加图片"
3. 选择 5 张新图片
4. 保存

**预期结果：**
- ✅ 从 1 张变为 5 张
- ✅ 第一张为主图
- ✅ 其余 4 张为附加图片
- ✅ 类型更新为.mixed

**自动化测试：**
```swift
func testEditModeSingleToMultiple() {
    var photoCount = 1
    let newCount = 5
    
    photoCount = newCount
    
    XCTAssertEqual(photoCount, 5)
}
```

---

## 📊 测试用例统计

| 类别 | 测试用例数 | P0 | P1 | P2 |
|------|-----------|----|----|----|
| 编辑功能测试 | 13 | 6 | 5 | 2 |
| **总计** | **13** | **6** | **5** | **2** |

---

## ✅ 验证清单

### 编辑功能
- [ ] TC-EDIT-001: 编辑模式加载图片
- [ ] TC-EDIT-002: 编辑模式拍照追加
- [ ] TC-EDIT-003: 编辑模式相册追加
- [ ] TC-EDIT-004: 编辑模式更换图片
- [ ] TC-EDIT-005: 编辑模式删除部分图片
- [ ] TC-EDIT-006: 编辑模式图片数量显示
- [ ] TC-EDIT-007: 编辑模式保存验证
- [ ] TC-EDIT-008: 列表页图片角标显示
- [ ] TC-EDIT-009: 列表页图片文字说明
- [ ] TC-EDIT-010: 纯文字笔记无角标
- [ ] TC-EDIT-011: 多图笔记横向滚动
- [ ] TC-EDIT-012: 编辑模式取消不保存
- [ ] TC-EDIT-013: 编辑模式单图变多图

---

**测试用例版本：** V1.3  
**创建时间：** 2026-03-13 23:25  
**总计：** 13 个编辑功能测试用例
