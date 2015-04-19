
class PartialBlock
  attr_reader :tipos

  def initialize(tipos, &block)
    raise ArgumentError, "Cantidad de parametros invalida" if tipos and tipos.length != block.arity
    @tipos = tipos
    @block = block
  end

  def matches(*args)
    return false if args.length != @tipos.length
    (args.zip(@tipos)).each do |param, tipo|
      unless param.is_a? tipo
        return false
      end
    end
    return true
  end

 def call_with_object(object, *args)
    unless matches(*args)
      raise ArgumentError, "Argumentos invalidos"
    end

    object.instance_exec(*args, &@block)
 end

  def call(*args)
    call_with_object(self, *args)
  end
end

class Class
  def multimethods
    @multimethods ||= Hash.new
  end

  private

  def partial_def(nuevo_metodo, tipos, &bloque)
    multimethods[nuevo_metodo] ||= Array.new
    multimethods[nuevo_metodo] << PartialBlock.new(tipos, &bloque)

    unless method_defined?(nuevo_metodo)
      define_method(nuevo_metodo) do |*argumentos|
        candidatos = self.class.multimethods[nuevo_metodo].select do |partial_block|
          partial_block.matches(*argumentos)
        end

        if candidatos.empty?
          raise ArgumentError, "#{nuevo_metodo} no esta definido para los argumentos recibidos"
        end

        candidatos.min_by { |partial_block|

          argumentos.zip(partial_block.tipos, 1..(argumentos.size + 1)).map { |argumento, tipo, indice|
            indice * argumento.class.ancestors.index(tipo)
          }.inject(:+)

        }.call_with_object(self, *argumentos)
      end
    end
  end
end
