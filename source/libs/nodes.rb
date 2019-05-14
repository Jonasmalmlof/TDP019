# coding: utf-8
class Scope
  attr_reader :vars
  def initialize(parent = nil)
    @parent = parent
    @vars = {}
    @functions = {}
  end

  # assign variables
  def assign(name, value)
    # does the variable exist in current scope
    if key? name
      @vars[name] = value
    # does parent have the variable?
    elsif @parent && @parent.key?(name)
       @parent.assign(name, value)
    # assign to this scope
    else
       @vars[name] = value
    end
  end

  def get(name)
    if key? name
       @vars[name]
    elsif @parent
       @parent.get name
    else
       :notfound
    end
  end

  def key?(name)
    return @vars.key? name
  end

  def function?(name)
    return @functions.key? name
  end

  def add_function(name, func)
    return @functions[name] = func
  end

  def get_function(name)
    if function? name
      @functions[name]
    elsif @parent
      @parent.get_function name
    else
      :notfound
    end
  end
end

class BasicNode
  def initialize(statements)
    @statements = if statements.is_a? Array
                    statements
                  else
                    [statements]
                  end
  end

  def evaluate
    highestscope = Scope.new
    @statements.each do |s|
      result = s.evaluate highestscope
      return result[0] if result[1] == :return
    end
  end
end

class BlockNode < BasicNode

  def initialize(statements, type='')
    @statements = statements
    @type = type
  end

  def evaluate(scope,while_loop = false)
    if !while_loop
      new_scope = Scope.new(scope)
    end

    @statements.each do |s|
      
      if while_loop
        result = s.evaluate scope
      else
        result = s.evaluate new_scope
      end
      
      return result if result[1] == :return
    end
  end
end

# functions begin here!
class FunctionDefNode
  def initialize(function_name, params, block)
    @function_name = function_name
    @params = params
    @block = block
  end

  def evaluate(scope)
    [scope.add_function(@function_name, FunctionNode.new(@function_name, @params, @block)), :ok]
  end
end

class FunctionNode
      def initialize(function_name, params, block)
        @function_name = function_name
        @params = params
        @block = block
      end
      def evaluate(scope, params)
        new_scope = Scope.new(scope)

        #array to deep copy param list so we can preserve values
        var_copy = []
        @params.each { |e| var_copy.push(e.dup) }

        #assign the value to the new copy list
        params.each_with_index { |p,i| var_copy[i][1] = p} #var_copy[i] = p}

        #assign all the values to current new scope
        var_copy.each { |v| new_scope.assign(v[0], v[1])}
        
        #run the function block.
        @block.evaluate(new_scope)
        
      end
    end

class FunctionCallNode
  def initialize(function_name, params)
    @function_name = function_name
    @params = params
  end
  
  def evaluate(scope)
    #get function
    func = scope.get_function(@function_name.name)
    
    #take all params, inject [] to get the correct list we need to copy later.
    params = @params.inject([]) {|a,e| a << scope.get(e[0].to_s)}
        
    func.evaluate(scope,*[params])
  end
end

# functions end here!

class ForNode
  def initialize(block, cond)
    @block = block
    @cond = cond
  end

  def evaluate(scope)
    while @cond.evaluate(scope)[0]
      new_scope = Scope.new(scope)
      result = @block.evaluate(new_scope)
      return result if result[1] == :return
      @cond.increase('a', 1, scope)
    end
    [nil, :ok]
  end
end

class WhileNode
      def initialize(block, cond)
        @block = block
        @cond = cond
      end
      def evaluate(scope)
        new_scope = Scope.new(scope)

        while @cond.evaluate(new_scope)[0]   
          result = @block.evaluate(new_scope, true)
          return result if result[1] == :return
        end
        [nil, :ok]
      end
    end

class IfNode
  def initialize(body, cond)
    @body = body
    @cond = cond
  end

  def evaluate(scope)
    @body.evaluate scope
  end

  def true?(scope)
    @cond.evaluate(scope)[0]
  end
end

