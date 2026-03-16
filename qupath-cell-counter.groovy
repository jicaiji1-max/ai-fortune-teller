// QuPath 自动细胞计数脚本
// 功能：自动识别和计数红细胞、白细胞
// 保存为：cell_counter.groovy
// 使用方法：在 QuPath 中打开图像 → 运行此脚本

import qupath.lib.images.servers.ImageServer
import qupath.lib.objects.PathCellObject
import qupath.lib.roi.ROIs
import qupath.lib.regions.RegionRequest
import java.awt.image.BufferedImage
import ij.IJ
import ij.process.ImageProcessor
import ij.plugin.filter.ParticleAnalyzer
import ij.measure.ResultsTable

// ==================== 配置参数 ====================

// 细胞检测参数
def params = [
    pixelSize: 0.5,              // 像素大小 (μm)
    backgroundRadius: 8.0,       // 背景半径
    medianRadius: 0.0,           // 中值滤波半径
    sigma: 1.5,                  // 高斯平滑 sigma
    minArea: 10.0,               // 最小面积 (μm²)
    maxArea: 500.0,              // 最大面积 (μm²)
    threshold: 0.1,              // 检测阈值
    cellExpansion: 5.0,          // 细胞扩展
    includeNuclei: true          // 包含细胞核
]

// 细胞分类参数
def classificationParams = [
    redBloodCellMaxArea: 50.0,   // 红细胞最大面积
    redBloodCellMinIntensity: 100, // 红细胞最小强度
    whiteBloodCellMinArea: 50.0  // 白细胞最小面积
]

// ==================== 主程序 ====================

println "=" * 60
println "QuPath 自动细胞计数系统"
println "=" * 60

// 获取当前图像
def imageData = getCurrentImageData()
def server = imageData.getServer()

println "\n📷 图像信息:"
println "   名称：${getImageName()}"
println "   尺寸：${server.getWidth()} x ${server.getHeight()}"
println "   像素大小：${server.getPixelCalibration().pixelWidth} μm"

// 运行细胞检测
println "\n🔍 开始检测细胞..."
def detections = detectCells(imageData, params)
println "✅ 检测到 ${detections.size()} 个细胞"

// 细胞分类
println "\n🔬 开始细胞分类..."
def redBloodCells = []
def whiteBloodCells = []
def otherCells = []

for (cell in detections) {
    def area = cell.getROI().getArea()
    def intensity = cell.getMeasurementList().getMeasurementValue('Nucleus: Mean') ?: 0
    
    // 根据面积和强度分类
    if (area < classificationParams.redBloodCellMaxArea && intensity > classificationParams.redBloodCellMinIntensity) {
        // 红细胞：面积小，强度高
        redBloodCells << cell
        cell.setPathClass(getPathClass('Red Blood Cell'))
    } else if (area >= classificationParams.whiteBloodCellMinArea) {
        // 白细胞：面积大
        whiteBloodCells << cell
        cell.setPathClass(getPathClass('White Blood Cell'))
    } else {
        // 其他细胞
        otherCells << cell
        cell.setPathClass(getPathClass('Other'))
    }
}

// 添加检测结果到图像
println "\n📌 添加检测结果到图像..."
addObjects(detections)

// 统计结果
println "\n" + "=" * 60
println "📊 细胞统计报告"
println "=" * 60
println "图像名称：${getImageName()}"
println "-" * 60
println "🔴 红细胞数量：${redBloodCells.size()}"
println "⚪ 白细胞数量：${whiteBloodCells.size()}"
println "⚫ 其他细胞数量：${otherCells.size()}"
println "-" * 60
println "总细胞数：${detections.size()}"

if (detections.size() > 0) {
    println "红细胞比例：${(redBloodCells.size()/detections.size()*100).round(2)}%"
    println "白细胞比例：${(whiteBloodCells.size()/detections.size()*100).round(2)}%"
}
println "=" * 60

// 导出结果
def outputPath = buildFilePath(PROJECT_BASE_DIR, 'results')
mkdirs(outputPath)

