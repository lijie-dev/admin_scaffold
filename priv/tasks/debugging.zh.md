# 任务：调试 Elixir/Phoenix 应用

**目的**：系统地诊断和修复 Elixir/Phoenix 应用中的问题

**代理**：elixir-dev

**耗时**：30 分钟 - 4 小时（因问题复杂度而异）

## 概述

在 Elixir 中进行有效的调试需要理解 BEAM、OTP 监督树和 Phoenix 请求生命周期。使用系统化的方法来隔离和修复问题。

## 调试工具和技术

### 1. IEx - 交互式 Elixir Shell

**启动 IEx：**
```bash
# 使用 Mix 项目
iex -S mix

# 使用 Phoenix 服务器
iex -S mix phx.server

# 连接到运行中的节点
iex --sname debug --remsh my_app@localhost
```

**关键 IEx 命令：**
```elixir
# 帮助
h()                          # 通用帮助
h(Enum.map)                  # 函数文档
i(variable)                  # 检查值和类型

# 重新编译
recompile()                  # 重新编译已更改的模块

# 进程检查
Process.list()               # 所有进程
Process.info(pid)            # 进程详情
:sys.get_state(pid)          # GenServer 状态（仅用于测试/调试！）

# 历史记录
v()                          # 最后一个值
v(3)                         # 第 3 行的值

# 退出
Ctrl+C, Ctrl+C               # 退出 IEx
```

### 2. IO.inspect - 打印调试

**基本用法：**
```elixir
def process_data(data) do
  data
  |> transform()
  |> IO.inspect(label: "After transform")
  |> validate()
  |> IO.inspect(label: "After validate")
  |> save()
end
```

**高级选项：**
```elixir
# 限制输出
IO.inspect(large_list, limit: 10)

# 美化打印
IO.inspect(struct, pretty: true)

# 自定义标签和函数
data
|> IO.inspect(label: "Step 1")
|> Enum.map(&transform/1)
|> IO.inspect(label: "Step 2", limit: 5)
```

### 3. Logger - 应用日志

**日志级别：**
```elixir
require Logger

Logger.debug("用于调试的详细信息")
Logger.info("关于系统操作的一般信息")
Logger.warning("警告消息")
Logger.error("错误消息")

# 带元数据
Logger.info("用户已登录",
  user_id: user.id,
  ip_address: conn.remote_ip
)
```

**配置日志：**
```elixir
# config/dev.exs
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id]

# 记录所有 SQL 查询
config :my_app, MyApp.Repo,
  log: :debug  # 或 false 禁用
```

### 4. 调试器 - 逐步执行代码

**使用 IEx.pry：**
```elixir
# 添加到代码
require IEx

def problematic_function(data) do
  result = transform(data)
  IEx.pry()  # 执行在此停止
  validate(result)
end
```

**在 IEx 会话中：**
```elixir
# 当触发 pry() 时：
respawn()                    # 继续执行
whereami()                   # 显示当前代码位置
# 直接访问本地变量
result
data
```

**使用 :debugger（Erlang 调试器）：**
```elixir
# 启动图形调试器
:debugger.start()

# 解释模块
:int.ni(MyModule)

# 设置断点
:int.break(MyModule, line_number)
```

### 5. Observer - 系统监控

**启动 Observer：**
```bash
# 在 IEx 中
iex> :observer.start()
```

**监控内容：**
- **Applications 标签**：查看所有运行中的应用
- **Processes 标签**：查找内存泄漏、失控进程
- **System 标签**：整体 BEAM 健康状况
- **Load Charts**：CPU、内存、I/O 使用情况
- **Trace Overview**：追踪函数调用

### 6. Recon - 生产环境调试

```elixir
# 添加到 mix.exs
{:recon, "~> 2.5"}

# 查找内存占用最多的进程
:recon.proc_count(:memory, 10)

# 查找最繁忙的进程
:recon.proc_count(:reductions, 10)

# 查找邮箱最大的进程
:recon.proc_count(:message_queue_len, 10)

# 获取进程信息
:recon.info(pid)
```

## 常见问题和解决方案

### 问题 1：N+1 查询性能

**症状：**
- 页面加载缓慢
- 日志中有许多数据库查询
- 关于预加载的警告

**诊断：**
```elixir
# 启用查询日志
config :my_app, MyApp.Repo,
  log: :debug

# 检查日志中的重复查询
```

**解决方案：**
```elixir
# 不好：N+1 查询
users = Repo.all(User)
Enum.each(users, fn user ->
  Enum.each(user.posts, fn post ->  # 为每个用户查询！
    IO.puts post.title
  end)
end)

# 好：预加载
users = Repo.all(User) |> Repo.preload(:posts)
Enum.each(users, fn user ->
  Enum.each(user.posts, fn post ->  # 已加载！
    IO.puts post.title
  end)
end)
```

