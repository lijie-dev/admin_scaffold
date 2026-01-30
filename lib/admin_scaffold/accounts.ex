defmodule AdminScaffold.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias AdminScaffold.Repo

  alias AdminScaffold.Accounts.{User, UserToken, UserNotifier, Role, Permission, Menu}
  alias AdminScaffold.System
  alias AdminScaffold.PermissionCache

  ## Database getters

  @doc """
  Returns the count of users.

  ## Examples

      iex> count_users()
      42

  """
  def count_users do
    Repo.aggregate(User, :count, :id)
  end

  @doc """
  Returns the count of roles.
  """
  def count_roles do
    Repo.aggregate(Role, :count, :id)
  end

  @doc """
  Returns the count of permissions.
  """
  def count_permissions do
    Repo.aggregate(Permission, :count, :id)
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    User
    |> preload(:roles)
    |> Repo.all()
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs, current_user \\ nil, metadata \\ %{}) do
    case user
         |> User.update_changeset(attrs)
         |> Repo.update() do
      {:ok, updated_user} = result ->
        System.log_action(current_user, "update", "User", updated_user.id, attrs, metadata)
        result

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes (for editing).
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.update_changeset(user, attrs)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user, current_user \\ nil, metadata \\ %{}) do
    case Repo.delete(user) do
      {:ok, deleted_user} = result ->
        System.log_action(
          current_user,
          "delete",
          "User",
          deleted_user.id,
          %{email: deleted_user.email},
          metadata
        )

        result

      error ->
        error
    end
  end

  ## User registration

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user registration changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs, metadata \\ %{}) do
    case %User{}
         |> User.registration_changeset(attrs)
         |> Repo.insert() do
      {:ok, user} = result ->
        System.log_action(nil, "create", "User", user.id, %{email: user.email}, metadata)
        result

      error ->
        error
    end
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `AdminScaffold.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `AdminScaffold.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  ## Role functions

  @doc """
  Returns the list of roles.
  """
  def list_roles do
    Role
    |> preload([:permissions, :menus])
    |> Repo.all()
  end

  @doc """
  Gets a single role.
  """
  def get_role!(id), do: Repo.get!(Role, id)

  @doc """
  Creates a role.
  """
  def create_role(attrs \\ %{}, current_user \\ nil, metadata \\ %{}) do
    case %Role{}
         |> Role.changeset(attrs)
         |> Repo.insert() do
      {:ok, role} = result ->
        System.log_action(current_user, "create", "Role", role.id, %{name: role.name}, metadata)
        result

      error ->
        error
    end
  end

  @doc """
  Updates a role.
  """
  def update_role(%Role{} = role, attrs, current_user \\ nil, metadata \\ %{}) do
    case role
         |> Role.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_role} = result ->
        System.log_action(current_user, "update", "Role", updated_role.id, attrs, metadata)
        clear_role_users_cache(updated_role.id)
        result

      error ->
        error
    end
  end

  @doc """
  Deletes a role.
  """
  def delete_role(%Role{} = role, current_user \\ nil, metadata \\ %{}) do
    # 先清除缓存，因为删除后无法获取关联的用户
    clear_role_users_cache(role.id)

    case Repo.delete(role) do
      {:ok, deleted_role} = result ->
        System.log_action(
          current_user,
          "delete",
          "Role",
          deleted_role.id,
          %{name: deleted_role.name},
          metadata
        )

        result

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking role changes.
  """
  def change_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end

  @doc """
  Gets the list of permission IDs for a role.
  """
  def get_role_permission_ids(role_id) do
    role = get_role!(role_id) |> Repo.preload(:permissions)
    Enum.map(role.permissions, & &1.id)
  end

  @doc """
  Gets the list of menu IDs for a role.
  """
  def get_role_menu_ids(role_id) do
    role = get_role!(role_id) |> Repo.preload(:menus)
    Enum.map(role.menus, & &1.id)
  end

  @doc """
  Updates the permissions associated with a role.
  """
  def update_role_permissions(role, permission_ids) do
    role = role |> Repo.preload(:permissions)
    permissions = Repo.all(from p in Permission, where: p.id in ^permission_ids)

    result =
      role
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:permissions, permissions)
      |> Repo.update()

    # 清除拥有此角色的所有用户的权限缓存
    case result do
      {:ok, updated_role} ->
        clear_role_users_cache(updated_role.id)
        result

      _ ->
        result
    end
  end

  @doc """
  Updates the menus associated with a role.
  """
  def update_role_menus(role, menu_ids) do
    role = role |> Repo.preload(:menus)
    menus = Repo.all(from m in Menu, where: m.id in ^menu_ids)

    role
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:menus, menus)
    |> Repo.update()
  end

  ## Permission functions

  @doc """
  Returns the list of permissions.
  """
  def list_permissions do
    Repo.all(Permission)
  end

  @doc """
  Gets a single permission.
  """
  def get_permission!(id), do: Repo.get!(Permission, id)

  @doc """
  Creates a permission.
  """
  def create_permission(attrs \\ %{}, current_user \\ nil, metadata \\ %{}) do
    case %Permission{}
         |> Permission.changeset(attrs)
         |> Repo.insert() do
      {:ok, permission} = result ->
        System.log_action(
          current_user,
          "create",
          "Permission",
          permission.id,
          %{name: permission.name, slug: permission.slug},
          metadata
        )

        result

      error ->
        error
    end
  end

  @doc """
  Updates a permission.
  """
  def update_permission(%Permission{} = permission, attrs, current_user \\ nil, metadata \\ %{}) do
    case permission
         |> Permission.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_permission} = result ->
        System.log_action(
          current_user,
          "update",
          "Permission",
          updated_permission.id,
          attrs,
          metadata
        )

        result

      error ->
        error
    end
  end

  @doc """
  Deletes a permission.
  """
  def delete_permission(%Permission{} = permission, current_user \\ nil, metadata \\ %{}) do
    case Repo.delete(permission) do
      {:ok, deleted_permission} = result ->
        System.log_action(
          current_user,
          "delete",
          "Permission",
          deleted_permission.id,
          %{name: deleted_permission.name, slug: deleted_permission.slug},
          metadata
        )

        result

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking permission changes.
  """
  def change_permission(%Permission{} = permission, attrs \\ %{}) do
    Permission.changeset(permission, attrs)
  end

  ## Menu functions

  @doc """
  Returns the list of menus.
  """
  def list_menus do
    Repo.all(from m in Menu, order_by: [asc: m.sort])
  end

  @doc """
  Gets a single menu.
  """
  def get_menu!(id), do: Repo.get!(Menu, id)

  @doc """
  Creates a menu.
  """
  def create_menu(attrs \\ %{}) do
    %Menu{}
    |> Menu.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a menu.
  """
  def update_menu(%Menu{} = menu, attrs) do
    menu
    |> Menu.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a menu.
  """
  def delete_menu(%Menu{} = menu) do
    Repo.delete(menu)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking menu changes.
  """
  def change_menu(%Menu{} = menu, attrs \\ %{}) do
    Menu.changeset(menu, attrs)
  end

  ## Authorization functions

  @doc """
  Gets all permissions for a user through their roles.

  ## Examples

      iex> get_user_permissions(user_id)
      [%Permission{slug: "users.manage"}, ...]

  """
  def get_user_permissions(user_id) do
    # 先尝试从缓存获取
    case PermissionCache.get_user_permissions(user_id) do
      {:ok, permissions} ->
        permissions

      {:error, _} ->
        # 缓存未命中或已过期,从数据库查询
        permissions =
          from(p in Permission,
            join: rp in "role_permissions",
            on: p.id == rp.permission_id,
            join: ur in "user_roles",
            on: rp.role_id == ur.role_id,
            where: ur.user_id == ^user_id,
            distinct: true
          )
          |> Repo.all()

        # 尝试将结果存入缓存(忽略错误)
        case PermissionCache.put_user_permissions(user_id, permissions) do
          :ok -> :ok
          {:error, _reason} -> :ok
        end

        permissions
    end
  end

  @doc """
  Checks if a user has a specific permission.

  ## Examples

      iex> has_permission?(user, "users.manage")
      true

      iex> has_permission?(user, "admin.settings")
      false

  """
  def has_permission?(%User{id: user_id}, permission_slug) when is_binary(permission_slug) do
    # 使用缓存的权限列表进行检查
    user_id
    |> get_user_permissions()
    |> Enum.any?(fn permission -> permission.slug == permission_slug end)
  end

  def has_permission?(nil, _permission_slug), do: false

  @doc """
  Checks if a user can access a specific menu path.

  ## Examples

      iex> can_access_menu?(user, "/admin/users")
      true

  """
  def can_access_menu?(%User{id: user_id}, menu_path) when is_binary(menu_path) do
    from(m in Menu,
      join: rm in "role_menus",
      on: m.id == rm.menu_id,
      join: ur in "user_roles",
      on: rm.role_id == ur.role_id,
      where: ur.user_id == ^user_id and m.path == ^menu_path
    )
    |> Repo.exists?()
  end

  def can_access_menu?(nil, _menu_path), do: false

  @doc """
  Gets all accessible menus for a user through their roles.

  ## Examples

      iex> get_user_menus(user_id)
      [%Menu{name: "用户管理", path: "/admin/users"}, ...]

  """
  def get_user_menus(user_id) do
    from(m in Menu,
      join: rm in "role_menus",
      on: m.id == rm.menu_id,
      join: ur in "user_roles",
      on: rm.role_id == ur.role_id,
      where: ur.user_id == ^user_id and m.status == :active,
      distinct: true,
      order_by: [asc: m.sort]
    )
    |> Repo.all()
  end

  ## Private Functions

  # 清除拥有指定角色的所有用户的权限缓存
  defp clear_role_users_cache(role_id) do
    # 查询所有拥有此角色的用户ID
    user_ids =
      from(ur in "user_roles",
        where: ur.role_id == ^role_id,
        select: ur.user_id
      )
      |> Repo.all()

    # 清除这些用户的权限缓存
    Enum.each(user_ids, fn user_id ->
      PermissionCache.clear_user_permissions(user_id)
    end)
  end
end
