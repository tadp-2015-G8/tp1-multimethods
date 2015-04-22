require_relative '../src/partial_block'

module Multimethods

  # variable que guarda los blocks de cada multimethod.
  def partial_blocks
    @partial_blocks ||= {}
  end

  def partial_def(nuevo_metodo, tipos, &block)
    @object =  (self.is_a? Module)? self : self.singleton_class

    partial_blocks[nuevo_metodo] ||= {}
    partial_blocks[nuevo_metodo][tipos] = PartialBlock.new(tipos, &block)

    unless @object.method_defined?(nuevo_metodo)
      @object.send(:define_method, nuevo_metodo)  do |*args|
        get_metodo_a_ejecutar(nuevo_metodo, *args).call_with_object(self, *args)
      end
    end
  end

  # Lookup del metodo. Elige que metodo (block) que se tiene que ejecutar
  # self aca es siempre una instancia, pero no se sabe si definio un multimetodo de instancia o de clase/modulo.
  def get_metodo_a_ejecutar(method, *args)
    camino_ancestros = [self] + self.class.ancestors

    #ancestros_candidatos es la posible instancia/clase/modulo que definen el metodo a ejecutar
    ancestros_candidatos = []
    camino_ancestros.each do |ancestro|
        ancestros_candidatos << ancestro if ancestro.multimethods.include? method
    end

    #candidatos contiene metodos que matchean los argumentos.
    candidatos = []
    ancestros_candidatos.each do |ancestro|
      candidatos += ancestro.partial_blocks[method].values.find_all{|block| block.matches(*args) }
    end

    if candidatos.empty?
      raise NoMethodError, "#{method} no esta definido para los argumentos recibidos"
    end
    candidatos.min_by {|block| block.distancia(*args)}
  end

  def multimethods
    partial_blocks.keys
  end

  def multimethod(method)
    (multimethods.include? method)? instance_method(method) : (raise NameError, "Multimetodo #{method} no definido")
  end

end

class Object
  include Multimethods
end
