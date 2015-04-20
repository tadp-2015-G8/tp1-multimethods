require_relative '../src/partial_block'

module Multimethods

    def partial_def(nuevo_metodo, tipos, &block)
      @receiver =  (self.is_a? Module)? self : self.singleton_class

      @multimethods ||= {}
      @multimethods[nuevo_metodo] ||= {}
      @multimethods[nuevo_metodo][tipos] = PartialBlock.new(tipos, &block)

      unless @receiver.method_defined?(nuevo_metodo)
        @receiver.send(:define_method, nuevo_metodo)  do |*args|
          @receiver = (multimethods.include? nuevo_metodo)? self : self.class
          @receiver.get_metodo_a_ejecutar(nuevo_metodo, *args).call_with_object(self, *args)
        end
      end
    end

    def get_metodo_a_ejecutar(method, *args)
      candidatos =  @multimethods[method].values.find_all{|block| block.matches(*args) }
      if candidatos.empty?
        raise NoMethodError, "#{method} no esta definido para los argumentos recibidos"
      end
      candidatos.min_by {|block| block.distancia(*args)}
    end

    def multimethods
      @multimethods? @multimethods.keys : []
    end

    def multimethod(method)
      (multimethods.include? method)? instance_method(method) : (raise NameError, "Multimetodo #{method} no definido")
    end
end

class Object
  include Multimethods
end
