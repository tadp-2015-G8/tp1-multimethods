require_relative '../src/partial_block'

module Multimethods

  # variable que guarda los blocks de cada multimethod.
  def partial_blocks
    @partial_blocks ||= {}
  end
  
  def base
    @base ||= MultimethodsBase.new(self)
  end

  def multimethods(regular = true)
    regular ? partial_blocks_total.keys : partial_blocks.keys
  end

  def multimethod(method)
    (multimethods.include? method)? instance_method(method) : (raise NoMethodError, "undefined method '#{method}' for #{self}")
  end

  # Define un multimetodo.
  def partial_def(method, tipos, &block)
    object = (self.is_a? Module)? self : self.singleton_class

    object.partial_blocks[method] ||= {}
    object.partial_blocks[method][tipos] = PartialBlock.new(tipos, &block)

    object.send(:define_method, method) do |*args|
      self.instance_exec(*args, &get_metodo_a_ejecutar(method, *args))
    end
  end

  def respond_to_multimethod?(method, args = nil)
    multimethods.include?(method) and (args.nil? or not partial_blocks_total[method].values.find_all { |block| block.matches_with_class(*args) }.empty?)
  end

  def respond_to?(method, include_all = false, args = nil)
    super(method, include_all) and (args.nil? or respond_to_multimethod?(method, args))
  end

  private
  # Lookup del metodo. Elige que metodo (block) que se tiene que ejecutar
  # self aca es siempre una instancia, pero no se sabe si definio un multimetodo de instancia o de clase/modulo.
  def get_metodo_a_ejecutar(method, *args)
    candidatos = partial_blocks_total[method].values.find_all { |block| block.matches(*args) }

    if candidatos.empty?
      raise ArgumentError, "undefined multimethod '#{method}' for arguments #{args} in #{self}"
    end
    candidatos.min_by { |block| block.distancia(*args) }
  end

  # Devuelve un hash con todos los multimetodos, tipos y bloques que debe entender por sus superclases y modulos para el metodo pedido.
  def partial_blocks_total
    partial_blocks_total = {}

    ancestros = (self.is_a? Module) ? ancestors : self.singleton_class.ancestors
    ancestros.reverse_each do |ancestro|
      partial_blocks_total.delete_if do |multimetodo, _|
        ancestro.instance_methods(false).include? multimetodo and not ancestro.partial_blocks.keys.include? multimetodo
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

    def method_missing(method, tipos, *args)
      instancia.instance_exec(*args, &get_metodo_a_ejecutar(method, tipos, *args))
    end

    def get_metodo_a_ejecutar(method, tipos, *args)
      partial_blocks = instancia.send(:partial_blocks_total)

      if partial_blocks[method].nil?
        raise NoMethodError, "undefined method '#{method}' for #{instancia}"
      end

      candidato = partial_blocks[method][tipos]

      if candidato.nil?
        raise TypeError, "undefined multimethod '#{method}' for types #{tipos} in #{instancia}"
      end

      if not candidato.matches(*args)
        raise ArgumentError, "undefined multimethod '#{method}' for arguments #{args} in #{instancia}"
      end

      candidato
    end
  end
end

class Object
  include Multimethods
end
