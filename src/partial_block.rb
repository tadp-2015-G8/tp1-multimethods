class PartialBlock
  attr_accessor :block
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

  def distancia(*args)
    if !self.matches(*args)
      raise ArgumentError, "Argumentos invalidos"
    end
    args.zip(@tipos, 1..(args.size + 1)).map { |argumento, tipo, indice|
      argumento.class.ancestors.index(tipo) * indice
    }.inject(:+)
  end
end

