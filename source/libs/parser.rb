#! /usr/bin/ruby
# coding: utf-8
require_relative 'rdparse.rb'
require_relative 'nodes.rb'

class EPParser
  def initialize
    @ep = Parser.new('EasyProgramming') do
      # Tokens
      #token(/set \w+ to .+/)
      token(/\s+/) # Garbage/White space
      token(/#.*$/) # single line comment
      token(/-?\d+\.\d+/, &:to_f) # floats
      token(/-?\d+/, &:to_i) # integers
      token(/create function/) {|m| m}
      token(/call function/) {|m| m}
      token(/while/) { |m| m }
      token(/for/) { |m| m}
      token(/if/) { |m| m}

      token(/(equation\([^'].+\))/) { |m| m }

      token(/(true|True|False|false)/) {|m| m}
      token(/else|elseif/) { |m| m } # if - else, while , for
      token(/'[^']*'/) { |m| m } # strings
      token(/print/) { |m| m}
      token(/equals/) { |m| m}
      token(/not equals/) { |m| m}
      token(/greater than/) { |m| m}
      token(/lesser than/) { |m| m}
      token(/greater or equal to/) { |m| m}
      token(/lesser or equal to/) { |m| m}
      #token(/while/) { |m| m }
      token(/increase/) { |m| m }
      token(/decrease/) { |m| m }
      token(/(\*|\/|\+|\-)/) { |m| m } # operators
      token(/(?!\B'[^']*)[a-zA-Z]+(?![^']*'\B)/) { |m| m } # variables


      #token(/\([^']*\)/) { |m| m }

      token(/return/) { |m| m }
      #token(/equals|not equals|greater than|lesser than|greater or equal to|lesser or equal to/) { |m| m } # comparison operators
      
      token(/->/) { |m| m }
      token(/;/) { |m| m }
      token(/./) { |m| m }

      

      start :program do
        match(:statement_list) { |sl| BasicNode.new(sl) }
      end

      rule :statement_list do
        match(:statement, :statement_terminator, :statement_list) { |s, _, sl| [s].concat(sl) }
        match(:statement, :statement_terminator) { |s, _| [s] }
        #match(:statement) { |s| [s] }
      end

      rule :statement_terminator do
        match(/;/)
      end

      rule :statement do
        match(:function_def)

        match(:if_statement)
        match(:for_statement)
        match(:while_statement)
        match(:return)
        match(:print)
        match(:expr)
        
      end

      rule :expr do
        match(:expr_call) # functions?
        match(:arithmetics)
        match(:assignment)
        match(:comparison)
        
        match(:bool)
        match(:identifer)
        match(:print)
        match(:string)
      end

      rule :expr_call do
        match('call function', :identifer, '(', :param_list, ')')  { |_,i,_,pl,_| FunctionCallNode.new(i,pl) }
        match('call function', :identifer, '(', ')')  { |_,i,_,_| FunctionCallNode.new(i, [])}
      end

      rule :return do
        match('return', :numeric) { |_, e| ReturnNode.new(e) }
        match('return', :identifer) { |_, e| ReturnNode.new(e) }
      end

      rule :print do
        match('print', :identifer) { |_, i| PrintNode.new(i) }
        match('print', :string) { |_, i| PrintNode.new(i) }
        match('print', :numeric) { |_, i| PrintNode.new(i) }
      end

      rule :if_statement do
        match('if', :expr, :condition_body) \
        do |_, if_condition, if_body|
          if_handler(if_body, if_condition)
        end
      end

      rule :for_statement do
        match('for', :expr, :condition_body) \
        do |_, e, b|
          for_handler(b, e) #bae <3
        end
        
      end

      rule :while_statement do
        match('while', :expr, :condition_body) \
        do |_, e, b|
          while_handler(b, e)
        end
      end

      rule :condition_body do
        match('{', :statement_list, '}') { |_, sl, _| sl }
        match(:statement) { |s| s }
      end

      rule :param_call_list do
        match(:expr, ',', :param_call_list) { |e, _, pcl| [e].concat(pcl) }
        match(:expr) { |e| e }
      end

      rule :param_list do
        match(:identifer, ',', :param_def_list) do |i, _, _pdl|
          [[i.name, :nv]].concat(pl)
        end
        match(:identifer, ',', :param_list) do |i, _, pl|
          [[i.name, :nv]].concat(pl)
        end
        match(:identifer) { |i| [[i.name, :nv]] }
      end

        rule :function_def do
          match('create function', :identifer, '(', :param_list, ')', '{', :statement_list, '}') \
          do |_,i,_,params,_,_,statements,_|
            FunctionDefNode.new(i.name, params, BlockNode.new(statements, 'func'))
          end
          match('create function', :identifer, '(', ')', '{', :statement_list, '}') \
          do |_,i,_,_,_,statements,_|
            FunctionDefNode.new(i.name, [], BlockNode.new(statements, 'func'))
          end
        end


      rule :assignment do
        match('set', :identifer, 'to', :expr) do |_, i, _, e|
          AssignmentNode.new(i, e)
        end
        match(:identifer, '=', :expr) do |i, _, e|
          AssignmentNode.new(i, e)
        end
        match('increase', :identifer) { |_,a| AssignmentNode.new(a, 1)}
        match('decrease', :identifer) { |_,a| AssignmentNode.new(a, -1)}
      end

      rule :identifer do
        match(:name) { |n| VariableNode.new(n) }
      end

      rule :name do
        match(/(?!\B'[^']*)[a-zA-Z]+(?![^']*'\B)/) { |n| n }
      end

      rule :comparison do
        match(:identifer, :comparison_operator, :bool) { |a, op, b| ComparisonNode.new(a, op, b) }
        match(:identifer, :comparison_operator, :identifer) { |a, op, b| ComparisonNode.new(a, op, b) }
        match(:identifer, :comparison_operator, :numeric) { |a, op, b| ComparisonNode.new(a, op, b) }
        match(:identifer, :comparison_operator, :string) { |a, op, b| ComparisonNode.new(a, op, b) }
        match(:numeric, :comparison_operator, :numeric) { |a, op, b| ComparisonNode.new(a, op, b) }
      end

      rule :comparison_operator do
        match('greater or equal to') { |op| op }
        match('lesser or equal to') { |op| op }
        match('greater than') { |op| op }
        match('lesser than') { |op| op }
        match('not equals') { |op| op }
        match('equals') { |op| op }
      end

      rule :arithmetics do
        match(:equation) { |a| EquationNode.new(a) }
        match(:numeric, :arith_op, :arithmetics) { |a, op, b| ArithmeticNode.new(a, op, b) }
        match(:numeric)
      end

      rule :arith_op do
        match('*') { |op| op }
        match('/') { |op| op }
        match('+') { |op| op }
        match('-') { |op| op }
      end

      rule :equation do
        match(/(equation\([^'].+\))/) { |m| m }
      end

      rule :numeric do
        match(:float)
        match(:integer)
      end

      rule :float do
        match(Float) { |m| ConstantNode.new(m) }
      end

      rule :integer do
        match(Integer) { |m| ConstantNode.new(m) }
      end

      rule :string do
        # remove quotes
        match(/'[^']*'/) { |m| ConstantNode.new(m) }
      end

      rule :bool do
        match('true') { ConstantNode.new(true) }
        match('false') { ConstantNode.new(false) }
      end
    end
    log true
   end

  def parse(code)
    @ep.parse(code)
  end

  def log(state = true)
    @ep.logger.level = if state
                         Logger::DEBUG
                       else
                         Logger::WARN # WARN
                       end
  end

  def compile(filename)
    ep = EPParser.new

    f = File.read filename
    ep.log(false)
    program = ep.parse f
    res = program.evaluate
  end
end
