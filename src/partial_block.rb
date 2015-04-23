class PartialBlock < Proc

  def initialize(tipos, &block)
    raise ArgumentError, "Cantidad de parametros invalida" if tipos and tipos.length != block.arity
    @tipos = tipos
    @block = block
  end

  def matches(*args)
    args.map! { |arg| arg.class}
    matches_with_class(*args)
  end

  def matches_with_class(*args)
    return false if args.length != @tipos.length
    (args.zip(@tipos)).each do |param, tipo|
      unless param.ancestors.include? tipo
        return false
      end
    end
    return true
  end

  def call(*args)
    unless matches(*args)
      raise ArgumentError, "Argumentos invalidos"
    end

    @block.call(*args)
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

