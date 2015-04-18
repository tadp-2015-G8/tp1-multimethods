class PartialBlock
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

  def call(*args)
    if !self.matches(*args)
      raise ArgumentError, "Argumentos invalidos"
    end

    @block.call(*args)
  end
end