// 导出 CSV
def csvPath = buildFilePath(outputPath, 'cell_counts_${getImageName()}.csv')
def csv = new StringBuilder()
csv << 'Image,Red Blood Cells,White Blood Cells,Other Cells,Total,RBC %,WBC %\n'
def rbcPercent = detections.size() > 0 ? (redBloodCells.size()/detections.size()*100).round(2) : 0
def wbcPercent = detections.size() > 0 ? (whiteBloodCells.size()/detections.size()*100).round(2) : 0
csv << "${getImageName()},${redBloodCells.size()},${whiteBloodCells.size()},${otherCells.size()},${detections.size()},${rbcPercent},${wbcPercent}\n"
new File(csvPath).text = csv.toString()
println "\n💾 结果已导出到：${csvPath}"

// 导出统计报告
def reportPath = buildFilePath(outputPath, 'report_${getImageName()}.txt')
def report = """
QuPath 自动细胞计数报告
========================
生成时间：${new Date()}
图像名称：${getImageName()}
图像尺寸：${server.getWidth()} x ${server.getHeight()}

细胞计数结果
------------
🔴 红细胞数量：${redBloodCells.size()}
⚪ 白细胞数量：${whiteBloodCells.size()}
⚫ 其他细胞数量：${otherCells.size()}
总细胞数：${detections.size()}

细胞比例
--------
红细胞比例：${rbcPercent}%
白细胞比例：${wbcPercent}%

检测参数
--------
像素大小：${params.pixelSize} μm
最小面积：${params.minArea} μm²
最大面积：${params.maxArea} μm²
检测阈值：${params.threshold}
"""
new File(reportPath).text = report
println "📄 报告已保存到：${reportPath}"

// 导出标注图像（可选）
// println "\n🖼️ 导出标注图像..."
// def annotationPath = buildFilePath(outputPath, 'annotated_${getImageName()}.png')
// writeImageAnnotation(annotationPath, true)
// println "标注图像已导出到：${annotationPath}"

println "\n✅ 细胞计数完成！"
println "=" * 60

// ==================== 细胞检测函数 ====================

def detectCells(imageData, params) {
    def server = imageData.getServer()
    def detections = []
    
    // 创建检测请求
    def request = RegionRequest.createInstance(
        server,
        params.pixelSize,
        0, 0, server.getWidth(), server.getHeight()
    )
    
    // 获取图像
    BufferedImage img = server.readBufferedImageRegion(request)
    
    // 转换为 ImageJ 格式进行处理
    def ip = ij.IJ.createImage("", "8-bit", img.getWidth(), img.getHeight(), 1)
    ip.getProcessor().copyBits(img.getRaster().getDataBuffer(), new java.awt.Point(0, 0), java.awt.AlphaComposite.SRC)
    
    // 应用高斯模糊
    ij.plugin.filter.GaussianBlur gaussianBlur = new ij.plugin.filter.GaussianBlur()
    gaussianBlur.blur(ip, params.sigma)
    
    // 自动阈值
    ip.setAutoThreshold(ij.plugin.filter.ThresholdFinder.DEFAULT_METHOD)
    def threshold = ip.getThreshold()
    
    // 粒子分析
    def rt = new ResultsTable()
    def pa = new ParticleAnalyzer(
        ParticleAnalyzer.ADD_TO_MANAGER | ParticleAnalyzer.EXCLUDE_EDGE_PARTICLES,
        ParticleAnalyzer.AREA,
        rt,
        params.minArea,
        params.maxArea
    )
    
    pa.analyze(ij.IJ.createImage("", ip), rt)
    
    // 创建细胞对象
    for (int i = 0; i < rt.getCounter(); i++) {
        def x = rt.getXValue(i)
        def y = rt.getYValue(i)
        def area = rt.getValue(ResultsTable.AREA, i)
        
        def roi = ROIs.createEllipseROI(x - Math.sqrt(area)/2, y - Math.sqrt(area)/2, 
                                        Math.sqrt(area), Math.sqrt(area), 0, null)
        
        def cell = new PathCellObject(roi, null)
        cell.getMeasurementList().putValue('Area', area)
        cell.getMeasurementList().putValue('Nucleus: Mean', ip.getf((int)x, (int)y))
        
        detections << cell
    }
    
    return detections
}
