defmodule AdminScaffold.Accounts.RoleTest do
  use AdminScaffold.DataCase

  alias AdminScaffold.Accounts.Role

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{name: "管理员", status: :active}
      changeset = Role.changeset(%Role{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset with description" do
      attrs = %{name: "管理员", description: "系统管理员角色", status: :active}
      changeset = Role.changeset(%Role{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without name" do
      attrs = %{status: :active}
      changeset = Role.changeset(%Role{}, attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "valid changeset without status uses default" do
      attrs = %{name: "管理员"}
      changeset = Role.changeset(%Role{}, attrs)
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :status) == :active
    end

    test "invalid changeset with name too long" do
      attrs = %{name: String.duplicate("a", 101), status: :active}
      changeset = Role.changeset(%Role{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "invalid changeset with description too long" do
      attrs = %{name: "管理员", description: String.duplicate("a", 501), status: :active}
      changeset = Role.changeset(%Role{}, attrs)
      refute changeset.valid?
      assert %{description: ["should be at most 500 character(s)"]} = errors_on(changeset)
    end
  end
end
