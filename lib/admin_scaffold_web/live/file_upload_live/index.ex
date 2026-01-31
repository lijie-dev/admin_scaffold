defmodule AdminScaffoldWeb.FileUploadLive.Index do
  use AdminScaffoldWeb, :live_view

  alias AdminScaffoldWeb.Authorization

  @impl true
  def mount(_params, _session, socket) do
    socket = Authorization.require_permission(socket, "files.view")

    {:ok,
     socket
     |> assign(:page_title, "文件管理")
     |> assign(:uploaded_files, [])
     |> allow_upload(:file, accept: ~w(.jpg .jpeg .png .gif .pdf .doc .docx .xls .xlsx), max_entries: 5)}
  end

  @impl true
  def handle_event("upload", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path} ->
        # 这里应该实现实际的文件保存逻辑
        # 目前返回一个模拟的文件信息
        {:ok, %{
          filename: Path.basename(path),
          size: File.stat!(path).size,
          content_type: get_content_type(path)
        }}
      end)

    {:noreply, assign(socket, :uploaded_files, uploaded_files ++ socket.assigns.uploaded_files)}
  end

  @impl true
  def handle_event("clear", _, socket) do
    {:noreply, assign(socket, :uploaded_files, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="aurora-container">
      <!-- 页面头部 -->
      <div class="aurora-card p-6 mb-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 class="aurora-section-title" style="font-size: 1.5rem; margin-bottom: 0.5rem;">文件管理</h1>
            <p style="color: var(--color-text-secondary);">
              上传和管理文件
              <span class="aurora-badge aurora-badge-primary ml-2">ADMIN</span>
            </p>
          </div>
          <.link navigate={~p"/dashboard"} class="aurora-btn aurora-btn-secondary">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            返回仪表板
          </.link>
        </div>
      </div>

      <!-- 上传区域 -->
      <div class="aurora-card p-6 mb-6">
        <h2 class="aurora-section-title mb-4" style="font-size: 1.125rem;">上传文件</h2>

        <div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center hover:border-indigo-500 transition-colors">
          <div class="aurora-file-upload">
            <svg class="w-12 h-12 mb-4" style="color: #6366F1;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
            </svg>

            <div>
              <p class="mb-2" style="font-weight: 600; color: var(--color-text-primary);">
                拖拽文件到此处，或点击上传
              </p>
              <p style="font-size: 0.875rem; color: var(--color-text-muted);">
                支持格式：JPG, PNG, GIF, PDF, DOC, DOCX, XLS, XLSX
              </p>
              <p style="font-size: 0.875rem; color: var(--color-text-muted);">
                最大文件数：5 个
              </p>
            </div>

            <div class="mt-4">
              <.live_img_upload
                upload={@uploads.file}
                class="aurora-btn aurora-btn-primary"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                </svg>
                选择文件
              </.live_img_upload>
            </div>

            <div :for={entry <- @uploads.file.entries} class="mt-4 p-3 rounded-lg" style="background: var(--color-bg-muted);">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span>{entry.client_name}</span>
                  <span :if={entry.progress > 0} class="aurora-badge aurora-badge-secondary">
                    {entry.progress}%
                  </span>
                </div>
                <button phx-click="cancel_upload" phx-value-ref={entry.ref} class="text-red-500 hover:text-red-700">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div :if={entry.progress > 0 && entry.progress < 100} class="mt-2">
                <div class="h-2 rounded-full" style="background: var(--color-border);">
                  <div class="h-full rounded-full transition-all" style={"background: #6366F1; width: #{entry.progress}%"}></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="mt-4 flex justify-end gap-2">
          <button phx-click="upload" class="aurora-btn aurora-btn-primary" disabled={length(@uploads.file.entries) == 0}>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
            </svg>
            上传文件
          </button>
          <button phx-click="clear" class="aurora-btn aurora-btn-secondary" disabled={length(@uploaded_files) == 0}>
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
            清空列表
          </button>
        </div>
      </div>

      <!-- 已上传文件列表 -->
      <div :if={length(@uploaded_files) > 0} class="aurora-card">
        <div class="p-6" style="border-bottom: 1px solid var(--color-border);">
          <h2 class="aurora-section-title" style="font-size: 1.125rem;">
            已上传文件
            <span class="aurora-badge aurora-badge-warning ml-2">{length(@uploaded_files)} 个文件</span>
          </h2>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-6">
          <div :for={file <- @uploaded_files} class="border rounded-lg p-4 hover:border-indigo-500 transition-colors" style="border-color: var(--color-border);">
            <div class="flex items-start justify-between mb-3">
              <div class="flex items-center gap-2">
                <svg class="w-8 h-8" style="color: #6366F1;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <div>
                  <div class="font-semibold" style="color: var(--color-text-primary);">
                    {String.slice(file.filename, 0, 20)}{String.length(file.filename) > 20 && "..."}
                  </div>
                  <div style="font-size: 0.75rem; color: var(--color-text-muted);">
                    {format_file_size(file.size)}
                  </div>
                </div>
              </div>
              <button class="text-red-500 hover:text-red-700">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>

            <div class="flex items-center gap-2">
              <span class="aurora-badge aurora-badge-secondary" style="font-size: 0.75rem;">
                {file.content_type || "unknown"}
              </span>
              <span class="aurora-badge" style="background: var(--color-bg-muted); font-size: 0.75rem; color: var(--color-text-muted);">
                已上传
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- 文件使用说明 -->
      <div class="aurora-card p-6">
        <h2 class="aurora-section-title mb-4" style="font-size: 1.125rem;">使用说明</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h3 class="font-semibold mb-2" style="color: var(--color-text-primary);">支持的文件类型</h3>
            <ul class="space-y-1" style="color: var(--color-text-muted); font-size: 0.875rem;">
              <li>• 图片：JPG, JPEG, PNG, GIF</li>
              <li>• 文档：PDF, DOC, DOCX</li>
              <li>• 表格：XLS, XLSX</li>
            </ul>
          </div>
          <div>
            <h3 class="font-semibold mb-2" style="color: var(--color-text-primary);">上传限制</h3>
            <ul class="space-y-1" style="color: var(--color-text-muted); font-size: 0.875rem;">
              <li>• 单次最多上传 5 个文件</li>
              <li>• 建议单个文件不超过 10MB</li>
              <li>• 文件名支持中文和英文</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp get_content_type(path) do
    ext = Path.extname(path) |> String.downcase()

    case ext do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".pdf" -> "application/pdf"
      ".doc" -> "application/msword"
      ".docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ".xls" -> "application/vnd.ms-excel"
      ".xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      _ -> "application/octet-stream"
    end
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{div(bytes, 1024)} KB"
  defp format_file_size(bytes), do: "#{Float.round(bytes / (1024 * 1024), 2)} MB"
end
