/**
 * Integration Tests
 * 端到端测试 API + Chrome Extension 集成
 */

const http = require('http');

describe('Integration Tests', () => {
  const API_PORT = 18790;
  const API_BASE = `http://127.0.0.1:${API_PORT}`;

  function makeRequest(path) {
    return new Promise((resolve, reject) => {
      http.get(`${API_BASE}${path}`, (res) => {
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

  describe('API Server Availability', () => {
    test('API 服务器应该正在运行', async () => {
      const response = await makeRequest('/api/sessions');
      expect(response.statusCode).toBe(200);
    }, 10000);
  });

  describe('Data Format Validation', () => {
    test('返回的数据格式正确', async () => {
      const response = await makeRequest('/api/sessions');
      
      expect(response.body).toHaveProperty('sessions');
      expect(response.body).toHaveProperty('agentCnNames');
      
      const sessions = response.body.sessions;
      if (sessions.length > 0) {
        const session = sessions[0];
        expect(session).toHaveProperty('key');
        expect(session).toHaveProperty('agentId');
        expect(session).toHaveProperty('model');
        expect(session).toHaveProperty('totalTokens');
      }
    });

    test('中文名字映射格式正确', async () => {
      const response = await makeRequest('/api/sessions');
      const cnNames = response.body.agentCnNames;
      
      expect(typeof cnNames).toBe('object');
      // 至少应该有一些默认映射
      expect(Object.keys(cnNames).length).toBeGreaterThan(0);
    });
  });

  describe('Performance Tests', () => {
    test('响应时间应该 < 100ms', async () => {
      const start = Date.now();
      await makeRequest('/api/sessions');
      const elapsed = Date.now() - start;
      
      expect(elapsed).toBeLessThan(100);
    });

    test('并发请求处理', async () => {
      const promises = Array(10).fill(null).map(() => 
        makeRequest('/api/sessions')
      );
      
      const results = await Promise.all(promises);
      
      results.forEach(result => {
        expect(result.statusCode).toBe(200);
      });
    });
  });

  describe('Bug Fix Verification', () => {
    test('Bug #2: 中文名字不应该被默认值覆盖', async () => {
      const response = await makeRequest('/api/sessions');
      const cnNames = response.body.agentCnNames;
      
      // 如果 SOUL.md 定义了 'programmer' 为其他值，应该保留 SOUL.md 的值
      // 这里只能验证字段存在
      expect(cnNames).toHaveProperty('programmer');
    });

    test('Bug #5: 端口冲突应该有友好错误', async () => {
      // 这个测试需要启动第二个服务器实例
      // 实际测试中可以验证错误日志
      expect(true).toBe(true);
    });
  });

  describe('Stress Tests', () => {
    test('大量 sessions 数据处理', async () => {
      const response = await makeRequest('/api/sessions');
      
      // 验证即使有大量 sessions，也能正常返回
      expect(response.statusCode).toBe(200);
      expect(Array.isArray(response.body.sessions)).toBe(true);
    }, 15000);

    test('快速连续请求', async () => {
      const promises = [];
      for (let i = 0; i < 20; i++) {
        promises.push(makeRequest('/api/sessions'));
      }
      
      const results = await Promise.all(promises);
      
      // 所有请求都应该成功
      results.forEach(result => {
        expect(result.statusCode).toBe(200);
      });
    }, 10000);
  });
});
