EctoOrdered
===========
[![Build Status](https://travis-ci.org/Mdlkxzmcp/ecto-ordered.svg?branch=master)](https://travis-ci.org/Mdlkxzmcp/ecto-ordered)

Ecto extension to support ordered list items. Similar to [acts_as_list](https://github.com/swanandp/acts_as_list), but
for [Ecto](https://github.com/elixir-lang/ecto). _Requires Elixir ≥ 1.4_

Add the latest stable release to your mix.exs file:

```elixir
defp deps do
  [
    {:ecto_ordered, github: "Mdlkxzmcp/ecto-ordered"}
  ]
end
```

Examples
--------


### Global positioning
```elixir
defmodule MyModel do
  use Ecto.Schema
  import EctoOrdered

  schema "models" do
    field :position, :integer
  end

  def changeset(model, params) do
    model
    |> cast(params, [], [:position])
    |> set_order(:position)
  end
  
  @doc """
  Used to ensure that the remaining items are repositioned on deletion
  """
  def delete_changeset(model) do
    model
    |> cast(%{}, [])
    |> Map.put(:action, :delete)
    |> set_order(:position)
  end
end

# Usage
model1 = %MyModel{title: "item with no position, going to be #1"} |> MyModel.changeset(%{}) |> Repo.insert!()
model2 = %MyModel{title: "item #2", position: 2} |> MyModel.changeset(%{}) |> Repo.insert!()

assert Repo.get(MyModel, model1.id).position == 1
assert Repo.get(MyModel, model2.id).position == 2

model1 |> MyModel.changeset(%{position: 2}) |> Repo.update()

assert Repo.get(MyModel, model1.id).position == 2
assert Repo.get(MyModel, model2.id).position == 1
```

### Scoped positioning
```elixir
defmodule MyModel do
  use Ecto.Model
  import EctoOrdered

  schema "models" do
    field :reference_id, :integer
    field :position,     :integer
  end

  def changeset(model, params) do
    model
    |> cast(params, [], [:position, :reference_id])
    |> set_order(:position, :reference_id)
  end
  
  @doc """
  Used to ensure that the remaining items are repositioned on deletion
  """
  def delete_changeset(model) do
    model
    |> cast(%{}, [])
    |> Map.put(:action, :delete)
    |> set_order(:position, :reference_id)
  end
end

# Usage
model1 = Model.changeset(%MyModel{reference_id: 1, title: "item #1"}, %{}) |> Repo.insert!()
model2 = Model.changeset(%MyModel{reference_id: 1, title: "item #2"}, %{}) |> Repo.insert!()

assert Repo.get(MyModel, model1.id).position == 1
assert Repo.get(MyModel, model2.id).position == 2

model1 |> MyModel.changeset(%{position: 2}) |> Repo.update()

assert Repo.get(MyModel, model1.id).position == 2
assert Repo.get(MyModel, model2.id).position == 1
```
