#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
病理图像自动分析系统 - 增强版
功能：
1. 自动判断图像类型（血液涂片 vs 肺组织切片）
2. 根据类型使用不同的分类逻辑
3. 自动细胞检测和计数

依赖安装：
pip install opencv-python numpy matplotlib pillow
"""

import cv2
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont
import sys
import os
from pathlib import Path
from collections import Counter

# ==================== 图像类型判断 ====================

def analyze_image_type(image_path):
    """
    分析图像类型：血液涂片 or 肺组织切片
    
    判断依据：
    1. 血液涂片：分散的圆形细胞，背景干净
    2. 肺组织：有肺泡腔（空腔）+ 肺泡隔（组织结构）
    
    返回:
        image_type: 'blood_smear' or 'lung_tissue'
        confidence: 置信度 (0-1)
        features: 特征字典
    """
    print("🔍 分析图像类型...")
    
    img = cv2.imread(str(image_path))
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    features = {
        'image_size': img.shape,
        'avg_brightness': np.mean(gray),
        'brightness_std': np.std(gray),
    }
    
    # 1. 检测空腔区域（肺泡腔特征）
    # 肺组织有大量空腔（肺泡），血液涂片没有
    _, binary = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    cavity_count = 0
    cavity_area_ratio = 0
    total_area = img.shape[0] * img.shape[1]
    
    for contour in contours:
        area = cv2.contourArea(contour)
        if area > 1000:  # 较大的空腔
            cavity_count += 1
            cavity_area_ratio += area / total_area
    
    features['cavity_count'] = cavity_count
    features['cavity_area_ratio'] = cavity_area_ratio
    
    # 2. 检测细胞密度
    # 血液涂片：细胞分散，密度低
    # 肺组织：细胞密集，形成结构
    cell_contours = detect_cell_contours(gray)
    cell_density = len(cell_contours) / (total_area / 10000)  # 每 10000 像素的细胞数
    features['cell_density'] = cell_density
    
    # 3. 检测组织结构
    # 肺组织有明显的组织结构（肺泡隔）
    edges = cv2.Canny(gray, 50, 150)
    edge_density = np.count_nonzero(edges) / edges.size
    features['edge_density'] = edge_density
    
    # 4. 颜色分析
    # 血液涂片：红色（红细胞）为主
    # 肺组织：粉色/紫色（H&E 染色）
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    red_mask1 = cv2.inRange(hsv, (0, 50, 50), (15, 255, 255))
    red_mask2 = cv2.inRange(hsv, (160, 50, 50), (180, 255, 255))
    red_ratio = (np.count_nonzero(red_mask1) + np.count_nonzero(red_mask2)) / red_mask1.size
    features['red_color_ratio'] = red_ratio
    
    # 判断逻辑
    lung_score = 0
    blood_score = 0
    
    # 有空腔 → 肺组织
    if cavity_count > 5:
        lung_score += 3
    if cavity_area_ratio > 0.2:
        lung_score += 2
    
    # 细胞密度高 → 肺组织
    if cell_density > 5:
        lung_score += 1
    
    # 组织结构明显 → 肺组织
    if edge_density > 0.05:
        lung_score += 2
    
    # 红色比例高 → 血液涂片
    if red_ratio > 0.3:
        blood_score += 3
    
    # 细胞分散 → 血液涂片
    if cell_density < 3:
        blood_score += 2
    
    print(f"   空腔数量：{cavity_count}")
    print(f"   空腔面积比：{cavity_area_ratio:.2%}")
    print(f"   细胞密度：{cell_density:.1f}/10000px²")
    print(f"   边缘密度：{edge_density:.3f}")
    print(f"   红色比例：{red_ratio:.2%}")
    print(f"   肺组织评分：{lung_score}")
    print(f"   血液涂片评分：{blood_score}")
    
    # 判断结果
    if lung_score > blood_score:
        image_type = 'lung_tissue'
        confidence = min(1.0, lung_score / 10.0)
        type_name = "肺组织病理切片"
    else:
        image_type = 'blood_smear'
        confidence = min(1.0, blood_score / 10.0)
        type_name = "血液涂片"
    
    print(f"\n✅ 判断结果：{type_name} (置信度：{confidence:.1%})")
    
    return image_type, confidence, features

def detect_cell_contours(gray):
    """检测细胞轮廓"""
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                    cv2.THRESH_BINARY_INV, 11, 2)
    kernel = np.ones((3,3), np.uint8)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel, iterations=2)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # 过滤小的轮廓
    valid_contours = [c for c in contours if cv2.contourArea(c) > 30]
    return valid_contours

# ==================== 肺组织分析 ====================

def analyze_lung_tissue(image_path):
    """
    分析肺组织病理切片
    
    检测目标：
    1. 肺泡腔（空腔）
    2. 肺泡隔（肺泡壁）
    3. 肺泡上皮细胞（1 型、2 型）
    4. 炎症细胞浸润
    """
    print("\n🫁 分析肺组织...")
    
    img = cv2.imread(str(image_path))
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    results = {
        'alveolar_spaces': [],      # 肺泡腔
        'alveolar_septa': [],       # 肺泡隔
        'type1_cells': [],          # 1 型上皮细胞
        'type2_cells': [],          # 2 型上皮细胞
        'inflammatory_cells': [],   # 炎症细胞
    }
    
    # 1. 检测肺泡腔（大而空的区域）
    print("   检测肺泡腔...")
    _, binary = cv2.threshold(gray, 180, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    for contour in contours:
        area = cv2.contourArea(contour)
        if 500 < area < 50000:  # 肺泡腔大小范围
            perimeter = cv2.arcLength(contour, True)
            if perimeter == 0:
                continue
            circularity = 4 * np.pi * (area / (perimeter * perimeter))
            
            if circularity > 0.3:  # 肺泡腔通常不太规则
                M = cv2.moments(contour)
                if M['m00'] > 0:
                    cx = int(M['m10'] / M['m00'])
                    cy = int(M['m01'] / M['m00'])
                    results['alveolar_spaces'].append({
                        'contour': contour,
                        'area': area,
                        'center': (cx, cy),
                        'circularity': circularity
                    })
    
    print(f"   检测到 {len(results['alveolar_spaces'])} 个肺泡腔")
    
    # 2. 检测细胞（在肺泡隔区域）
    print("   检测细胞...")
    cell_contours = detect_cell_contours(gray)
    
    for contour in cell_contours:
        area = cv2.contourArea(contour)
        perimeter = cv2.arcLength(contour, True)
        if perimeter == 0:
            continue
        circularity = 4 * np.pi * (area / (perimeter * perimeter))
        
        M = cv2.moments(contour)
        if M['m00'] == 0:
            continue
        cx = int(M['m10'] / M['m00'])
        cy = int(M['m01'] / M['m00'])
        
        # 分类细胞
        if area < 100:
            # 小细胞 - 可能是炎症细胞
            results['inflammatory_cells'].append({
                'contour': contour,
                'area': area,
                'center': (cx, cy),
                'type': 'inflammatory'
            })
        elif area < 400:
            # 中等细胞 - 可能是 2 型上皮细胞
            results['type2_cells'].append({
                'contour': contour,
                'area': area,
                'center': (cx, cy),
                'type': 'type2'
            })
        else:
            # 大细胞 - 可能是 1 型上皮细胞
            results['type1_cells'].append({
                'contour': contour,
                'area': area,
                'center': (cx, cy),
                'type': 'type1'
            })
    
    total_cells = (len(results['type1_cells']) + 
                   len(results['type2_cells']) + 
                   len(results['inflammatory_cells']))
    print(f"   检测到 {total_cells} 个细胞")
    print(f"      - 1 型上皮细胞：{len(results['type1_cells'])}")
    print(f"      - 2 型上皮细胞：{len(results['type2_cells'])}")
    print(f"      - 炎症细胞：{len(results['inflammatory_cells'])}")
    
    return img, results

# ==================== 血液涂片分析 ====================

def analyze_blood_smear(image_path):
    """
    分析血液涂片
    
    检测目标：
    1. 红细胞（RBC）
    2. 白细胞（WBC）
    3. 血小板（Platelet）
    """
    print("\n🩸 分析血液涂片...")
    
    img = cv2.imread(str(image_path))
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    results = {
        'rbc': [],        # 红细胞
        'wbc': [],        # 白细胞
        'platelet': [],   # 血小板
    }
    
    # 检测细胞
    cell_contours = detect_cell_contours(gray)
    
    for contour in cell_contours:
        area = cv2.contourArea(contour)
        perimeter = cv2.arcLength(contour, True)
        if perimeter == 0:
            continue
        circularity = 4 * np.pi * (area / (perimeter * perimeter))
        
        M = cv2.moments(contour)
        if M['m00'] == 0:
            continue
        cx = int(M['m10'] / M['m00'])
        cy = int(M['m01'] / M['m00'])
        
        # 分类
        if area < 30:
            # 血小板
            results['platelet'].append({
                'contour': contour,
                'area': area,
                'center': (cx, cy)
            })
        elif 30 <= area < 600 and circularity > 0.5:
            # 红细胞
            results['rbc'].append({
                'contour': contour,
                'area': area,
                'center': (cx, cy),
                'circularity': circularity
            })
        elif area >= 600:
            # 可能是白细胞（需要进一步验证细胞核）
            has_nucleus = detect_nucleus(img, contour)
            if has_nucleus:
                results['wbc'].append({
                    'contour': contour,
                    'area': area,
                    'center': (cx, cy),
                    'has_nucleus': has_nucleus
                })
    
    print(f"   检测到 {len(results['rbc'])} 个红细胞")
    print(f"   检测到 {len(results['wbc'])} 个白细胞")
    print(f"   检测到 {len(results['platelet'])} 个血小板")
    
    return img, results

def detect_nucleus(img, contour):
    """检测细胞核"""
    if len(img.shape) == 2:
        mask = np.zeros(img.shape, dtype=np.uint8)
        cv2.drawContours(mask, [contour], -1, 255, -1)
        cell_pixels = img[mask == 255]
        if len(cell_pixels) == 0:
            return False
        std_dev = np.std(cell_pixels)
        return std_dev > 30
    
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = np.zeros(img.shape[:2], dtype=np.uint8)
    cv2.drawContours(mask, [contour], -1, 255, -1)
    
    lower_purple = np.array([100, 50, 50])
    upper_purple = np.array([160, 255, 200])
    nucleus_mask = cv2.inRange(hsv, lower_purple, upper_purple)
    nucleus_mask = cv2.bitwise_and(nucleus_mask, nucleus_mask, mask=mask)
    
    cell_area = cv2.contourArea(contour)
    if cell_area == 0:
        return False
    
    nucleus_area = cv2.countNonZero(nucleus_mask)
    nucleus_ratio = nucleus_area / cell_area
    return nucleus_ratio > 0.15

# ==================== 标注和报告 ====================

def annotate_and_save(img, image_type, results, output_path):
    """标注图像并保存"""
    print(f"\n💾 保存标注图像到：{output_path}")
    
    img_pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)
    
    # 根据类型选择标注颜色
    if image_type == 'lung_tissue':
        # 肺组织标注
        # 肺泡腔 - 蓝色
        for space in results.get('alveolar_spaces', []):
            contour = [(int(pt[0][0]), int(pt[0][1])) for pt in space['contour']]
            if len(contour) > 2:
                draw.polygon(contour, outline=(0, 0, 255), width=2)
        
        # 1 型细胞 - 红色
        for cell in results.get('type1_cells', []):
            cx, cy = cell['center']
            draw.ellipse([(cx-5, cy-5), (cx+5, cy+5)], fill=(255, 0, 0))
        
        # 2 型细胞 - 绿色
        for cell in results.get('type2_cells', []):
            cx, cy = cell['center']
            draw.ellipse([(cx-3, cy-3), (cx+3, cy+3)], fill=(0, 255, 0))
        
        # 炎症细胞 - 黄色
        for cell in results.get('inflammatory_cells', []):
            cx, cy = cell['center']
            draw.ellipse([(cx-2, cy-2), (cx+2, cy+2)], fill=(255, 255, 0))
        
        # 统计面板
        h, w = img.shape[:2]
        draw.rectangle([(0, 0), (w, 150)], fill=(0, 0, 0, 180))
        draw.text((20, 10), "肺组织病理分析", fill=(255, 255, 255))
        draw.text((20, 35), f"🫁 肺泡腔：{len(results.get('alveolar_spaces', 0))}", fill=(100, 100, 255))
        draw.text((20, 60), f"🔴 1 型上皮细胞：{len(results.get('type1_cells', 0))}", fill=(255, 100, 100))
        draw.text((20, 85), f"🟢 2 型上皮细胞：{len(results.get('type2_cells', 0))}", fill=(100, 255, 100))
        draw.text((20, 110), f"🟡 炎症细胞：{len(results.get('inflammatory_cells', 0))}", fill=(255, 255, 100))
    
    else:
        # 血液涂片标注
        # 红细胞 - 红色
        for cell in results.get('rbc', []):
            cx, cy = cell['center']
            draw.ellipse([(cx-3, cy-3), (cx+3, cy+3)], fill=(255, 0, 0))
        
        # 白细胞 - 绿色
        for cell in results.get('wbc', []):
            cx, cy = cell['center']
            draw.ellipse([(cx-5, cy-5), (cx+5, cy+5)], fill=(0, 255, 0))
        
        # 血小板 - 黄色
        for cell in results.get('platelet', []):
            cx, cy = cell['center']
            draw.ellipse([(cx-2, cy-2), (cx+2, cy+2)], fill=(255, 255, 0))
        
        # 统计面板
        h, w = img.shape[:2]
        draw.rectangle([(0, 0), (w, 120)], fill=(0, 0, 0, 180))
        draw.text((20, 10), "血液涂片分析", fill=(255, 255, 255))
        draw.text((20, 35), f"🔴 红细胞：{len(results.get('rbc', 0))}", fill=(255, 100, 100))
        draw.text((20, 60), f"⚪ 白细胞：{len(results.get('wbc', 0))}", fill=(100, 255, 100))
        draw.text((20, 85), f"🟡 血小板：{len(results.get('platelet', 0))}", fill=(255, 255, 100))
    
    # 保存
    annotated_img = cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)
    cv2.imwrite(str(output_path), annotated_img)

def generate_report(image_type, results, output_path):
    """生成文本报告"""
    print(f"📄 生成报告：{output_path}")
    
    report = f"""
