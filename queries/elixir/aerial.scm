(call
  target: (identifier) @identifier (#eq? @identifier "defmodule")
  (arguments) @name) @type

(call
  target: (identifier) @identifier (#any-of? @identifier "def" "defp" "defguard" "defmacro" "defmacrop")
  (arguments [
              (call target: (identifier) @name)
              (binary_operator left: (call target: (identifier) @name))
   ])) @type

(unary_operator
  operand: (call
              target: (identifier) @identifier (#eq? @identifier "callback")
  (arguments [
              (call target: (identifier) @name)
              (binary_operator left: (call target: (identifier) @name))
  ])) @type) @start

(unary_operator
  operand: (call
    target: (identifier) @identifier (#eq? @identifier "module_attribute")
    (arguments) @name
    ) @type
  ) @start

(do_block
  (call
    target: (identifier) @identifier (#eq? @identifier "defstruct")) @type) @start
