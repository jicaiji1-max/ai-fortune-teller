#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
病理图像自动细胞分析系统
功能：自动识别红细胞、白细胞，并在图像上标注

依赖安装：
pip install opencv-python numpy matplotlib pillow

使用方法：
python pathology-cell-analyzer.py your_image.png
"""

import cv2
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont
import sys
import os
from pathlib import Path

# ==================== 配置参数 ====================

# 细胞检测参数
DETECTION_PARAMS = {
    'min_area': 50,           # 最小细胞面积（像素）
    'max_area': 5000,         # 最大细胞面积（像素）
    'min_circularity': 0.5,   # 最小圆度
    'blur_kernel': 5,         # 高斯模糊核大小
    'adaptive_block_size': 11, # 自适应阈值块大小
    'adaptive_c': 2,          # 自适应阈值常数
}

# 细胞分类参数
CLASSIFICATION_PARAMS = {
    'red_blood_cell_max_area': 600,      # 红细胞最大面积
    'red_blood_cell_min_area': 30,       # 红细胞最小面积
    'white_blood_cell_min_area': 600,    # 白细胞最小面积
    'white_blood_cell_max_area': 5000,   # 白细胞最大面积
    'white_blood_cell_min_nucleus_ratio': 0.15,  # 白细胞核质比最小值
}

# 标注颜色
COLORS = {
    'red_blood_cell': (255, 0, 0, 200),      # 红色（半透明）
    'white_blood_cell': (0, 255, 0, 200),    # 绿色（半透明）
    'other': (0, 0, 255, 200),               # 蓝色（半透明）
    'text': (255, 255, 255),                  # 白色文字
    'border': (255, 255, 0),                  # 黄色边框
}

# ==================== 细胞检测函数 ====================

def detect_cells(image_path):
    """
    检测图像中的细胞
    
    参数:
        image_path: 图像文件路径
    
    返回:
        cells: 细胞列表，每个细胞包含 {contour, area, center, type}
    """
    print(f"📷 加载图像：{image_path}")
    
    # 读取图像
    img = cv2.imread(str(image_path))
    if img is None:
        raise ValueError(f"无法加载图像：{image_path}")
    
    original = img.copy()
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
    print(f"   图像尺寸：{img.shape[1]} x {img.shape[0]}")
    
    # 预处理
    # 1. 高斯模糊
    blurred = cv2.GaussianBlur(gray, (DETECTION_PARAMS['blur_kernel'], 
                                       DETECTION_PARAMS['blur_kernel']), 0)
    
    # 2. 自适应阈值
    thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                    cv2.THRESH_BINARY_INV, 
                                    DETECTION_PARAMS['adaptive_block_size'],
                                    DETECTION_PARAMS['adaptive_c'])
    
    # 3. 形态学操作
    kernel = np.ones((3,3), np.uint8)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel, iterations=2)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel, iterations=1)
    
    # 查找轮廓
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, 
                                    cv2.CHAIN_APPROX_SIMPLE)
    
    print(f"   检测到 {len(contours)} 个轮廓")
    
    # 过滤和分类细胞
    cells = []
    for i, contour in enumerate(contours):
        # 计算面积
        area = cv2.contourArea(contour)
        
        # 过滤面积
        if area < DETECTION_PARAMS['min_area'] or area > DETECTION_PARAMS['max_area']:
            continue
        
        # 计算圆度
        perimeter = cv2.arcLength(contour, True)
        if perimeter == 0:
            continue
        circularity = 4 * np.pi * (area / (perimeter * perimeter))
        
        if circularity < DETECTION_PARAMS['min_circularity']:
            continue
        
        # 计算中心点
        M = cv2.moments(contour)
        if M['m00'] == 0:
            continue
        cx = int(M['m10'] / M['m00'])
        cy = int(M['m01'] / M['m00'])
        
        # 细胞分类
        cell_type = classify_cell(area, circularity, gray, contour)
        
        cells.append({
            'contour': contour,
            'area': area,
            'center': (cx, cy),
            'type': cell_type,
            'circularity': circularity
        })
    
    print(f"   识别到 {len(cells)} 个细胞")
    
    return original, cells

def classify_cell(area, circularity, img, contour):
    """
    细胞分类 - 基于面积、形状和细胞核特征
    
    参数:
        area: 细胞面积
        circularity: 圆度
        img: 原始图像
        contour: 细胞轮廓
    
    返回:
        cell_type: 'red_blood_cell', 'white_blood_cell', 或 'other'
    """
    # 首先根据面积初步判断
    if area < CLASSIFICATION_PARAMS['red_blood_cell_min_area']:
        return 'other'  # 太小，可能是杂质
    
    # 检查是否有细胞核（白细胞的关键特征）
    has_nucleus = detect_nucleus(img, contour)
    
    # 白细胞：面积大 + 有细胞核
    if (area >= CLASSIFICATION_PARAMS['white_blood_cell_min_area'] and 
        area < CLASSIFICATION_PARAMS['white_blood_cell_max_area'] and
        has_nucleus):
        return 'white_blood_cell'
    
    # 红细胞：面积小 + 无核 + 较圆
    if (CLASSIFICATION_PARAMS['red_blood_cell_min_area'] <= area < 
        CLASSIFICATION_PARAMS['red_blood_cell_max_area'] and
        circularity > 0.5):
        return 'red_blood_cell'
    
    # 其他
    return 'other'

def detect_nucleus(img, contour):
    """
    检测细胞核（白细胞特征）
    
    白细胞有明显细胞核，红细胞没有
    
    参数:
        img: 原始图像（BGR 或灰度）
        contour: 细胞轮廓
    
    返回:
        has_nucleus: 是否有细胞核
    """
    # 如果是灰度图，用强度检测
    if len(img.shape) == 2:
        # 创建掩膜
        mask = np.zeros(img.shape, dtype=np.uint8)
        cv2.drawContours(mask, [contour], -1, 255, -1)
        
        # 获取细胞区域的像素
        cell_pixels = img[mask == 255]
        
        if len(cell_pixels) == 0:
            return False
        
        # 白细胞核通常更暗
        # 计算强度标准差，有核的细胞强度变化大
        std_dev = np.std(cell_pixels)
        
        # 经验阈值
        return std_dev > 30
    
    # 如果是彩色图，用颜色检测
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    
    # 创建掩膜
    mask = np.zeros(img.shape[:2], dtype=np.uint8)
    cv2.drawContours(mask, [contour], -1, 255, -1)
    
    # 白细胞核通常呈深紫色/蓝色
    lower_purple = np.array([100, 50, 50])
    upper_purple = np.array([160, 255, 200])
    
    # 阈值分割
    nucleus_mask = cv2.inRange(hsv, lower_purple, upper_purple)
    nucleus_mask = cv2.bitwise_and(nucleus_mask, nucleus_mask, mask=mask)
    
    # 计算细胞核面积比例
    cell_area = cv2.contourArea(contour)
    if cell_area == 0:
        return False
    
    nucleus_area = cv2.countNonZero(nucleus_mask)
    nucleus_ratio = nucleus_area / cell_area
    
    # 如果核质比大于阈值，认为有细胞核
    return nucleus_ratio > CLASSIFICATION_PARAMS['white_blood_cell_min_nucleus_ratio']

# ==================== 标注函数 ====================

def annotate_image(img, cells, output_path=None):
    """
    在图像上标注细胞
    
    参数:
        img: 原始图像
        cells: 细胞列表
        output_path: 输出文件路径
    
    返回:
        annotated_img: 标注后的图像
    """
    # 转换为 PIL Image
    img_pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)
    
    # 统计
    stats = {
        'red_blood_cell': 0,
        'white_blood_cell': 0,
        'other': 0
    }
    
    # 标注每个细胞
    for cell in cells:
        contour = cell['contour']
        cell_type = cell['type']
        stats[cell_type] += 1
        
        # 获取颜色
        color = COLORS[cell_type]
        
        # 绘制轮廓
        contour_list = [(int(pt[0][0]), int(pt[0][1])) for pt in contour]
        if len(contour_list) > 2:
            draw.polygon(contour_list, outline=color[:3], width=2)
            # 半透明填充
            overlay = Image.new('RGBA', img_pil.size, (0, 0, 0, 0))
            overlay_draw = ImageDraw.Draw(overlay)
            overlay_draw.polygon(contour_list, fill=color)
            img_pil = Image.alpha_composite(img_pil.convert('RGBA'), overlay)
            draw = ImageDraw.Draw(img_pil)
        
        # 标注中心点
        cx, cy = cell['center']
        draw.ellipse([(cx-3, cy-3), (cx+3, cy+3)], fill=COLORS['text'])
    
    # 添加统计信息
    h, w = img.shape[:2]
    text_y = 30
    text_x = 20
    
    # 背景
    draw.rectangle([(0, 0), (w, text_y * 6)], fill=(0, 0, 0, 180))
    
    # 标题
    draw.text((text_x, 10), "病理图像细胞分析", fill=COLORS['text'], 
              font=ImageFont.load_default())
    
    # 统计
    draw.text((text_x, text_y + 5), f"🔴 红细胞：{stats['red_blood_cell']}", 
              fill=(255, 100, 100))
    draw.text((text_x, text_y * 2 + 5), f"⚪ 白细胞：{stats['white_blood_cell']}", 
              fill=(100, 255, 100))
    draw.text((text_x, text_y * 3 + 5), f"⚫ 其他细胞：{stats['other']}", 
              fill=(100, 100, 255))
    draw.text((text_x, text_y * 4 + 5), f"总细胞数：{len(cells)}", 
              fill=COLORS['text'])
    
    if len(cells) > 0:
        rbc_percent = stats['red_blood_cell'] / len(cells) * 100
        wbc_percent = stats['white_blood_cell'] / len(cells) * 100
        draw.text((text_x, text_y * 5 + 5), 
                  f"红细胞比例：{rbc_percent:.1f}% | 白细胞比例：{wbc_percent:.1f}%", 
                  fill=COLORS['text'])
    
    # 转换回 OpenCV 格式
    annotated_img = cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)
    
    # 保存
    if output_path:
        cv2.imwrite(str(output_path), annotated_img)
        print(f"✅ 标注图像已保存：{output_path}")
    
    return annotated_img, stats

# ==================== 报告生成 ====================

def generate_report(stats, cells, output_path):
    """
    生成分析报告
    
    参数:
        stats: 统计数据
        cells: 细胞列表
        output_path: 输出文件路径
    """
    total = len(cells)
    rbc_percent = stats['red_blood_cell'] / total * 100 if total > 0 else 0
    wbc_percent = stats['white_blood_cell'] / total * 100 if total > 0 else 0
    
    report = f"""
