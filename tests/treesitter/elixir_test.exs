defmodule Example.Module do
  @module_attribute :value

  def public_function() do
  end

  defp private_function() do
  end

  defguard public_guard(x) when is_atom(x)

  defguard private_guard(x) when is_atom(x)
 
  defmacro public_macro() do
  end

  defmacrop private_macro() do
  end
end

defmodule Example.Behaviour do
  @callback example_function(atom()) :: atom()
end

defmodule Example.Struct do
  defstruct name: nil, age: nil # Creates a Struct with the name of the current module
end

#defprotocol Example.Protocol do # Should probably map to Interface
#  @spec public_function_head(t, atom()) :: boolean # Typespecs, map to TypeParameter ?
#  def public_function_head(target, opt) # Functions heads should map to Function as regular functions 
#end
#
#defimpl Example.Protocol, for: Map do # Should it be a Module or a kind of Namespace ?
#  @spec public_function_head(Map.t(), atom()) :: boolean
#  def public_function_head(target, opt) do
#    true 
#  end
#end
