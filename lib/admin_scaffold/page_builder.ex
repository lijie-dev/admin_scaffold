defmodule AdminScaffold.PageBuilder do
  @moduledoc """
  PageBuilder Context - 管理页面配置的核心模块

  提供 JSON 驱动的页面构建功能，类似 owl-admin 的 amis 配置系统。
  """

  import Ecto.Query, warn: false
  alias AdminScaffold.Repo
  alias AdminScaffold.PageBuilder.Page

  ## Page CRUD

  @doc """
  返回所有页面列表
  """
  def list_pages(opts \\ []) do
    Page
    |> maybe_filter_by_status(Keyword.get(opts, :status))
    |> order_by(asc: :sort, asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  根据 slug 获取页面
  """
  def get_page_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Page, slug: slug, status: "active")
  end

  @doc """
  根据 ID 获取页面
  """
  def get_page!(id), do: Repo.get!(Page, id)

  @doc """
  根据类型获取页面列表
  """
  def list_pages_by_type(type) when is_binary(type) do
    Repo.all(
      from p in Page, where: p.type == ^type and p.status == "active", order_by: [asc: :sort]
    )
  end

  @doc """
  创建新页面
  """
  def create_page(attrs \\ %{}) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  更新页面
  """
  def update_page(%Page{} = page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  删除页面
  """
  def delete_page(%Page{} = page) do
    Repo.delete(page)
  end

  @doc """
  返回页面变更集
  """
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  ## 页面配置处理

  @doc """
  解析页面配置为可用格式
  """
  def parse_page_config(%Page{} = page) do
    %{
      id: page.id,
      name: page.name,
      title: page.title,
      slug: page.slug,
      type: page.type,
      icon: page.icon,
      config: normalize_config(page.config)
    }
  end

  @doc """
  渲染页面配置组件
  根据 type 返回对应的 LiveView 组件
  """
  def render_page_type("list"), do: AdminScaffoldWeb.PageLive.List
  def render_page_type("form"), do: AdminScaffoldWeb.PageLive.Form
  def render_page_type("detail"), do: AdminScaffoldWeb.PageLive.Detail
  def render_page_type("dashboard"), do: AdminScaffoldWeb.PageLive.Dashboard
  def render_page_type(_), do: AdminScaffoldWeb.PageLive.List

  # 私有函数

  defp maybe_filter_by_status(query, nil), do: query
  defp maybe_filter_by_status(query, status), do: where(query, [p], p.status == ^status)

  defp normalize_config(config) when is_map(config), do: config
  defp normalize_config(_), do: %{}
end
