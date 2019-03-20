defmodule EctoOrderedScopeTest do
  use EctoOrdered.TestCase
  alias EctoOrderedTest.Repo
  import Ecto.Query

  defmodule Model do
    use Ecto.Schema
    import Ecto.Changeset
    import EctoOrdered

    schema "scoped_model" do
      field(:title, :string)
      field(:scope, :integer)
      field(:scoped_position, :integer)
    end

    def changeset(model, params) do
      model
      |> cast(params, [:scope, :scoped_position, :title])
      |> set_order(:scoped_position, :scope)
    end

    def delete(model) do
      model
      |> cast(%{}, [])
      |> Map.put(:action, :delete)
      |> set_order(:scoped_position, :scope)
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoOrderedTest.Repo)
  end

  # Insertion
  describe "scoped: inserting item" do
    test "with no position" do
      for s <- 1..10, i <- 1..10 do
        model =
          Model.changeset(%Model{scope: s, title: "no position, going to be ##{i}"}, %{})
          |> Repo.insert!()

        assert model.scoped_position == i
      end

      for s <- 1..10 do
        assert from(m in Model,
                 select: m.scoped_position,
                 order_by: [asc: :id],
                 where: m.scope == ^s
               )
               |> Repo.all() == Enum.into(1..10, [])
      end
    end

    test "with a correct appending position" do
      Model.changeset(%Model{scope: 10, title: "item with no position, going to be #1"}, %{})
      |> Repo.insert()

      Model.changeset(%Model{scope: 11, title: "item #2"}, %{}) |> Repo.insert()

      model =
        Model.changeset(%Model{scope: 10, title: "item #2", scoped_position: 2}, %{})
        |> Repo.insert!()

      assert model.scoped_position == 2
    end

    test "with a gapped position" do
      Model.changeset(%Model{scope: 1, title: "item with no position, going to be #1"}, %{})
      |> Repo.insert!()

      assert_raise EctoOrdered.InvalidMove, "too large", fn ->
        Model.changeset(%Model{scope: 1, title: "item #10", scoped_position: 10}, %{})
        |> Repo.insert()
      end
    end

    test "with an inserting position" do
      model1 =
        Model.changeset(%Model{scope: 1, title: "no position, going to be #1"}, %{})
        |> Repo.insert!()

      model2 =
        Model.changeset(%Model{scope: 1, title: "no position, going to be #2"}, %{})
        |> Repo.insert!()

      model3 =
        Model.changeset(%Model{scope: 1, title: "no position, going to be #3"}, %{})
        |> Repo.insert!()

      model =
        Model.changeset(%Model{scope: 1, title: "item #2", scoped_position: 2}, %{})
        |> Repo.insert!()

      assert model.scoped_position == 2
      assert Repo.get(Model, model1.id).scoped_position == 1
      assert Repo.get(Model, model2.id).scoped_position == 3
      assert Repo.get(Model, model3.id).scoped_position == 4
    end

    test "with an inserting position at #1" do
      model1 =
        Model.changeset(%Model{scope: 1, title: "no position, going to be #1"}, %{})
        |> Repo.insert!()

      model2 =
        Model.changeset(%Model{scope: 1, title: "no position, going to be #2"}, %{})
        |> Repo.insert!()

      model3 =
        Model.changeset(%Model{scope: 1, title: "no position, going to be #3"}, %{})
        |> Repo.insert!()

      model =
        Model.changeset(%Model{scope: 1, title: "item #1", scoped_position: 1}, %{})
        |> Repo.insert!()

      assert model.scoped_position == 1
      assert Repo.get(Model, model1.id).scoped_position == 2
      assert Repo.get(Model, model2.id).scoped_position == 3
      assert Repo.get(Model, model3.id).scoped_position == 4
    end
  end

  ## Moving
  describe "scoped:" do
    test "updating item with the same position" do
      model = Model.changeset(%Model{scope: 1, title: "no position"}, %{}) |> Repo.insert!()

      model1 =
        Model.changeset(model, %{title: "item with a position", scope: 1})
        |> Repo.update!()

      assert model.scoped_position == model1.scoped_position
    end

    test "replacing an item below" do
      model1 = Model.changeset(%Model{scope: 1, title: "item #1"}, %{}) |> Repo.insert!()
      model2 = Model.changeset(%Model{scope: 1, title: "item #2"}, %{}) |> Repo.insert!()
      model3 = Model.changeset(%Model{scope: 1, title: "item #3"}, %{}) |> Repo.insert!()
      model4 = Model.changeset(%Model{scope: 1, title: "item #4"}, %{}) |> Repo.insert!()
      model5 = Model.changeset(%Model{scope: 1, title: "item #5"}, %{}) |> Repo.insert!()

      model2 |> Model.changeset(%{scoped_position: 4}) |> Repo.update()

      assert Repo.get(Model, model1.id).scoped_position == 1
      assert Repo.get(Model, model3.id).scoped_position == 2
      assert Repo.get(Model, model4.id).scoped_position == 3
      assert Repo.get(Model, model2.id).scoped_position == 4
      assert Repo.get(Model, model5.id).scoped_position == 5
    end

    test "replacing an item above" do
      model1 = Model.changeset(%Model{scope: 1, title: "item #1"}, %{}) |> Repo.insert!()
      model2 = Model.changeset(%Model{scope: 1, title: "item #2"}, %{}) |> Repo.insert!()
      model3 = Model.changeset(%Model{scope: 1, title: "item #3"}, %{}) |> Repo.insert!()
      model4 = Model.changeset(%Model{scope: 1, title: "item #4"}, %{}) |> Repo.insert!()
      model5 = Model.changeset(%Model{scope: 1, title: "item #5"}, %{}) |> Repo.insert!()

      model4 |> Model.changeset(%{scoped_position: 2}) |> Repo.update()

      assert Repo.get(Model, model1.id).scoped_position == 1
      assert Repo.get(Model, model4.id).scoped_position == 2
      assert Repo.get(Model, model2.id).scoped_position == 3
      assert Repo.get(Model, model3.id).scoped_position == 4
      assert Repo.get(Model, model5.id).scoped_position == 5
    end

    test "updating item with a tail position" do
      model1 = Model.changeset(%Model{scope: 1, title: "item #1"}, %{}) |> Repo.insert!()
      model2 = Model.changeset(%Model{scope: 1, title: "item #2"}, %{}) |> Repo.insert!()
      model3 = Model.changeset(%Model{scope: 1, title: "item #3"}, %{}) |> Repo.insert!()

      model2 |> Model.changeset(%{scoped_position: 4}) |> Repo.update()

      assert Repo.get(Model, model1.id).scoped_position == 1
      assert Repo.get(Model, model3.id).scoped_position == 2
      assert Repo.get(Model, model2.id).scoped_position == 3
    end

    test "moving between scopes" do
      model1 = Model.changeset(%Model{scope: 1, title: "item #1"}, %{}) |> Repo.insert!()
      model2 = Model.changeset(%Model{scope: 1, title: "item #2"}, %{}) |> Repo.insert!()
      model3 = Model.changeset(%Model{scope: 1, title: "item #3"}, %{}) |> Repo.insert!()

      xmodel1 = Model.changeset(%Model{scope: 2, title: "item #1"}, %{}) |> Repo.insert!()
      xmodel2 = Model.changeset(%Model{scope: 2, title: "item #2"}, %{}) |> Repo.insert!()
      xmodel3 = Model.changeset(%Model{scope: 2, title: "item #3"}, %{}) |> Repo.insert!()

      model2 |> Model.changeset(%{scoped_position: 4, scope: 2}) |> Repo.update()

      assert Repo.get(Model, model1.id).scoped_position == 1
      assert Repo.get(Model, model1.id).scope == 1
      assert Repo.get(Model, model3.id).scoped_position == 2
      assert Repo.get(Model, model3.id).scope == 1

      assert Repo.get(Model, xmodel1.id).scoped_position == 1
      assert Repo.get(Model, xmodel2.id).scoped_position == 2
      assert Repo.get(Model, xmodel3.id).scoped_position == 3
      assert Repo.get(Model, model2.id).scoped_position == 4
      assert Repo.get(Model, model2.id).scope == 2
    end

    ## Deletion

    test "deleting an item" do
      model1 = Model.changeset(%Model{title: "item #1", scope: 1}, %{}) |> Repo.insert!()
      model2 = Model.changeset(%Model{title: "item #2", scope: 1}, %{}) |> Repo.insert!()
      model3 = Model.changeset(%Model{title: "item #3", scope: 1}, %{}) |> Repo.insert!()
      model4 = Model.changeset(%Model{title: "item #4", scope: 1}, %{}) |> Repo.insert!()
      model5 = Model.changeset(%Model{title: "item #5", scope: 1}, %{}) |> Repo.insert!()

      model2 |> Model.delete() |> Repo.delete()

      assert Repo.get(Model, model1.id).scoped_position == 1
      assert Repo.get(Model, model3.id).scoped_position == 2
      assert Repo.get(Model, model4.id).scoped_position == 3
      assert Repo.get(Model, model5.id).scoped_position == 4
    end
  end
end
