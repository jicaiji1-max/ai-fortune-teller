/**
 * API Server Tests
 * 测试 openclaw-sessions-api.js
 */

const http = require('http');

describe('OpenClaw Monitor API', () => {
  const API_PORT = 18790;
  const API_BASE = `http://127.0.0.1:${API_PORT}`;

  // 辅助函数：发送 HTTP 请求
  function makeRequest(path, options = {}) {
    return new Promise((resolve, reject) => {
      const url = `${API_BASE}${path}`;
      http.get(url, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              body: JSON.parse(data)
            });
          } catch (e) {
            resolve({
              statusCode: res.statusCode,
              headers: res.headers,
              body: data
            });
          }
        });
      }).on('error', reject);
    });
  }

  describe('HTTP Endpoints', () => {
    test('GET /api/sessions 返回 200', async () => {
      const response = await makeRequest('/api/sessions');
      expect(response.statusCode).toBe(200);
    });

    test('返回 JSON 格式', async () => {
      const response = await makeRequest('/api/sessions');
      expect(response.headers['content-type']).toContain('application/json');
    });

    test('返回 sessions 数组', async () => {
      const response = await makeRequest('/api/sessions');
      expect(response.body).toHaveProperty('sessions');
      expect(Array.isArray(response.body.sessions)).toBe(true);
    });
  });

  describe('CORS Headers', () => {
    test('包含 Access-Control-Allow-Origin', async () => {
      const response = await makeRequest('/api/sessions');
      expect(response.headers['access-control-allow-origin']).toBe('*');
    });

    test('包含 Access-Control-Allow-Methods', async () => {
      const response = await makeRequest('/api/sessions');
      expect(response.headers['access-control-allow-methods']).toBe('GET, OPTIONS');
    });
  });

  describe('Session Filtering', () => {
    test('过滤掉 subagent sessions', async () => {
      const response = await makeRequest('/api/sessions');
      const subagentSessions = response.body.sessions.filter(s => 
        s.key && s.key.includes(':subagent:')
      );
      expect(subagentSessions.length).toBe(0);
    });

    test('过滤掉 :run: sessions', async () => {
      const response = await makeRequest('/api/sessions');
      const runSessions = response.body.sessions.filter(s => 
        s.key && s.key.includes(':run:')
      );
      expect(runSessions.length).toBe(0);
    });
  });

  describe('Error Handling', () => {
    test('处理不存在的路径', async () => {
      const response = await makeRequest('/api/nonexistent');
      expect(response.statusCode).toBe(404);
    });
  });

  describe('Chinese Name Mapping', () => {
    test('包含 agentCnNames 字段', async () => {
      const response = await makeRequest('/api/sessions');
      expect(response.body).toHaveProperty('agentCnNames');
    });

    test('agentCnNames 包含默认映射', async () => {
      const response = await makeRequest('/api/sessions');
      const cnNames = response.body.agentCnNames;
      expect(cnNames).toHaveProperty('main');
      expect(cnNames).toHaveProperty('programmer');
    });
  });
});
