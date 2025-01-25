defmodule AdminTable.Range do
  import Ecto.Query
  use Phoenix.Component

  defstruct [:field, :key, :options]

  def new(field, key, options) do
    %__MODULE__{field: field, key: key, options: options}
  end

  def apply(acc, %__MODULE__{field: field, options: options}) do
    dynamic(
      [p],
      ^acc and fragment("? BETWEEN ? AND ?", field(p, ^field), ^options.min, ^options.max)
    )
  end

  def render(assigns) do
    ~H"""
    <div class="w-64 mx-4">
      <label class="block mb-2 text-sm font-medium text-gray-700">Price Range</label>
      <div
        id="price-range"
        phx-hook="RangeSlider"
        phx-update="ignore"
        data-key={@key}
        data-data=""
        data-min="0"
        data-max="500"
        data-start={"[#{Map.get(@filters, @key).options.min || 0}, #{Map.get(@filters, @key).options.max || 500}]"}
        class="h-2 mt-4 w-64"
      >
        <div class="slider-target"></div>
      </div>
    </div>
    """
  end
end
