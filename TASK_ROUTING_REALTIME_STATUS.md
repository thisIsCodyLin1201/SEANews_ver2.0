# 任務路由即時狀態機制說明

## 📊 總覽

任務路由（Task Routing）系統透過 **Server-Sent Events (SSE)** 實現即時狀態更新，讓前端可以顯示 AI 處理過程中的每個步驟狀態。

## 🔄 完整流程

```
前端請求 → 後端 SSE Stream → 監聽 Event → 更新狀態 → 前端顯示
   ↓            ↓                ↓            ↓            ↓
 /api/      團隊執行         routing_      狀態合併     進度條
artifacts    任務事件         update                    UI 更新
```

---

## 🎯 核心組件

### 1. 後端事件監聽 (agno_api.py)

#### 📍 事件處理函數：`build_routing_update()`

位置：[server/agno_api.py#L935-L998](server/agno_api.py#L935-L998)

```python
def build_routing_update(event: Any, routing_state: Dict[str, str]) -> Optional[Dict[str, str]]:
    event_name = getattr(event, "event", "") or ""

    # 1️⃣ 監聽「任務開始」事件
    if event_name in {TeamRunEvent.run_started.value, RunEvent.run_started.value}:
        step_id = "run-main"
        routing_state.setdefault(step_id, step_id)
        return {
            "id": step_id, 
            "label": "模型生成", 
            "status": "running",  # 🔴 運行中
            "eta": "進行中"
        }

    # 2️⃣ 監聽「任務完成」事件
    if event_name in {TeamRunEvent.run_completed.value, RunEvent.run_completed.value}:
        step_id = "run-main"
        routing_state.setdefault(step_id, step_id)
        return {
            "id": step_id, 
            "label": "模型生成", 
            "status": "done",  # ✅ 完成
            "eta": ""
        }

    # 3️⃣ 監聽「工具調用開始」事件
    if event_name in {TeamRunEvent.tool_call_started.value, RunEvent.tool_call_started.value}:
        tool = getattr(event, "tool", None)
        tool_key = getattr(tool, "tool_call_id", None)
        
        return {
            "id": routing_state[tool_key],
            "label": format_tool_label(getattr(tool, "tool_name", None)),
            "status": "running",  # 🔴 運行中
            "eta": "進行中",
        }

    # 4️⃣ 監聽「工具調用完成」事件
    if event_name in {TeamRunEvent.tool_call_completed.value, RunEvent.tool_call_completed.value}:
        tool = getattr(event, "tool", None)
        tool_key = getattr(tool, "tool_call_id", None)
        
        return {
            "id": routing_state[tool_key],
            "label": format_tool_label(getattr(tool, "tool_name", None)),
            "status": "done",  # ✅ 完成
            "eta": "",
        }

    return None  # 不處理其他事件
```

#### 📍 狀態合併函數：`update_routing_log()`

```python
def update_routing_log(routing_log: List[Dict[str, str]], update: Dict[str, str]) -> bool:
    """
    更新或新增路由日誌
    返回 True 表示有變更，需要發送給前端
    """
    # 1. 尋找現有步驟
    for idx, step in enumerate(routing_log):
        if step.get("id") == update.get("id"):
            merged = {**step, **update}
            if merged == step:
                return False  # 沒有變化，不發送
            routing_log[idx] = merged
            return True  # 有更新，發送
    
    # 2. 新步驟，直接加入
    routing_log.append(update)
    return True  # 新增，發送
```

---

### 2. SSE 串流實現

位置：[server/agno_api.py#L1622-L1730](server/agno_api.py#L1622-L1730)

```python
async def generate_sse():
    routing_state: Dict[str, str] = {}      # 存儲每個任務的 ID 映射
    routing_log: List[Dict[str, str]] = []  # 存儲完整的路由日誌
    
    # 🔵 步驟 1: OCR 解析（如果有圖片）
    if image_inputs:
        ocr_start = {
            "id": "ocr",
            "label": "OCR 解析",
            "status": "running",
            "eta": "進行中",
        }
        if update_routing_log(routing_log, ocr_start):
            # 立即發送給前端！
            yield f"data: {json.dumps({'routing_update': ocr_start})}\n\n"
        
        ocr_updates = run_ocr_for_documents(req.documents)
        
        ocr_done = {
            "id": "ocr",
            "label": "OCR 解析",
            "status": "done",
            "eta": "完成",
        }
        if update_routing_log(routing_log, ocr_done):
            yield f"data: {json.dumps({'routing_update': ocr_done})}\n\n"

    # 🔵 步驟 2: 模型生成開始
    run_start = {
        "id": "run-main",
        "label": "模型生成",
        "status": "running",
        "eta": "進行中",
    }
    if update_routing_log(routing_log, run_start):
        yield f"data: {json.dumps({'routing_update': run_start})}\n\n"

    # 🔵 步驟 3: 執行團隊任務並監聽事件
    response = team.run(
        prompt,
        images=image_inputs if image_inputs else None,
        stream=True,
        stream_events=True,  # ⭐ 關鍵：啟用事件串流
    )

    for event in response:
        # 🎯 從事件構建路由更新
        routing_update = build_routing_update(event, routing_state)
        
        if routing_update:
            if update_routing_log(routing_log, routing_update):
                # ⚡ 即時發送給前端！
                yield f"data: {json.dumps({'routing_update': routing_update})}\n\n"
        
        # ... 處理其他事件（chunk, trace_event 等）

    # 🔵 步驟 4: 模型生成完成
    run_done = {
        "id": "run-main",
        "label": "模型生成",
        "status": "done",
        "eta": "完成",
    }
    if update_routing_log(routing_log, run_done):
        yield f"data: {json.dumps({'routing_update': run_done})}\n\n"

    # 🔵 步驟 5: 發送最終結果
    final_data = safe_parse_json(accumulated)
    if routing_log:
        final_data["routing"] = routing_log  # 包含完整路由歷史
    yield f"data: {json.dumps(final_data)}\n\n"
    
    yield f"data: {json.dumps({'done': True})}\n\n"
```

---

### 3. 前端接收處理 (App.jsx)

位置：[src/App.jsx#L908-L950](src/App.jsx#L908-L950)

```javascript
// 📍 定義路由更新處理函數
const applyRoutingUpdate = (update) => {
  if (!update || !update.id) return;
  
  // 🔄 更新 routingSteps 狀態（用於顯示任務列表）
  setRoutingSteps((prev) => {
    const index = prev.findIndex((step) => step.id === update.id);
    
    if (index >= 0) {
      // 更新現有步驟
      const next = [...prev];
      next[index] = { ...next[index], ...update };
      return next;
    }
    
    // 新增步驟
    return [...prev, update];
  });
  
  // 🎨 根據任務狀態更新階段（用於進度條）
  const label = (update.label || '').toLowerCase();
  
  if (update.status === 'running') {
    // 🔴 任務開始：推測當前階段
    if (label.includes('模型生成')) {
      setCurrentStage('analyze');
      setCompletedStages(['init']);
    } 
    else if (label.includes('網路查詢') || label.includes('搜尋')) {
      setCurrentStage('search');
      setCompletedStages(['init', 'analyze']);
    }
    else if (label.includes('文件檢索') || label.includes('knowledge')) {
      setCurrentStage('process');
      setCompletedStages(['init', 'analyze', 'search']);
    }
  } 
  else if (update.status === 'done') {
    // ✅ 任務完成：更新階段
    if (label.includes('模型生成')) {
      setCurrentStage('generate');
      setCompletedStages(['init', 'analyze', 'search', 'process']);
    }
    else if (label.includes('網路查詢') || label.includes('搜尋')) {
      setCurrentStage('process');
      setCompletedStages((prev) => [...new Set([...prev, 'init', 'analyze', 'search'])]);
    }
  }
};

// 📍 SSE 串流處理
const reader = response.body.getReader();
const decoder = new TextDecoder();
let buffer = '';

while (true) {
  const { done, value } = await reader.read();
  if (done) break;

  buffer += decoder.decode(value, { stream: true });
  const lines = buffer.split('\n');
  buffer = lines.pop() || '';

  for (const line of lines) {
    if (!line.startsWith('data: ')) continue;
    const jsonStr = line.slice(6).trim();
    if (!jsonStr) continue;

    const parsed = JSON.parse(jsonStr);

    // 🎯 處理路由更新
    if (parsed.routing_update) {
      hasRoutingUpdates = true;
      applyRoutingUpdate(parsed.routing_update);  // ⚡ 即時更新 UI
      continue;
    }

    // 處理其他類型的更新...
    if (parsed.chunk) { ... }
    if (parsed.done) { ... }
  }
}
```

---

## 📊 事件類型對照表

| 事件名稱 | 觸發時機 | 狀態 | Label 範例 |
|---------|---------|------|-----------|
| `run_started` | 模型開始執行 | `running` | 模型生成 |
| `run_completed` | 模型執行完成 | `done` | 模型生成 |
| `run_error` | 模型執行錯誤 | `done` | 模型生成（失敗） |
| `tool_call_started` | 工具開始調用 | `running` | 網路查詢、文件檢索 |
| `tool_call_completed` | 工具調用完成 | `done` | 網路查詢、文件檢索 |
| `tool_call_error` | 工具調用錯誤 | `done` | 網路查詢（失敗） |

---

## 🎬 實際執行時序圖

```
時間軸 ────────────────────────────────────────────────▶

前端發送請求
  │
  ├─ SSE 連接建立
  │
後端開始處理
  │
  ├─ [OCR 解析] running ──▶ 前端顯示「OCR 解析...」
  │       │
  │       ├─ 執行 OCR
  │       │
  │       └─ done ──────────▶ 前端顯示「OCR 解析 ✓」
  │
  ├─ [模型生成] running ──▶ 前端顯示「模型生成...」
  │       │
  │       ├─ 模型執行
  │       │
  │       ├─ [網路查詢] running ──▶ 前端顯示「網路查詢...」
  │       │       │
  │       │       ├─ 搜尋網路
  │       │       │
  │       │       └─ done ──────▶ 前端顯示「網路查詢 ✓」
  │       │
  │       └─ done ──────────▶ 前端顯示「模型生成 ✓」
  │
  └─ [完成] done ──────────▶ 前端顯示所有階段完成 ✓
```

---

## 🔑 關鍵技術要點

### 1. **事件驅動** (Event-Driven)
- 使用 Agno 框架的 `stream_events=True` 參數
- 監聽 `RunEvent` 和 `TeamRunEvent`
- 每個事件即時轉換為路由更新

### 2. **狀態去重** (Deduplication)
- `routing_state` 字典維護唯一 ID
- `update_routing_log()` 判斷是否有變化
- 只在狀態真正改變時才發送更新

### 3. **即時推送** (Real-time Push)
- SSE (Server-Sent Events) 單向推送
- 格式：`data: {json}\n\n`
- 前端使用 `ReadableStream` 讀取

### 4. **狀態合併** (State Merging)
```javascript
// 前端合併策略
const merged = { ...existingStep, ...newUpdate };

// 範例：
// existing: { id: "run-main", label: "模型生成", status: "running" }
// update:   { id: "run-main", status: "done" }
// merged:   { id: "run-main", label: "模型生成", status: "done" }
```

---

## 📝 工具名稱映射

位置：[server/agno_api.py#L1013-L1024](server/agno_api.py#L1013)

```python
def format_tool_label(tool_name: Optional[str]) -> str:
    if not tool_name:
        return "工具執行"
    mapping = {
        "search_knowledge_base": "文件檢索",
        "web_search": "網路查詢",
        "exa_search": "網路查詢",
        # ... 其他工具
    }
    return mapping.get(tool_name, tool_name)
```

---

## 🎯 前端 UI 更新

### 1. **任務列表** (routingSteps)
```jsx
{routingSteps.map((step) => (
  <div key={step.id}>
    <span>{step.label}</span>
    <span>{step.status === 'running' ? '⏳' : '✓'}</span>
    <span>{step.eta}</span>
  </div>
))}
```

### 2. **進度條** (currentStage)
```jsx
const stages = ['init', 'analyze', 'search', 'process', 'generate', 'complete'];

{stages.map((stage) => (
  <div className={
    completedStages.includes(stage) ? 'completed' :
    currentStage === stage ? 'active' : 'pending'
  }>
    {stageLabels[stage]}
  </div>
))}
```

---

## 🧪 測試範例

### 測試即時狀態更新
```bash
# 發送請求並觀察 SSE 輸出
curl -N -X POST http://localhost:8787/api/artifacts \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "搜尋東南亞經濟新聞"}],
    "documents": [],
    "stream": true
  }'
```

預期輸出：
```
data: {"routing_update":{"id":"run-main","label":"模型生成","status":"running","eta":"進行中"}}

data: {"routing_update":{"id":"web_search_123","label":"網路查詢","status":"running","eta":"進行中"}}

data: {"routing_update":{"id":"web_search_123","label":"網路查詢","status":"done","eta":""}}

data: {"routing_update":{"id":"run-main","label":"模型生成","status":"done","eta":"完成"}}

data: {"assistant":{"content":"..."},"routing":[...]}

data: {"done":true}
```

---

## 💡 設計優勢

✅ **即時反饋**：用戶可以看到 AI 的思考過程  
✅ **狀態透明**：清楚知道當前執行到哪個步驟  
✅ **錯誤追蹤**：如果某個工具失敗，立即顯示  
✅ **性能優化**：只在狀態變化時才推送更新  
✅ **擴展性強**：新增工具時自動顯示在路由中  

---

## 🔧 調試技巧

1. **後端日誌**：
```python
print(f"🔄 Routing update: {routing_update}")
```

2. **前端日誌**：
```javascript
console.log('📍 Routing update received:', parsed.routing_update);
```

3. **查看完整路由**：
```javascript
console.log('📊 Final routing log:', data.routing);
```

---

## 📚 相關文件

- [server/agno_api.py](server/agno_api.py) - 後端實現
- [src/App.jsx](src/App.jsx) - 前端處理
- [TASK_ROUTING_UPDATE.md](TASK_ROUTING_UPDATE.md) - 任務路由更新文檔

---

## 總結

任務路由的即時狀態是透過以下機制實現：

1. **Agno 事件監聽**：捕獲每個任務和工具的執行事件
2. **SSE 串流推送**：即時將狀態變化推送到前端
3. **狀態合併更新**：前端智能合併新舊狀態
4. **UI 即時反應**：根據狀態更新進度條和任務列表

整個流程實現了**毫秒級**的即時更新，讓用戶能夠清楚看到 AI 的執行過程！ 🚀
