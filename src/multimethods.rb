require_relative '../src/partial_block'

module Multimethods

  # variable que guarda los blocks de cada multimethod.
  def partial_blocks
    @partial_blocks ||= {}
  end

  def multimethods
    partial_blocks.keys
  end

  def multimethod(method)
    (multimethods.include? method)? instance_method(method) : (raise NameError, "Multimetodo #{method} no definido")
  end

  def partial_def(nuevo_metodo, tipos, &block)
    object = (self.is_a? Module)? self : self.singleton_class

    partial_blocks[nuevo_metodo] ||= {}
    partial_blocks[nuevo_metodo][tipos] = PartialBlock.new(tipos, &block)

    object.send(:define_method, nuevo_metodo)  do |*args|
      get_metodo_a_ejecutar(nuevo_metodo, *args).call_with_object(self, *args)
    end

  end

  private

  # Lookup del metodo. Elige que metodo (block) que se tiene que ejecutar
  # self aca es siempre una instancia, pero no se sabe si definio un multimetodo de instancia o de clase/modulo.
  def get_metodo_a_ejecutar(method, *args)
    candidatos = partial_blocks_total[method].values.find_all { |block| block.matches(*args) }

    if candidatos.empty?
      raise NoMethodError, "#{method} no esta definido para los argumentos recibidos"
    end
    candidatos.min_by {|block| block.distancia(*args)}
  end

  # Devuelve un hash con todos los multimetodos que debe entender por sus superclases y modulos.
  def partial_blocks_total
    partial_blocks_total = Hash.new

    ancestros = [self] + self.class.ancestors
    ancestros.each do |ancestro|
      ancestro.partial_blocks.each do |multimethod, hash_de_tipos|
        partial_blocks_total[multimethod] ||= Hash.new

        hash_de_tipos.each do |tipo, partial_block|
          partial_blocks_total[multimethod][tipo] ||= partial_block
        end
      end
    end

    partial_blocks_total
  end

  def respond_to_multimethod?(multimetodo,*args)
    partial_blocks_total[multimetodo].keys.include? *args
  end

end




class Object
  include Multimethods
  
end