### 问题 2：GenServer 崩溃

**症状：**
- 进程意外退出
- 日志中有监督者重启消息

**诊断：**
```elixir
# 检查监督者日志
Logger.error "GenServer #{inspect(self())} terminating"

# 获取崩溃报告
:sys.get_state(pid)  # 如果进程仍然活跃
Process.info(pid, :current_stacktrace)

# 检查监督树
Supervisor.which_children(MySupervisor)
```

**解决方案：**
```elixir
# 添加更好的错误处理
def handle_call(:risky_operation, _from, state) do
  try do
    result = perform_risky_operation(state)
    {:reply, {:ok, result}, state}
  rescue
    error ->
      Logger.error("操作失败：#{inspect(error)}")
      {:reply, {:error, :operation_failed}, state}
  end
end

# 或使用 with 以获得更清晰的错误处理
def handle_call(:risky_operation, _from, state) do
  with {:ok, data} <- fetch_data(state),
       {:ok, processed} <- process_data(data),
       {:ok, result} <- save_result(processed) do
    {:reply, {:ok, result}, state}
  else
    {:error, reason} = error ->
      Logger.error("操作失败：#{inspect(reason)}")
      {:reply, error, state}
  end
end
```

### 问题 3：内存泄漏

**症状：**
- 内存使用量随时间增长
- 最终因 :out_of_memory 崩溃

**诊断：**
```elixir
# 在生产环境中（使用 recon）
:recon.proc_count(:memory, 10)

# 检查大型 ETS 表
:ets.all()
|> Enum.map(fn table ->
  {table, :ets.info(table, :size), :ets.info(table, :memory)}
end)
|> Enum.sort_by(fn {_, _, mem} -> mem end, :desc)

# 检查 LiveView 分配
# 查找大型分配，特别是存储为列表的集合
```

**解决方案：**
```elixir
# 不好：在 socket 分配中存储大型集合
def mount(_params, _session, socket) do
  {:ok, assign(socket, :products, list_all_products())}  # 内存膨胀！
end

# 好：使用流
def mount(_params, _session, socket) do
  {:ok, stream(socket, :products, list_all_products())}
end

# 不好：在 GenServer 状态中累积数据
def handle_info({:log_event, event}, state) do
  new_events = [event | state.events]  # 永远增长！
  {:noreply, %{state | events: new_events}}
end

# 好：限制大小或使用外部存储
def handle_info({:log_event, event}, state) do
  new_events =
    [event | state.events]
    |> Enum.take(1000)  # 仅保留最后 1000 条

  {:noreply, %{state | events: new_events}}
end
```

### 问题 4：LiveView 不更新

**症状：**
- handle_event 后 UI 不更新
- 未收到 PubSub 消息
- 显示过期数据

**诊断：**
```elixir
# 检查 socket 是否连接
def mount(_params, _session, socket) do
  IO.inspect(connected?(socket), label: "Connected?")
  # ...
end

# 验证 PubSub 订阅
Phoenix.PubSub.subscribers(MyApp.PubSub, "topic_name")

# 检查 handle_info 返回值
def handle_info(msg, socket) do
  IO.inspect(msg, label: "Received message")
  {:noreply, socket}  # 你是否忘记更新 socket？
end
```

**解决方案：**
```elixir
# 确保返回更新的 socket
def handle_event("delete", %{"id" => id}, socket) do
  product = get_product!(id)
  delete_product(product)

  # 必须返回更新的 socket！
  {:noreply, stream_delete(socket, :products, product)}
end

# 仅在连接时订阅
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "products")
  end

  {:ok, stream(socket, :products, list_products())}
end
```

### 问题 5：Ecto 查询错误

**症状：**
- Ecto.Query.CastError
- 关联未加载错误
- 无效查询错误

**诊断：**
```elixir
# 查看生成的 SQL
query = from(u in User, where: u.active == true)
IO.inspect(Repo.to_sql(:all, query), label: "SQL")

# 检查预加载了什么
user = Repo.get!(User, 1)
IO.inspect(Ecto.assoc_loaded?(user.posts), label: "Posts loaded?")
```

**解决方案：**
```elixir
# 预加载关联
user = Repo.get!(User, id) |> Repo.preload(:posts)

# 或在查询中
query = from(u in User, where: u.id == ^id, preload: [:posts])
Repo.one(query)

# 用于条件预加载
query =
  from(u in User, where: u.id == ^id)
  |> maybe_preload_posts(should_preload?)

defp maybe_preload_posts(query, true), do: preload(query, :posts)
defp maybe_preload_posts(query, false), do: query
```

### 问题 6：测试失败

**症状：**
- 不稳定的测试
- 测试单独运行通过但在套件中失败
- 时间相关的失败

