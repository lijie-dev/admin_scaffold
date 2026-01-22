defmodule AdminScaffold.Accounts.PermissionTest do
  use AdminScaffold.DataCase

  alias AdminScaffold.Accounts.Permission

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{name: "用户管理", slug: "user-management"}
      changeset = Permission.changeset(%Permission{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset with description" do
      attrs = %{name: "用户管理", slug: "user-management", description: "管理系统用户"}
      changeset = Permission.changeset(%Permission{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without name" do
      attrs = %{slug: "user-management"}
      changeset = Permission.changeset(%Permission{}, attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset without slug" do
      attrs = %{name: "用户管理"}
      changeset = Permission.changeset(%Permission{}, attrs)
      refute changeset.valid?
      assert %{slug: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset with invalid slug format - uppercase" do
      attrs = %{name: "用户管理", slug: "User-Management"}
      changeset = Permission.changeset(%Permission{}, attrs)
      refute changeset.valid?
      assert %{slug: [_]} = errors_on(changeset)
    end

    test "invalid changeset with invalid slug format - spaces" do
      attrs = %{name: "用户管理", slug: "user management"}
      changeset = Permission.changeset(%Permission{}, attrs)
      refute changeset.valid?
    end
  end
end
