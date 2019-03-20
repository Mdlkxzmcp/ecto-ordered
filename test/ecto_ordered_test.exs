defmodule EctoOrderedTest do
  use EctoOrdered.TestCase
  alias EctoOrderedTest.Repo
  import Ecto.Query

  defmodule Model do
    use Ecto.Schema
    import Ecto.Changeset
    import EctoOrdered

    schema "model" do
      field(:title, :string)
      field(:position, :integer)
    end

    def changeset(model, params) do
      model
      |> cast(params, [:position, :title])
      |> set_order(:position)
    end

    def delete(model) do
      model
      |> cast(%{}, [])
      |> Map.put(:action, :delete)
      |> set_order(:position)
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoOrderedTest.Repo)
  end

  # No scope

  describe "inserting item" do
    test "with no position" do
      for i <- 1..10 do
        model =
          %Model{}
          |> Model.changeset(%{title: "item with no position, going to be ##{i}"})
          |> Repo.insert!()

        assert model.position == i
      end

      assert from(m in Model, select: m.position) |> Repo.all() == Enum.into(1..10, [])
    end

    test "with a correct appending position" do
      %Model{title: "item with no position, going to be #1"}
      |> Model.changeset(%{})
      |> Repo.insert!()

      model =
        %Model{title: "item #2", position: 2}
        |> Model.changeset(%{})
        |> Repo.insert!()

      assert model.position == 2
    end

    test "with a gapped position" do
      %Model{title: "item with no position, going to be #1"}
      |> Model.changeset(%{})
      |> Repo.insert()

      assert_raise EctoOrdered.InvalidMove, "too large", fn ->
        %Model{title: "item #10", position: 10}
        |> Model.changeset(%{})
        |> Repo.insert!()
      end
    end

    test "with an inserting position" do
      model1 =
        Model.changeset(%Model{}, %{title: "item with no position, going to be #1"})
        |> Repo.insert!()

      model2 =
        Model.changeset(%Model{title: "item with no position, going to be #2"}, %{})
        |> Repo.insert!()

      model3 =
        Model.changeset(%Model{title: "item with no position, going to be #3"}, %{})
        |> Repo.insert!()

      model =
        Model.changeset(%Model{title: "item #2", position: 2}, %{})
        |> Repo.insert!()

      assert model.position == 2
      assert Repo.get(Model, model1.id).position == 1
      assert Repo.get(Model, model2.id).position == 3
      assert Repo.get(Model, model3.id).position == 4
    end

    test "with an inserting position at #1" do
      model1 =
        Model.changeset(%Model{title: "item with no position, going to be #1"}, %{})
        |> Repo.insert!()

      model2 =
        Model.changeset(%Model{title: "item with no position, going to be #2"}, %{})
        |> Repo.insert!()

      model3 =
        Model.changeset(%Model{title: "item with no position, going to be #3"}, %{})
        |> Repo.insert!()

      model =
        Model.changeset(%Model{title: "item #1", position: 1}, %{})
        |> Repo.insert!()

      assert model.position == 1
      assert Repo.get(Model, model1.id).position == 2
      assert Repo.get(Model, model2.id).position == 3
      assert Repo.get(Model, model3.id).position == 4
    end
  end

  ## Moving

  test "updating item with the same position" do
    model =
      Model.changeset(%Model{title: "item with no position"}, %{})
      |> Repo.insert!()

    model1 =
      Model.changeset(%Model{model | title: "item with a position"}, %{})
      |> Repo.update!()

    assert model.position == model1.position
  end

  test "replacing an item below" do
    model1 = Model.changeset(%Model{title: "item #1"}, %{}) |> Repo.insert!()
    model2 = Model.changeset(%Model{title: "item #2"}, %{}) |> Repo.insert!()
    model3 = Model.changeset(%Model{title: "item #3"}, %{}) |> Repo.insert!()
    model4 = Model.changeset(%Model{title: "item #4"}, %{}) |> Repo.insert!()
    model5 = Model.changeset(%Model{title: "item #5"}, %{}) |> Repo.insert!()

    model2 |> Model.changeset(%{position: 4}) |> Repo.update!()

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model3.id).position == 2
    assert Repo.get(Model, model4.id).position == 3
    assert Repo.get(Model, model2.id).position == 4
    assert Repo.get(Model, model5.id).position == 5
  end

  test "replacing an item above" do
    model1 = Model.changeset(%Model{title: "item #1"}, %{}) |> Repo.insert!()
    model2 = Model.changeset(%Model{title: "item #2"}, %{}) |> Repo.insert!()
    model3 = Model.changeset(%Model{title: "item #3"}, %{}) |> Repo.insert!()
    model4 = Model.changeset(%Model{title: "item #4"}, %{}) |> Repo.insert!()
    model5 = Model.changeset(%Model{title: "item #5"}, %{}) |> Repo.insert!()

    model4 |> Model.changeset(%{position: 2}) |> Repo.update()

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model4.id).position == 2
    assert Repo.get(Model, model2.id).position == 3
    assert Repo.get(Model, model3.id).position == 4
    assert Repo.get(Model, model5.id).position == 5
  end

  test "updating item with a tail position" do
    model1 = Model.changeset(%Model{title: "item #1"}, %{}) |> Repo.insert!()
    model2 = Model.changeset(%Model{title: "item #2"}, %{}) |> Repo.insert!()
    model3 = Model.changeset(%Model{title: "item #3"}, %{}) |> Repo.insert!()

    model2 |> Model.changeset(%{position: 4}) |> Repo.update!()

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model3.id).position == 2
    assert Repo.get(Model, model2.id).position == 3
  end

  ## Deletion

  test "deleting an item" do
    model1 = Model.changeset(%Model{title: "item #1"}, %{}) |> Repo.insert!()
    model2 = Model.changeset(%Model{title: "item #2"}, %{}) |> Repo.insert!()
    model3 = Model.changeset(%Model{title: "item #3"}, %{}) |> Repo.insert!()
    model4 = Model.changeset(%Model{title: "item #4"}, %{}) |> Repo.insert!()
    model5 = Model.changeset(%Model{title: "item #5"}, %{}) |> Repo.insert!()

    model2 |> Model.delete() |> Repo.delete()

    assert Repo.get(Model, model1.id).position == 1
    assert Repo.get(Model, model3.id).position == 2
    assert Repo.get(Model, model4.id).position == 3
    assert Repo.get(Model, model5.id).position == 4
  end
end