**诊断：**
```elixir
# 运行单个测试
mix test test/my_test.exs:23

# 使用种子运行（重现不稳定测试）
mix test --seed 12345

# 仅运行失败的测试
mix test --failed

# 使用追踪运行
mix test --trace
```

**解决方案：**
```elixir
# 修复异步问题
use MyApp.DataCase, async: false  # 如果测试共享状态

# 测试中的正确异步处理
test "async operation completes" do
  send_async_message()

  # 不好：竞态条件
  assert get_result() == :done

  # 好：等待消息
  assert_receive {:done, result}, 1000
  assert result == :expected
end

# 数据库测试的沙箱模式
# 确保 test/test_helper.exs 包含：
Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, :manual)
```

## 调试工作流

### 工作流 1：Phoenix 请求/响应问题

1. **检查路由：**
   ```bash
   mix phx.routes | grep "/path"
   ```

2. **启用请求日志：**
   ```elixir
   # 添加到端点
   plug Plug.Logger
   ```

3. **在控制器中添加断点：**
   ```elixir
   def index(conn, params) do
     require IEx; IEx.pry()
     # ...
   end
   ```

4. **检查 conn 结构：**
   ```elixir
   IO.inspect(conn.assigns, label: "Assigns")
   IO.inspect(conn.params, label: "Params")
   IO.inspect(conn.private, label: "Private")
   ```

### 工作流 2：后台任务失败

1. **检查任务队列：**
   ```elixir
   # 对于 Oban
   Oban.check_queue(:default)
   ```

2. **查看失败的任务：**
   ```elixir
   # 查询失败的任务
   from(j in Oban.Job, where: j.state == "discarded")
   |> Repo.all()
   ```

3. **手动重试任务：**
   ```elixir
   Oban.retry_job(job_id)
   ```

4. **添加检测：**
   ```elixir
   def perform(%{args: args}) do
     Logger.info("启动任务", args: args)

     result = do_work(args)

     Logger.info("任务完成", result: result)
     result
   end
   ```

### 工作流 3：生产环境问题

1. **连接到生产节点：**
   ```bash
   # 通过 SSH 或 kubectl
   iex --remsh my_app@prod-server
   ```

2. **检查系统健康状况：**
   ```elixir
   :observer.start()  # 如果 GUI 可用
   :recon.proc_count(:memory, 10)
   :recon.proc_count(:reductions, 10)
   ```

3. **检查应用状态：**
   ```elixir
   Application.started_applications()
   Supervisor.which_children(MyApp.Supervisor)
   ```

4. **查看日志：**
   ```elixir
   # 检查最近的错误
   Logger.warning("调查生产问题")
   ```

## 调试检查清单

调试问题时：

- [ ] 你能一致地重现该问题吗？
- [ ] 最近改变了什么（代码、配置、依赖）？
- [ ] 你检查过日志吗？
- [ ] 你添加了 IO.inspect 来追踪执行吗？
- [ ] 它是在所有环境中发生还是仅在一个环境中？
- [ ] 你检查过 N+1 查询吗？
- [ ] 你验证过 socket/进程状态吗？
- [ ] 你仔细检查过错误消息吗？
- [ ] 你查阅过文档吗？
- [ ] 你搜索过 GitHub 问题吗？

## 预防策略

### 添加全面的测试

```elixir
# 也要测试错误情况！
test "handles invalid input" do
  assert {:error, _} = MyContext.create_item(%{invalid: "data"})
end
```

### 使用类型规范

```elixir
@spec process_data(String.t()) :: {:ok, result} | {:error, term()}
      when result: map()
def process_data(data) do
  # Dialyzer 将捕获类型错误
end
```

### 添加遥测

```elixir
:telemetry.execute(
  [:my_app, :operation, :start],
  %{system_time: System.system_time()},
  %{operation: :process_data}
)
```

### 使用模式匹配

```elixir
# 显式模式可以尽早捕获错误
def handle_response({:ok, %{"data" => data}}) do
  process(data)
end

def handle_response({:error, reason}) do
  Logger.error("请求失败：#{inspect(reason)}")
  {:error, :request_failed}
end
```

## 资源

- [Elixir Logger](https://hexdocs.pm/logger)
- [IEx 文档](https://hexdocs.pm/iex)
- [Observer 指南](https://www.erlang.org/doc/man/observer.html)
- [Recon 库](https://ferd.github.io/recon/)
- [Phoenix 调试指南](https://hexdocs.pm/phoenix/debugging.html)
- [使用 IEx.pry 调试](https://blog.appsignal.com/2020/05/05/debugging-with-iex-pry-in-elixir.html)

## 后续步骤

修复问题后：
1. 添加测试以防止回归
2. 在注释/文档中记录问题
3. 与团队分享学习内容
4. 考虑是否存在类似问题
5. 如需要更新错误处理
