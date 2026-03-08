// 在 OpenClaw 页面上注入监控面板（无闪烁刷新 + 可调整大小）

(function() {
  'use strict';
  
  // 保存展开状态
  var expandedStates = {};
  
  // Agent 中文名字映射（默认映射，如果 API 返回了中文名字则使用 API 的）
  const DEFAULT_AGENT_CN_NAMES = {
    'main': '主助手',
    'programmer': '代码助手',
    'product-manager': '产品小助手',
    'project-manager': '项目总负责人'
  };
  
  // 创建样式
  const style = document.createElement('style');
  style.textContent = `
    #openclaw-monitor-panel {
      position: fixed;
      top: 80px;
      right: 20px;
      width: 420px;
      height: 300px;
      max-height: 600px;
      min-width: 350px;
      min-height: 200px;
      background: #1a1a24;
      border: 1px solid #2a2a3a;
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
      z-index: 999999;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      overflow: hidden;
      cursor: move;
    }
    .monitor-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      background: #13131a;
      border-bottom: 1px solid #2a2a3a;
    }
    .monitor-title {
      font-size: 14px;
      font-weight: 600;
      color: #e4e4e7;
    }
    .monitor-toggle {
      width: 24px;
      height: 24px;
      border: none;
      background: #2a2a3a;
      color: #a1a1aa;
      border-radius: 6px;
      cursor: pointer;
      font-size: 16px;
      line-height: 1;
    }
    .monitor-toggle:hover {
      background: #3a3a4a;
      color: #fff;
    }
    .monitor-content {
      max-height: calc(600px - 50px);
      overflow-y: auto;
    }
    .monitor-body {
      padding: 16px;
      background: #0a0a0f;
      color: #e4e4e7;
      font-size: 13px;
    }
    .section { margin-bottom: 16px; }
    .section-title {
      font-size: 11px;
      font-weight: 600;
      color: #71717a;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 8px;
    }
    .hint {
      font-size: 10px;
      color: #6b7280;
      margin-bottom: 12px;
      padding: 8px;
      background: #13131a;
      border-radius: 6px;
      font-style: italic;
      border-left: 3px solid #6366f1;
    }
    .agent-card {
      background: #13131a;
      border: 1px solid #2a2a3a;
      border-radius: 8px;
      margin-bottom: 8px;
      overflow: hidden;
      transition: all 0.2s;
    }
    .agent-card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 16px;
      background: #1a1a24;
      cursor: pointer;
      transition: background 0.2s;
    }
    .agent-card-header:hover {
      background: #222230;
    }
    .agent-info {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .agent-name {
      font-weight: 600;
      font-size: 14px;
    }
    .agent-cn-name {
      font-size: 12px;
      color: #71717a;
      font-weight: normal;
    }
    .agent-status {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      animation: pulse 2s infinite;
    }
    .status-dot.running { background: #10b981; box-shadow: 0 0 8px #10b981; }
    .status-dot.idle { background: #f59e0b; box-shadow: 0 0 8px #f59e0b; }
    .status-dot.aborted { background: #ef4444; box-shadow: 0 0 8px #ef4444; animation: none; }
    .status-dot.no-sessions { background: #6b7280; box-shadow: none; animation: none; }
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.5; }
    }
    .model-badge {
      background: #6366f1;
      color: #fff;
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 10px;
    }
    .status-badge {
      padding: 2px 8px;
      border-radius: 4px;
      font-size: 10px;
    }
    .status-badge.running { background: #10b981; color: #fff; }
    .status-badge.idle { background: #f59e0b; color: #fff; }
    .status-badge.aborted { background: #ef4444; color: #fff; }
    .status-badge.no-sessions { background: #6b7280; color: #fff; }
    .expand-icon {
      color: #71717a;
      font-size: 12px;
      margin-left: 8px;
    }
    .agent-details {
      padding: 12px 16px;
      font-size: 11px;
      color: #a1a1aa;
      background: #0f0f16;
    }
    .detail-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
      padding: 8px 12px;
      border-radius: 6px;
      transition: background 0.2s;
    }
    .detail-row.clickable {
      cursor: pointer;
    }
    .detail-row.clickable:hover {
      background: #1a1a24;
    }
    .detail-row:last-child {
      margin-bottom: 0;
    }
    .detail-label { color: #71717a; }
    .detail-value { color: #e4e4e7; font-weight: 500; }
    .detail-value.clickable {
      color: #6366f1;
      cursor: pointer;
    }
    .detail-value.clickable:hover {
      color: #818cf8;
    }
    .context-bar {
      height: 4px;
      background: #2a2a3a;
      border-radius: 2px;
      margin-top: 0;
      overflow: hidden;
      width: 80px;
      flex-shrink: 0;
    }
    .context-fill {
      height: 100%;
      border-radius: 2px;
      transition: width 0.3s;
    }
    .context-fill.low { background: #10b981; }
    .context-fill.medium { background: #f59e0b; }
    .context-fill.high { background: #ef4444; }
    .loading { color: #71717a; text-align: center; padding: 20px; }
    .error { color: #ef4444; text-align: center; padding: 20px; font-size: 11px; }
    .refresh-btn {
      display: block;
      width: 100%;
      padding: 8px;
      margin-top: 8px;
      background: #10b981;
      color: #fff;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
    }
    .refresh-btn:hover { background: #059669; }
    .session-list {
      margin-top: 8px;
      padding: 8px;
      background: #13131a;
      border-radius: 6px;
      border: 1px solid #2a2a3a;
      max-height: 200px;
      overflow-y: auto;
    }
    .session-item {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      padding: 8px;
      margin-bottom: 4px;
      font-size: 10px;
      border-radius: 4px;
      background: #1a1a24;
    }
    .session-item:hover { background: #222230; }
    .session-main {
      flex: 1;
      min-width: 0;
    }
    .session-label { 
      color: #a1a1aa; 
      font-weight: 500;
      margin-bottom: 4px;
      word-break: break-word;
    }
    .session-task {
      color: #6b7280;
      font-size: 9px;
      margin-top: 2px;
      font-style: italic;
    }
    .session-meta {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      gap: 4px;
      margin-left: 8px;
    }
    .session-model {
      color: #6366f1;
      font-size: 9px;
      background: #13131a;
      padding: 2px 4px;
      border-radius: 3px;
    }
    .session-tokens {
      color: #71717a;
      font-size: 9px;
    }
    .session-status {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 9px;
    }
    .status-dot.small {
      width: 6px;
      height: 6px;
    }
    /* 右下角拖拽手柄 */
    .resize-handle-br {
      position: absolute;
      bottom: 0;
      right: 0;
      width: 20px;
      height: 20px;
      cursor: nwse-resize;
      opacity: 0;
      transition: opacity 0.2s;
      z-index: 1000;
    }
    .resize-handle-br:hover {
      opacity: 1;
      background: linear-gradient(135deg, transparent 50%, #6366f1 50%);
      border-radius: 0 0 12px 0;
      box-shadow: -2px -2px 8px rgba(0, 0, 0, 0.3);
    }
    /* 左下角拖拽手柄 */
    .resize-handle-bl {
      position: absolute;
      bottom: 0;
      left: 0;
      width: 20px;
      height: 20px;
      cursor: nesw-resize;
      opacity: 0;
      transition: opacity 0.2s;
      z-index: 1000;
    }
    .resize-handle-bl:hover {
      opacity: 1;
      background: linear-gradient(45deg, transparent 50%, #6366f1 50%);
      border-radius: 0 0 0 12px;
      box-shadow: 2px -2px 8px rgba(0, 0, 0, 0.3);
    }
  `;
  document.head.appendChild(style);
  
  // 会话任务描述映射
  function getSessionTask(session) {
    const label = session.label || session.key || '';
    const key = session.key || '';
    
    if (label.includes('Cron') || key.includes('cron')) {
      return '🕐 定时任务：' + label.replace('Cron: ', '');
    }
    if (label.includes('feishu') || key.includes('feishu')) {
      if (key.includes('group')) {
        return '💬 飞书群聊';
      }
      return '💬 飞书私聊';
    }
    if (label.includes('main') && key.includes('main')) {
      return '🏠 主会话';
    }
    if (key.includes('run:')) {
      return '⚡ 任务执行';
    }
    if (label.includes('topic') || key.includes('topic')) {
      return '📝 话题讨论';
    }
    return '💭 对话会话';
  }
  
  // 创建面板容器
  const panel = document.createElement('div');
  panel.id = 'openclaw-monitor-panel';
  
  // 创建头部
  const header = document.createElement('div');
  header.className = 'monitor-header';
  
  const title = document.createElement('span');
  title.className = 'monitor-title';
  title.textContent = '🤖 OpenClaw Monitor';
  
  const toggleBtn = document.createElement('button');
  toggleBtn.className = 'monitor-toggle';
  toggleBtn.textContent = '−';
  
  header.appendChild(title);
  header.appendChild(toggleBtn);
  
  // 创建内容区
  const content = document.createElement('div');
  content.className = 'monitor-content';
  
  const body = document.createElement('div');
  body.className = 'monitor-body';
  body.innerHTML = '<div class="loading">加载中...</div>';
  
  content.appendChild(body);
  panel.appendChild(header);
  panel.appendChild(content);
  
  // 添加到页面
  document.body.appendChild(panel);
  
  // 实现面板整体拖拽功能（改进灵敏度）
  let isDragging = false;
  let dragOffset = { x: 0, y: 0 };
  let lastMouseX = 0;
  let lastMouseY = 0;
  
  header.addEventListener('mousedown', function(e) {
    isDragging = true;
    lastMouseX = e.clientX;
    lastMouseY = e.clientY;
    const rect = panel.getBoundingClientRect();
    dragOffset.x = e.clientX - rect.left;
    dragOffset.y = e.clientY - rect.top;
    header.style.cursor = 'grabbing';
    e.preventDefault(); // 防止文本选择
  }, { passive: false });
  
  document.addEventListener('mousemove', function(e) {
    if (!isDragging) return;
    
    // 使用增量移动，更灵敏
    const deltaX = e.clientX - lastMouseX;
    const deltaY = e.clientY - lastMouseY;
    lastMouseX = e.clientX;
    lastMouseY = e.clientY;
    
    const currentLeft = parseFloat(panel.style.left) || 0;
    const currentTop = parseFloat(panel.style.top) || 80;
    
    let newLeft = currentLeft + deltaX;
    let newTop = currentTop + deltaY;
    
    // 限制边界
    const panelRect = panel.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;
    
    // 左边界
    if (newLeft < 0) newLeft = 0;
    // 右边界
    if (newLeft + panelRect.width > viewportWidth) newLeft = viewportWidth - panelRect.width;
    // 上边界（允许到顶部，只留 10px）
    if (newTop < 10) newTop = 10;
    // 下边界（允许到底部，只留 10px）
    if (newTop + panelRect.height > viewportHeight - 10) newTop = viewportHeight - 10 - panelRect.height;
    
    panel.style.left = newLeft + 'px';
    panel.style.top = newTop + 'px';
    panel.style.right = 'auto';
  }, { passive: true });
  
  document.addEventListener('mouseup', function() {
    isDragging = false;
    header.style.cursor = 'grab';
  });
  
  // 实现右下角拖拽（改进灵敏度）
  const resizeHandleBR = document.createElement('div');
  resizeHandleBR.className = 'resize-handle-br';
  resizeHandleBR.title = '拖拽调整大小';
  panel.appendChild(resizeHandleBR);
  
  let isResizingBR = false;
  let lastResizeX = 0;
  let lastResizeY = 0;
  
  resizeHandleBR.addEventListener('mousedown', function(e) {
    isResizingBR = true;
    lastResizeX = e.clientX;
    lastResizeY = e.clientY;
    e.preventDefault();
    e.stopPropagation();
  }, { passive: false });
  
  document.addEventListener('mousemove', function(e) {
    if (!isResizingBR) return;
    
    // 使用增量方式，更灵敏
    const deltaX = e.clientX - lastResizeX;
    const deltaY = e.clientY - lastResizeY;
    lastResizeX = e.clientX;
    lastResizeY = e.clientY;
    
    const currentWidth = parseFloat(panel.style.width) || 420;
    const currentHeight = parseFloat(panel.style.height) || 300;
    
    let newWidth = currentWidth + deltaX;
    let newHeight = currentHeight + deltaY;
    
    // 最小尺寸限制
    if (newWidth < 350) newWidth = 350;
    if (newHeight < 200) newHeight = 200;
    
    panel.style.width = newWidth + 'px';
    panel.style.height = newHeight + 'px';
  }, { passive: true });
  
  document.addEventListener('mouseup', function() {
    isResizingBR = false;
  });
  
  // 实现左下角拖拽（改进灵敏度）
  const resizeHandleBL = document.createElement('div');
  resizeHandleBL.className = 'resize-handle-bl';
  resizeHandleBL.title = '拖拽调整大小';
  panel.appendChild(resizeHandleBL);
  
  let isResizingBL = false;
  let lastResizeX_BL = 0;
  let lastResizeY_BL = 0;
  
  resizeHandleBL.addEventListener('mousedown', function(e) {
    isResizingBL = true;
    lastResizeX_BL = e.clientX;
    lastResizeY_BL = e.clientY;
    e.preventDefault();
    e.stopPropagation();
  }, { passive: false });
  
  document.addEventListener('mousemove', function(e) {
    if (!isResizingBL) return;
    
    // 使用增量方式，更灵敏
    const deltaX = e.clientX - lastResizeX_BL;
    const deltaY = e.clientY - lastResizeY_BL;
    lastResizeX_BL = e.clientX;
    lastResizeY_BL = e.clientY;
    
    const currentWidth = parseFloat(panel.style.width) || 420;
    const currentHeight = parseFloat(panel.style.height) || 300;
    const currentLeft = parseFloat(panel.style.left) || 0;
    
    let newWidth = currentWidth - deltaX;
    let newHeight = currentHeight + deltaY;
    let newLeft = currentLeft + deltaX;
    
    // 最小尺寸限制
    if (newWidth < 350) newWidth = 350;
    if (newHeight < 200) newHeight = 200;
    // 左边界限制
    if (newLeft < 0) {
      newWidth += newLeft;
      newLeft = 0;
    }
    
    panel.style.width = newWidth + 'px';
    panel.style.height = newHeight + 'px';
    panel.style.left = newLeft + 'px';
    panel.style.right = 'auto';
  }, { passive: true });
  
  document.addEventListener('mouseup', function() {
    isResizingBL = false;
  });
  
  // 切换展开/收起
  let isExpanded = true;
  toggleBtn.addEventListener('click', function() {
    isExpanded = !isExpanded;
    content.style.display = isExpanded ? 'block' : 'none';
    toggleBtn.textContent = isExpanded ? '−' : '+';
  });
  
  // 格式化 token 数量
  function formatTokens(tokens) {
    if (tokens >= 1000000) return (tokens / 1000000).toFixed(1) + 'M';
    if (tokens >= 1000) return (tokens / 1000).toFixed(1) + 'K';
    return String(tokens);
  }
  
  // 计算 context 占比
  function getContextPercent(used, total) {
    if (!total) return 0;
    return Math.min(100, (used / total) * 100);
  }
  
  // 判断 context 等级
  function getContextLevel(percent) {
    if (percent < 50) return 'low';
    if (percent < 80) return 'medium';
    return 'high';
  }
  
  // 判断 session 状态
  function getSessionStatus(session) {
    if (session.aborted) return 'aborted';
    var fiveMinutesAgo = Date.now() - 5 * 60 * 1000;
    if (session.updatedAt > fiveMinutesAgo) return 'running';
    return 'idle';
  }
  
  // 更新 agent 卡片（不重新创建 DOM，只更新内容）
  function updateAgentCard(card, agent, detailsExpanded, sessionsExpanded) {
    const contextPercent = getContextPercent(agent.totalTokens, agent.contextTokens);
    const contextLevel = getContextLevel(contextPercent);
    
    // 更新卡片头部
    const cardHeader = card.querySelector('.agent-card-header');
    const agentInfo = cardHeader.querySelector('.agent-info');
    const nameContainer = agentInfo.children[0];
    const expandIcon = agentInfo.children[1];
    const status = cardHeader.querySelector('.agent-status');
    
    // 更新名字
    nameContainer.querySelector('.agent-name').textContent = agent.id;
    let cnNameSpan = nameContainer.querySelector('.agent-cn-name');
    const cnName = DEFAULT_AGENT_CN_NAMES[agent.id] || '';
    if (cnName) {
      if (!cnNameSpan) {
        cnNameSpan = document.createElement('span');
        cnNameSpan.className = 'agent-cn-name';
        nameContainer.appendChild(cnNameSpan);
      }
      cnNameSpan.textContent = '（' + cnName + '）';
    } else if (cnNameSpan) {
      cnNameSpan.remove();
    }
    
    // 更新展开图标
    expandIcon.textContent = detailsExpanded ? '▼' : '▶';
    
    // 更新模型徽章
    const badge = status.querySelector('.model-badge');
    badge.textContent = agent.model || '-';
    
    // 更新状态徽章
    const statusBadge = status.querySelector('.status-badge');
    statusBadge.className = 'status-badge ' + agent.status;
    if (agent.status === 'no-sessions') {
      statusBadge.textContent = '无会话';
    } else if (agent.status === 'aborted') {
      statusBadge.textContent = 'aborted';
    } else if (agent.status === 'running') {
      statusBadge.textContent = '运行中';
    } else {
      statusBadge.textContent = '空闲';
    }
    
    // 更新详情区域
    const details = card.querySelector('.agent-details');
    details.style.display = detailsExpanded ? 'block' : 'none';
    
    if (detailsExpanded) {
      // 获取或创建行
      let row1 = details.querySelector('.row-tokens');
      let row2 = details.querySelector('.row-context');
      let bar = details.querySelector('.context-bar');
      let row3 = details.querySelector('.row-sessions');
      let sessionList = details.querySelector('.session-list');
      
      // Tokens 行
      if (!row1) {
        row1 = document.createElement('div');
        row1.className = 'detail-row row-tokens';
        const label = document.createElement('span');
        label.className = 'detail-label';
        label.textContent = '累计 Tokens / Context Window:';
        const value = document.createElement('span');
        value.className = 'detail-value';
        row1.appendChild(label);
        row1.appendChild(value);
        details.appendChild(row1);
      }
      row1.querySelector('.detail-value').textContent = agent.sessions.length === 0 ? '- / -' : formatTokens(agent.totalTokens) + ' / ' + formatTokens(agent.contextTokens);
      
      // Context 使用率行（带进度条）
      if (!row2) {
        row2 = document.createElement('div');
        row2.className = 'detail-row row-context';
        row2.style.display = 'flex';
        row2.style.alignItems = 'center';
        row2.style.gap = '8px';
        const label = document.createElement('span');
        label.className = 'detail-label';
        label.textContent = 'Context:';
        const value = document.createElement('span');
        value.className = 'detail-value';
        bar = document.createElement('div');
        bar.className = 'context-bar';
        const fill = document.createElement('div');
        fill.className = 'context-fill';
        bar.appendChild(fill);
        row2.appendChild(label);
        row2.appendChild(value);
        row2.appendChild(bar);
        details.appendChild(row2);
      }
      row2.querySelector('.detail-value').textContent = agent.sessions.length === 0 ? '-' : contextPercent.toFixed(1) + '%';
      const fill = bar.querySelector('.context-fill');
      fill.className = 'context-fill ' + contextLevel;
      fill.style.width = (agent.sessions.length > 0 ? contextPercent : 0) + '%';
      
      // 会话数量行
      if (!row3) {
        row3 = document.createElement('div');
        row3.className = 'detail-row row-sessions';
        if (agent.sessions.length > 0) {
          row3.classList.add('clickable');
          row3.title = sessionsExpanded ? '收起会话列表' : '展开会话列表';
          row3.addEventListener('click', function(e) {
            e.stopPropagation();
            sessionsExpanded = !sessionsExpanded;
            expandedStates[agent.id] = { details: detailsExpanded, sessions: sessionsExpanded };
            updateAgentCard(card, agent, detailsExpanded, sessionsExpanded);
          });
        } else {
          row3.style.cursor = 'default';
          row3.style.opacity = '0.5';
        }
        const label = document.createElement('span');
        label.className = 'detail-label';
        label.textContent = '会话数量:';
        const valueContainer = document.createElement('div');
        valueContainer.style.display = 'flex';
        valueContainer.style.alignItems = 'center';
        valueContainer.style.gap = '6px';
        const value = document.createElement('span');
        value.className = 'detail-value';
        const expandIcon = document.createElement('span');
        expandIcon.className = 'detail-value clickable';
        const aborted = document.createElement('span');
        aborted.className = 'detail-label';
        valueContainer.appendChild(value);
        valueContainer.appendChild(expandIcon);
        valueContainer.appendChild(aborted);
        row3.appendChild(label);
        row3.appendChild(valueContainer);
        details.appendChild(row3);
      }
      row3.querySelector('.detail-value').textContent = agent.sessions.length;
      row3.querySelectorAll('.detail-value')[1].textContent = sessionsExpanded ? '▼' : '▶';
      const abortedLabel = row3.querySelectorAll('.detail-label')[1];
      if (abortedLabel) abortedLabel.textContent = agent.abortedCount > 0 ? '(aborted: ' + agent.abortedCount + ')' : '';
      
      if (agent.sessions.length === 0) {
        row3.style.cursor = 'default';
        row3.style.opacity = '0.5';
        row3.classList.remove('clickable');
      } else {
        row3.style.cursor = 'pointer';
        row3.style.opacity = '1';
        row3.classList.add('clickable');
      }
      
      // 会话列表
      if (sessionsExpanded && agent.sessions.length > 0) {
        if (!sessionList) {
          sessionList = document.createElement('div');
          sessionList.className = 'session-list';
          details.appendChild(sessionList);
        }
        
        const sortedSessions = agent.sessions.slice().sort(function(a, b) {
          return (b.updatedAt || 0) - (a.updatedAt || 0);
        });
        
        sessionList.innerHTML = sortedSessions.map(function(s) {
          return '<div class="session-item">' +
            '<div class="session-main">' +
              '<div class="session-label">' + (s.label || s.key || '未知会话').slice(0, 50) + '</div>' +
              '<div class="session-task">' + getSessionTask(s) + '</div>' +
            '</div>' +
            '<div class="session-meta">' +
              '<span class="session-model">' + (s.model || '-') + '</span>' +
              '<span class="session-tokens">' + formatTokens(s.totalTokens || 0) + '</span>' +
              '<div class="session-status">' +
                '<span class="status-dot small ' + getSessionStatus(s) + '"></span>' +
                '<span>' + getSessionStatus(s) + '</span>' +
              '</div>' +
            '</div>' +
          '</div>';
        }).join('');
      } else if (sessionList) {
        sessionList.remove();
      }
    }
  }
  
  // 创建 agent 卡片
  function createAgentCard(agent, detailsExpanded, sessionsExpanded) {
    const contextPercent = getContextPercent(agent.totalTokens, agent.contextTokens);
    const contextLevel = getContextLevel(contextPercent);
    
    const card = document.createElement('div');
    card.className = 'agent-card';
    card.dataset.agentId = agent.id;
    
    // Level 1: Agent 卡片头部
    const cardHeader = document.createElement('div');
    cardHeader.className = 'agent-card-header';
    
    const agentInfo = document.createElement('div');
    agentInfo.className = 'agent-info';
    
    const nameContainer = document.createElement('div');
    
    const name = document.createElement('span');
    name.className = 'agent-name';
    name.textContent = agent.id;
    
    // 动态获取中文名字（如果有默认映射则显示，否则不显示）
    const cnName = DEFAULT_AGENT_CN_NAMES[agent.id] || '';
    if (cnName && cnName !== agent.id) {
      const cnNameSpan = document.createElement('span');
      cnNameSpan.className = 'agent-cn-name';
      cnNameSpan.textContent = '（' + cnName + '）';
      nameContainer.appendChild(name);
      nameContainer.appendChild(cnNameSpan);
    } else {
      // 没有中文名字，只显示 agentId
      nameContainer.appendChild(name);
    }
    
    const expandIcon = document.createElement('span');
    expandIcon.className = 'expand-icon';
    expandIcon.textContent = detailsExpanded ? '▼' : '▶';
    
    agentInfo.appendChild(nameContainer);
    agentInfo.appendChild(expandIcon);
    
    const status = document.createElement('div');
    status.className = 'agent-status';
    
    const badge = document.createElement('span');
    badge.className = 'model-badge';
    badge.textContent = agent.model || '-';
    
    const statusBadge = document.createElement('span');
    statusBadge.className = 'status-badge ' + agent.status;
    
    if (agent.status === 'no-sessions') {
      statusBadge.textContent = '无会话';
    } else if (agent.status === 'aborted') {
      statusBadge.textContent = 'aborted';
    } else if (agent.status === 'running') {
      statusBadge.textContent = '运行中';
    } else {
      statusBadge.textContent = '空闲';
    }
    
    status.appendChild(badge);
    status.appendChild(statusBadge);
    cardHeader.appendChild(agentInfo);
    cardHeader.appendChild(status);
    
    // Level 2: Agent 详情
    const details = document.createElement('div');
    details.className = 'agent-details';
    details.style.display = detailsExpanded ? 'block' : 'none';
    
    if (detailsExpanded) {
      // Tokens 行
      const row1 = document.createElement('div');
      row1.className = 'detail-row row-tokens';
      const row1Label = document.createElement('span');
      row1Label.className = 'detail-label';
      row1Label.textContent = '累计 Tokens / Context Window:';
      const row1Value = document.createElement('span');
      row1Value.className = 'detail-value';
      row1Value.textContent = agent.sessions.length === 0 ? '- / -' : formatTokens(agent.totalTokens) + ' / ' + formatTokens(agent.contextTokens);
      row1.appendChild(row1Label);
      row1.appendChild(row1Value);
      
      // Context 使用率行（带进度条）
      const row2 = document.createElement('div');
      row2.className = 'detail-row row-context';
      row2.style.display = 'flex';
      row2.style.alignItems = 'center';
      row2.style.gap = '8px';
      const row2Label = document.createElement('span');
      row2Label.className = 'detail-label';
      row2Label.textContent = 'Context 使用率:';
      const row2Value = document.createElement('span');
      row2Value.className = 'detail-value';
      row2Value.textContent = agent.sessions.length === 0 ? '-' : contextPercent.toFixed(1) + '%';
      const bar = document.createElement('div');
      bar.className = 'context-bar';
      const fill = document.createElement('div');
      fill.className = 'context-fill ' + contextLevel;
      fill.style.width = (agent.sessions.length > 0 ? contextPercent : 0) + '%';
      bar.appendChild(fill);
      row2.appendChild(row2Label);
      row2.appendChild(row2Value);
      row2.appendChild(bar);
      
      // 会话数量行
      const row3 = document.createElement('div');
      row3.className = 'detail-row row-sessions' + (agent.sessions.length > 0 ? ' clickable' : '');
      if (agent.sessions.length === 0) {
        row3.style.cursor = 'default';
        row3.style.opacity = '0.5';
      } else {
        row3.title = sessionsExpanded ? '收起会话列表' : '展开会话列表';
        row3.addEventListener('click', function(e) {
          e.stopPropagation();
          sessionsExpanded = !sessionsExpanded;
          expandedStates[agent.id] = { details: detailsExpanded, sessions: sessionsExpanded };
          updateAgentCard(card, agent, detailsExpanded, sessionsExpanded);
        });
      }
      const row3Label = document.createElement('span');
      row3Label.className = 'detail-label';
      row3Label.textContent = '会话数量:';
      const row3ValueContainer = document.createElement('div');
      row3ValueContainer.style.display = 'flex';
      row3ValueContainer.style.alignItems = 'center';
      row3ValueContainer.style.gap = '6px';
      const row3Value = document.createElement('span');
      row3Value.className = 'detail-value';
      row3Value.textContent = agent.sessions.length;
      const sessionExpandIcon = document.createElement('span');
      sessionExpandIcon.className = 'detail-value clickable';
      sessionExpandIcon.textContent = sessionsExpanded ? '▼' : '▶';
      const row3Aborted = document.createElement('span');
      row3Aborted.className = 'detail-label';
      row3Aborted.textContent = agent.abortedCount > 0 ? '(aborted: ' + agent.abortedCount + ')' : '';
      row3ValueContainer.appendChild(row3Value);
      row3ValueContainer.appendChild(sessionExpandIcon);
      row3ValueContainer.appendChild(row3Aborted);
      row3.appendChild(row3Label);
      row3.appendChild(row3ValueContainer);
      
      details.appendChild(row1);
      details.appendChild(row2);
      details.appendChild(row3);
      
      // Level 3: 会话列表
      if (sessionsExpanded && agent.sessions.length > 0) {
        const sessionList = document.createElement('div');
        sessionList.className = 'session-list';
        
        const sortedSessions = agent.sessions.slice().sort(function(a, b) {
          return (b.updatedAt || 0) - (a.updatedAt || 0);
        });
        
        sortedSessions.forEach(function(s) {
          const item = document.createElement('div');
          item.className = 'session-item';
          
          const main = document.createElement('div');
          main.className = 'session-main';
          
          const label = document.createElement('div');
          label.className = 'session-label';
          label.textContent = (s.label || s.key || '未知会话').slice(0, 50);
          
          const task = document.createElement('div');
          task.className = 'session-task';
          task.textContent = getSessionTask(s);
          
          main.appendChild(label);
          main.appendChild(task);
          
          const meta = document.createElement('div');
          meta.className = 'session-meta';
          
          const model = document.createElement('span');
          model.className = 'session-model';
          model.textContent = s.model || '-';
          
          const tokens = document.createElement('span');
          tokens.className = 'session-tokens';
          tokens.textContent = formatTokens(s.totalTokens || 0);
          
          const statusContainer = document.createElement('div');
          statusContainer.className = 'session-status';
          const dot = document.createElement('span');
          dot.className = 'status-dot small ' + getSessionStatus(s);
          const statusText = document.createElement('span');
          statusText.textContent = getSessionStatus(s);
          statusContainer.appendChild(dot);
          statusContainer.appendChild(statusText);
          
          meta.appendChild(model);
          meta.appendChild(tokens);
          meta.appendChild(statusContainer);
          
          item.appendChild(main);
          item.appendChild(meta);
          sessionList.appendChild(item);
        });
        
        details.appendChild(sessionList);
      }
    }
    
    card.appendChild(cardHeader);
    card.appendChild(details);
    
    // 点击卡片头部展开/收起详情
    cardHeader.addEventListener('click', function() {
      detailsExpanded = !detailsExpanded;
      expandedStates[agent.id] = { details: detailsExpanded, sessions: sessionsExpanded };
      updateAgentCard(card, agent, detailsExpanded, sessionsExpanded);
    });
    
    return card;
  }
  
  // 加载数据
  function loadData() {
    // 从本地轻量级服务获取数据（127.0.0.1:18790）
    fetch('http://127.0.0.1:18790/api/sessions')
      .then(function(res) { return res.json(); })
      .then(function(sessions) {
        // 获取所有 agents 的 sessions
        var agentsData = {};
        sessions.forEach(function(s) {
          var agentId = s.agentId || 'main';
          if (!agentsData[agentId]) {
            agentsData[agentId] = {
              id: agentId,
              model: s.model || '-',
              sessions: [],
              totalTokens: 0,
              contextTokens: s.contextTokens || 1000000,
              active: false,
              abortedCount: 0,
              status: 'idle',
              lastUpdate: 0
            };
          }
          agentsData[agentId].sessions.push(s);
          agentsData[agentId].totalTokens = Math.max(agentsData[agentId].totalTokens, s.totalTokens || 0);
          agentsData[agentId].contextTokens = s.contextTokens || agentsData[agentId].contextTokens;
          
          if (s.aborted) {
            agentsData[agentId].abortedCount++;
            agentsData[agentId].status = 'aborted';
          }
          
          if (s.updatedAt > agentsData[agentId].lastUpdate) {
            agentsData[agentId].lastUpdate = s.updatedAt;
            agentsData[agentId].model = s.model || agentsData[agentId].model;
          }
          
          var fiveMinutesAgo = Date.now() - 5 * 60 * 1000;
          if (s.updatedAt > fiveMinutesAgo && !s.aborted) {
            agentsData[agentId].active = true;
            if (agentsData[agentId].status !== 'aborted') {
              agentsData[agentId].status = 'running';
            }
          }
        });
        
        // 动态获取所有 agents（从 sessions 数据中提取）
        const ALL_AGENTS = Object.keys(agentsData);
        
        // 如果没有 sessions，不显示任何 agents
        if (ALL_AGENTS.length === 0) {
          return;
        }
        
        // 渲染 - 使用增量更新，避免闪烁
        var section = body.querySelector('.section');
        if (!section) {
          section = document.createElement('div');
          section.className = 'section';
          body.innerHTML = '';
          body.appendChild(section);
          
          // 提示文字（换行显示）
          var hint = document.createElement('div');
          hint.className = 'hint';
          hint.innerHTML = '🟢运行中 🟡空闲 🔴aborted<br>点击卡片展开详情 | 点击会话数量展开会话列表';
          section.appendChild(hint);
        }
        
        // 更新或创建 agent 卡片
        ALL_AGENTS.forEach(function(agentId) {
          if (agentsData[agentId]) {
            var existingCard = section.querySelector('.agent-card[data-agent-id="' + agentId + '"]');
            var savedState = expandedStates[agentId] || { details: false, sessions: false };
            
            if (existingCard) {
              // 更新现有卡片
              updateAgentCard(existingCard, agentsData[agentId], savedState.details, savedState.sessions);
            } else {
              // 创建新卡片
              var newCard = createAgentCard(agentsData[agentId], savedState.details, savedState.sessions);
              section.appendChild(newCard);
            }
          }
        });
        
        // 移除不存在的 agent 卡片
        var existingCards = section.querySelectorAll('.agent-card');
        existingCards.forEach(function(card) {
          var agentId = card.dataset.agentId;
          if (!agentsData[agentId]) {
            card.remove();
          }
        });
        
        // 添加刷新按钮（如果不存在）
        if (!body.querySelector('.refresh-btn')) {
          var refreshBtn = document.createElement('button');
          refreshBtn.className = 'refresh-btn';
          refreshBtn.textContent = '刷新（10 秒自动刷新）';
          refreshBtn.addEventListener('click', loadData);
          section.appendChild(refreshBtn);
        }
      })
      .catch(function(e) {
        body.innerHTML = '<div class="error">加载失败：' + e.message + '<br><small>确保 sessions API (18790) 在运行：cd ~/.openclaw/workspace-programmer && node openclaw-sessions-api.js</small></div>';
      });
  }
  
  // 初始加载
  loadData();
  
  // 自动刷新（每 10 秒）
  setInterval(loadData, 10000);
  
  console.log('[OpenClaw Monitor] 面板已注入');
})();