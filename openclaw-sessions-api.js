// 轻量级 sessions API 服务
// 读取 ~/.openclaw/agents/*/sessions/sessions.json 并提供 HTTP API

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 18790;
const OPENCLAW_DIR = process.env.OPENCLAW_DIR || path.join(require('os').homedir(), '.openclaw');

console.log(`🦞 OpenClaw Sessions API`);
console.log(`📂 读取目录：${OPENCLAW_DIR}`);
console.log(`🌐 端口：${PORT}`);
console.log(`🔗 API: http://127.0.0.1:${PORT}/api/sessions\n`);

const server = http.createServer((req, res) => {
  // 设置 CORS 头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  // 处理 OPTIONS 预检请求
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  // 只处理 GET 请求
  if (req.method !== 'GET') {
    res.writeHead(405);
    res.end('Method Not Allowed');
    return;
  }
  
  // 只处理 /api/sessions 路径
  if (req.url !== '/api/sessions') {
    res.writeHead(404);
    res.end('Not Found');
    return;
  }
  
  try {
    const allSessions = [];
    const agentsDir = path.join(OPENCLAW_DIR, 'agents');
    const agentDirs = fs.readdirSync(agentsDir).filter(f => {
      try {
        return fs.statSync(path.join(agentsDir, f)).isDirectory();
      } catch {
        return false;
      }
    });
    
    for (const agentId of agentDirs) {
      try {
        const agentSessDir = path.join(agentsDir, agentId, 'sessions');
        const sFile = path.join(agentSessDir, 'sessions.json');
        if (!fs.existsSync(sFile)) continue;
        
        const data = JSON.parse(fs.readFileSync(sFile, 'utf8'));
        const sessions = Object.entries(data).map(([key, s]) => ({
          key,
          agentId: agentId,
          label: s.label || key,
          model: s.modelOverride || s.model || '-',
          totalTokens: s.totalTokens || 0,
          contextTokens: s.contextTokens || 0,
          kind: s.kind || (key.includes('group') ? 'group' : 'direct'),
          updatedAt: s.updatedAt || 0,
          createdAt: s.createdAt || s.updatedAt || 0,
          aborted: s.abortedLastRun || false
        }));
        
        // 排除 :run: 子 session
        const filteredSessions = sessions.filter(s => !s.key.includes(':run:'));
        allSessions.push(...filteredSessions);
      } catch (e) {
        console.error(`Error reading sessions for agent ${agentId}:`, e.message);
      }
    }
    
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(allSessions));
    console.log(`✅ 返回 ${allSessions.length} 个 sessions`);
  } catch (e) {
    console.error('Error:', e.message);
    res.writeHead(500);
    res.end(JSON.stringify({ error: e.message }));
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`✅ 服务已启动\n`);
});

// 优雅退出
process.on('SIGINT', () => {
  console.log('\n👋 服务已停止');
  server.close();
  process.exit(0);
});
