require_relative '../src/partial_block'

module Multimethods

  # variable que guarda los blocks de cada multimethod.
  def partial_blocks
    @partial_blocks ||= {}
  end

  def multimethods(regular = true)
    regular ? partial_blocks_total.keys : partial_blocks.keys
  end

  def multimethod(method)
    (multimethods.include? method)? instance_method(method) : (raise NameError, "Multimetodo #{method} no definido")
  end

  # Define un multimetodo y el metodo en base.
  def partial_def(nuevo_metodo, tipos, &block)
    object = (self.is_a? Module)? self : self.singleton_class

    partial_blocks[nuevo_metodo] ||= {}
    partial_blocks[nuevo_metodo][tipos] = PartialBlock.new(tipos, &block)

    object.send(:define_method, nuevo_metodo) do |*args|
      self.instance_exec(*args, &get_metodo_a_ejecutar(nuevo_metodo, nil, *args))
    end
  end

  def base
    @base ||= MultimethodsBase.new(self)
  end

  def respond_to_multimethod?(multimetodo, args = nil)
    multimethods.include?(multimetodo) and (args.nil? or !partial_blocks_total[multimetodo].values.find_all { |block| block.matches_with_class(*args) }.empty?)
  end

  def respond_to?(metodo, include_all = false, args = nil)
    super(metodo, include_all) and (args.nil? or respond_to_multimethod?(metodo, args))
  end

  private

  # Lookup del metodo. Elige que metodo (block) que se tiene que ejecutar
  # self aca es siempre una instancia, pero no se sabe si definio un multimetodo de instancia o de clase/modulo.
  def get_metodo_a_ejecutar(method, tipos, *args)
    candidatos = tipos ? [partial_blocks_total[method][tipos]] : partial_blocks_total[method].values.find_all { |block| block.matches(*args) }

    if candidatos.empty?
      raise NoMethodError, "#{method} no esta definido para los argumentos recibidos"
    end
    candidatos.min_by { |block| block.distancia(*args) }
  end

  # Devuelve un hash con todos los multimetodos, tipos y bloques que debe entender por sus superclases y modulos para el metodo pedido.
  def partial_blocks_total
    partial_blocks_total = {}

    ancestros = [self] + self.class.ancestors
    ancestros.reverse_each do |ancestro|
      partial_blocks_total.delete_if do |multimetodo, _|
        ancestro.is_a? Module and ancestro.instance_methods(false).include? multimetodo and not ancestro.partial_blocks.keys.include? multimetodo
      end

      ancestro.partial_blocks.each do |multimetodo, hash_tipos|
        hash_tipos.each do |lista_tipos, block|
          partial_blocks_total[multimetodo] ||= {}
          partial_blocks_total[multimetodo][lista_tipos] = block
        end
      end
    end

    partial_blocks_total
  end

  class MultimethodsBase
    attr_accessor :instancia

    def initialize(instancia)
      @instancia = instancia
    end

    def method_missing(sym, *args)
      metodo = instancia.send(:get_metodo_a_ejecutar, sym, args[0], *args.drop(1))
      instancia.instance_exec(*args.drop(1), &metodo)
    end
  end
end

class Object
  include Multimethods
end
