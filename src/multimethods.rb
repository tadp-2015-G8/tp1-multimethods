require_relative '../src/partial_block'

module Multimethods

  def initialize
    @@is_partial_method = false
  end

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
    @@is_partial_method = true
    object = (self.is_a? Module)? self : self.singleton_class

    partial_blocks[nuevo_metodo] ||= {}
    partial_blocks[nuevo_metodo][tipos] = PartialBlock.new(tipos, &block)

    object.send(:define_method, nuevo_metodo) do |*args|
      self.instance_exec(*args, &get_metodo_a_ejecutar(nuevo_metodo, *args))
    end

  end

  def respond_to_multimethod?(multimetodo, args = nil)
    !partial_blocks_total(multimetodo).nil? and (args.nil? or !partial_blocks_total(multimetodo).values.find_all { |block| block.matches_with_class(*args) }.empty?)
  end

  def respond_to?(metodo, include_all = false, args = nil)
    super(metodo, include_all) and (args.nil? or respond_to_multimethod?(metodo, args))
  end

  private

  # Lookup del metodo. Elige que metodo (block) que se tiene que ejecutar
  # self aca es siempre una instancia, pero no se sabe si definio un multimetodo de instancia o de clase/modulo.
  def get_metodo_a_ejecutar(method, *args)
    candidatos = partial_blocks_total(method).values.find_all { |block| block.matches(*args) }

    if candidatos.empty?
      raise NoMethodError, "#{method} no esta definido para los argumentos recibidos"
    end
    candidatos.min_by {|block| block.distancia(*args)}
  end

  # Devuelve un hash con todos los tipos y bloques que debe entender por sus superclases y modulos para el metodo pedido.
  def partial_blocks_total(method)
    partial_blocks_total = {}

    ancestros = [self] + self.class.ancestors
    ancestros.each do |ancestro|
      #si se encuentra un ancestro con definicion normal se corta la busqueda.
      (ancestro.is_a? Module and ancestro.instance_methods(false).include? method and not ancestro.multimethods.include? method)? break :

      ancestro.partial_blocks.find_all { |bloque| bloque[0] == method }.each do |_, hash_tipos|
        hash_tipos.each do |lista_tipos, block|
          unless  partial_blocks_total[lista_tipos] != nil
            partial_blocks_total[lista_tipos] = block
          end
        end
      end

    end
    partial_blocks_total
  end


end

class Object
  include Multimethods

  #Borra los multimetodos definidos antes de una definicion normal en una misma clase
  def self.method_added(method_name)
    @@is_partial_method ||= false
    if not @@is_partial_method and not multimethods.empty?
      partial_blocks.delete(method_name)
    end
  end
end