病理图像分析报告
================
生成时间：{__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
图像类型：{'肺组织病理切片' if image_type == 'lung_tissue' else '血液涂片'}

"""
    
    if image_type == 'lung_tissue':
        report += f"""肺组织分析结果
------------------
🫁 肺泡腔数量：{len(results.get('alveolar_spaces', []))}
🔴 1 型上皮细胞：{len(results.get('type1_cells', []))}
🟢 2 型上皮细胞：{len(results.get('type2_cells', []))}
🟡 炎症细胞：{len(results.get('inflammatory_cells', []))}

"""
    else:
        report += f"""血液涂片分析结果
------------------
🔴 红细胞：{len(results.get('rbc', []))}
⚪ 白细胞：{len(results.get('wbc', []))}
🟡 血小板：{len(results.get('platelet', []))}

"""
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report)

# ==================== 主程序 ====================

def main():
    """主程序入口"""
    print("=" * 60)
    print("病理图像自动分析系统 - 增强版")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("\n使用方法：")
        print("  python pathology_analyzer_v2.py <图像文件>")
        sys.exit(1)
    
    image_path = Path(sys.argv[1])
    
    if not image_path.exists():
        print(f"❌ 错误：文件不存在 - {image_path}")
        sys.exit(1)
    
    # 创建输出目录
    output_dir = Path('results')
    output_dir.mkdir(exist_ok=True)
    
    # 1. 判断图像类型
    image_type, confidence, features = analyze_image_type(image_path)
    
    # 2. 根据类型分析
    if image_type == 'lung_tissue':
        img, results = analyze_lung_tissue(image_path)
    else:
        img, results = analyze_blood_smear(image_path)
    
    # 3. 保存结果
    base_name = image_path.stem
    annotate_path = output_dir / f"annotated_{base_name}.jpg"
    report_path = output_dir / f"report_{base_name}.txt"
    
    annotate_and_save(img, image_type, results, annotate_path)
    generate_report(image_type, results, report_path)
    
    # 4. 显示统计
    print("\n" + "=" * 60)
    print("✅ 分析完成！")
    print("=" * 60)
    print(f"标注图像：{annotate_path}")
    print(f"分析报告：{report_path}")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"\n❌ 错误：{e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
