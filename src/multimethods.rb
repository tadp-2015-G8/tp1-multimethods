require_relative '../src/partial_block'

module Multimethods

  # variable que guarda los blocks de cada multimethod.
  def partial_blocks
    @partial_blocks ||= {}
  end

  def multimethods
    partial_blocks_total.keys
  end

  def multimethod(method)
    (multimethods.include? method)? instance_method(method) : (raise NameError, "Multimetodo #{method} no definido")
  end

  def partial_def(nuevo_metodo, tipos, &block)
    object = (self.is_a? Module)? self : self.singleton_class

    partial_blocks[nuevo_metodo] ||= {}
    partial_blocks[nuevo_metodo][tipos] = PartialBlock.new(tipos, &block)

    object.send(:define_method, nuevo_metodo) do |*args|
      self.instance_exec(*args, &get_metodo_a_ejecutar(nuevo_metodo, *args))
    end
  end

  def base
    object_singleton = self.clone

    multimethods.each do |multimetodo|
      object_singleton.define_singleton_method(multimetodo) do |tipos, *args|
        bloque = partial_blocks_total[multimetodo][tipos]

        if bloque.nil?
          raise NoMethodError, "#{multimetodo} no esta definido para los argumentos recibidos"
        end

        self.instance_exec(*args, &bloque)
      end
    end

    object_singleton
  end

  def respond_to_multimethod?(multimetodo, args = nil)
    multimethods.include?(multimetodo) and (args.nil? or !partial_blocks_total[multimetodo].values.find_all { |block| block.matches_with_class(*args) }.empty?)
  end

  def respond_to?(metodo, include_all = false, args = nil)
    super(metodo, include_all) and (args.nil? or respond_to_multimethod?(metodo, args))
  end

#  private

  # Lookup del metodo. Elige que metodo (block) que se tiene que ejecutar
  # self aca es siempre una instancia, pero no se sabe si definio un multimetodo de instancia o de clase/modulo.
  def get_metodo_a_ejecutar(method, *args)
    candidatos = partial_blocks_total[method].values.find_all { |block| block.matches(*args) }

    if candidatos.empty?
      raise NoMethodError, "#{method} no esta definido para los argumentos recibidos"
    end
    candidatos.min_by {|block| block.distancia(*args)}
  end

  # Devuelve un hash con todos los multimetodos, tipos y bloques que debe entender por sus superclases y modulos para el metodo pedido.
  def partial_blocks_total
    partial_blocks_total = {}

    ancestros = [self] + self.class.ancestors
    ancestros.reverse.each do |ancestro|
      partial_blocks_total.keys.each do |multimetodo|
        if ancestro.is_a? Module and ancestro.instance_methods(false).include? multimetodo and not ancestro.partial_blocks.keys.include? multimetodo
          partial_blocks_total.delete(multimetodo)
        end
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
end

class Object
  include Multimethods
end