class ReturnNode
  def initialize(expr)
    @expr = expr
  end

  def evaluate(scope)
    [@expr.evaluate(scope)[0], :return]
  end
end

class PrintNode
  def initialize(value)
    @value = value
  end

  def evaluate(scope)
      value = @value.evaluate(scope)[0]
      puts value
      [value, :ok]
  end
end

class IConditionalNode
  def initialize(i_block)#
    @i_block = i_block
  end

  def evaluate(scope)
    return @i_block.evaluate(scope) if @i_block.true?(scope)
    [:fail, :ok]
  end
end

class ConditionalNode
  def initialize(statement)
    @statement = statement
  end
  
  def evaluate(scope)
    
    if @statement.is_a? WhileNode
      
      while @statement.true?(scope)
        @statement.evaluate(scope)
      end
    end
  end
end


class ConditionNode
  def initialize(cond)
    @cond = cond
  end

  def evaluate(scope)
    [@cond.evaluate(scope)[0], :ok]
  end
end

class ComparisonNode
  def initialize(a, operator, b)
    @a = a
    @b = b
    @operator = operator
  end

  def increase(variable_to_increase, amount, scope)
    
    temp_a = @a.evaluate(scope)[0]
    temp_b = @b.evaluate(scope)[0]
    case variable_to_increase
    when 'a'
      scope.assign(@a.name, temp_a + amount )
    when 'b'
      scope.assign(@b.name, temp_b + amount )
    end
  end

  def evaluate(scope)
    case @operator
    when 'equals'
      [@a.evaluate(scope)[0] == @b.evaluate(scope)[0], :ok]
    when 'not equals'
      [@a.evaluate(scope)[0] != @b.evaluate(scope)[0], :ok]
    when 'greater or equal to'
      [@a.evaluate(scope)[0] >= @b.evaluate(scope)[0], :ok]
    when 'lesser or equal to'
      [@a.evaluate(scope)[0] <= @b.evaluate(scope)[0], :ok]
    when 'greater than'
      [@a.evaluate(scope)[0] > @b.evaluate(scope)[0], :ok]
    when 'lesser than'
      [@a.evaluate(scope)[0] < @b.evaluate(scope)[0], :ok]
    end
  end
end

class AssignmentNode
  def initialize(var, value)
    @name = var.name
    @value = value
  end

  def evaluate(scope)
    if @value.is_a? Float or @value.is_a? Integer
      temp_value = scope.get(@name)
      [scope.assign(@name, temp_value + @value), :ok]
    else
      [scope.assign(@name, @value.evaluate(scope)[0]), :ok]
    end
    
  end
end

class VariableNode
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def evaluate(scope)
    value = scope.get(@name)

    if value == :notfound
      raise "Error: no variable called '" + @name + "' found!"
    else
      return [value, :ok]
    end
  end
end

class ArithmeticNode
  def initialize(lh, op = nil, rh = nil)
    @lh = lh
    @op = op
    @rh = rh
  end

  def evaluate(scope)
    if @lh && @op.nil? && @rh.nil?
      @lh.evaluate(scope)
    elsif @lh && @op && @rh
      temp_string = @lh.evaluate(scope)[0].to_s + @op.to_s + @rh.evaluate(scope)[0].to_s
      [eval(temp_string), :ok]
    end
  end
end

class EquationNode
  def initialize(eq)
    @eq = eq.gsub(/equation/, '')
  end

  def evaluate(scope)
    temp_string = @eq.to_s
    [eval(temp_string), :ok]
  end
end

class ConstantNode
  def initialize(value)
    @value = value
  end

  def evaluate(scope)
    [@value, :ok]
  end
end


def if_handler(if_body, if_header, elseif = [], e = nil)
  if_node = IfNode.new(BlockNode.new(if_body), ConditionNode.new(if_header))
  IConditionalNode.new(if_node)
end

def for_handler(for_body, cond)
  for_node = ForNode.new(BlockNode.new(for_body), cond)
end

def while_handler(while_body,cond)
  while_statement = WhileNode.new(BlockNode.new(while_body), cond )
end