病理图像细胞分析报告
====================
生成时间：{__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

细胞计数结果
------------
🔴 红细胞数量：{stats['red_blood_cell']}
⚪ 白细胞数量：{stats['white_blood_cell']}
⚫ 其他细胞数量：{stats['other']}
总细胞数：{total}

细胞比例
--------
红细胞比例：{rbc_percent:.2f}%
白细胞比例：{wbc_percent:.2f}%

详细数据
--------
"""
    
    # 添加每个细胞的详细信息
    report += "细胞 ID,类型，面积 (像素),圆度，中心 X,中心 Y\n"
    for i, cell in enumerate(cells):
        report += f"{i+1},{cell['type']},{cell['area']:.1f},{cell['circularity']:.2f},{cell['center'][0]},{cell['center'][1]}\n"
    
    # 保存报告
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"📄 报告已保存：{output_path}")

# ==================== 主程序 ====================

def main():
    """主程序入口"""
    print("=" * 60)
    print("病理图像自动细胞分析系统")
    print("=" * 60)
    
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("\n使用方法：")
        print("  python pathology-cell-analyzer.py <图像文件>")
        print("\n示例：")
        print("  python pathology-cell-analyzer.py pathology_image.png")
        sys.exit(1)
    
    image_path = Path(sys.argv[1])
    
    if not image_path.exists():
        print(f"❌ 错误：文件不存在 - {image_path}")
        sys.exit(1)
    
    # 创建输出目录
    output_dir = Path('results')
    output_dir.mkdir(exist_ok=True)
    
    # 检测细胞
    img, cells = detect_cells(image_path)
    
    # 标注图像
    annotated_path = output_dir / f"annotated_{image_path.name}"
    annotated_img, stats = annotate_image(img, cells, annotated_path)
    
    # 生成报告
    report_path = output_dir / f"report_{image_path.stem}.txt"
    generate_report(stats, cells, report_path)
    
    # 生成 CSV
    csv_path = output_dir / f"cells_{image_path.stem}.csv"
    import csv
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['ID', '类型', '面积', '圆度', '中心 X', '中心 Y'])
        for i, cell in enumerate(cells):
            writer.writerow([i+1, cell['type'], f"{cell['area']:.1f}", 
                           f"{cell['circularity']:.2f}", 
                           cell['center'][0], cell['center'][1]])
    print(f"📊 CSV 已保存：{csv_path}")
    
    # 显示统计
    print("\n" + "=" * 60)
    print("📊 细胞统计")
    print("=" * 60)
    print(f"🔴 红细胞：{stats['red_blood_cell']}")
    print(f"⚪ 白细胞：{stats['white_blood_cell']}")
    print(f"⚫ 其他细胞：{stats['other']}")
    print(f"总细胞数：{len(cells)}")
    if len(cells) > 0:
        print(f"红细胞比例：{stats['red_blood_cell']/len(cells)*100:.1f}%")
        print(f"白细胞比例：{stats['white_blood_cell']/len(cells)*100:.1f}%")
    print("=" * 60)
    print("\n✅ 分析完成！")
    
    # 显示结果（可选）
    # plt.figure(figsize=(15, 10))
    # plt.imshow(cv2.cvtColor(annotated_img, cv2.COLOR_BGR2RGB))
    # plt.axis('off')
    # plt.tight_layout()
    # plt.savefig(output_dir / f"display_{image_path.name}", dpi=150)
    # print(f"🖼️ 显示图像已保存：{output_dir / f'display_{image_path.name}'}")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"\n❌ 错误：{e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
