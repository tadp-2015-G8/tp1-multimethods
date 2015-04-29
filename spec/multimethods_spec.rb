require 'rspec'
require_relative '../src/multimethods'

describe 'test multimethods' do
  it 'concat' do
    class A

      partial_def :concat, [String, String] do |s1, s2|
        s1 + s2
      end

      partial_def :concat, [String, Integer] do |s1, n|
        s1 * n
      end

      partial_def :concat, [Array] do |a|
        a.join
      end

    end


    expect(A.new.concat('hello', 'world')).to eq("helloworld")
    expect(A.new.concat('hello', 3)).to eq("hellohellohello")
    expect(A.new.concat(['hello', ' world', '!'])).to eq("hello world!")
    expect {A.new.concat('hello', 'world', '!')}.to raise_error(NoMethodError)

  end

  it 'ejecutar definicion mas especifica' do
    class A

      partial_def :concat, [String, Integer] do |s1, n|
        s1 * n
      end

      partial_def :concat, [Object, Object] do |s1, s2|
        "Objetos concatenados"
      end
    end

     expect(A.new.concat("Hello", 2)).to eq("HelloHello")
     expect(A.new.concat(Object.new, 3)).to eq("Objetos concatenados")
  end

  it 'referencia a self desde un multimethod' do
    class A
      partial_def :dame_self, [String] do |s|
        s + self.object_id.to_s
      end
    end

    a = A.new
    expect(a.dame_self('hola')).to eq('hola' + a.object_id.to_s)
  end

  it 'referencia a self desde multimethod 2' do
    class Soldado
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
    end

    class Tanque
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
      partial_def :ataca_a, [Tanque] do |objetivo|
        self.ataca_con_canion(objetivo)
      end

      partial_def :ataca_a, [Soldado] do |objetivo|
        self.ataca_con_ametralladora(objetivo)
      end

      def ataca_con_canion(objetivo)
        "#{@nombre} ataca con canion a #{objetivo.nombre}"
      end

      def ataca_con_ametralladora(objetivo)
        "#{@nombre} ataca con ametralladora a #{objetivo.nombre}"
      end

    end

    soldado = Soldado.new('Carlitos')
    tanque = Tanque.new('Tanque1')
    tanque2 = Tanque.new('Tanque2')


    expect(tanque.ataca_a(tanque2)).to eq("Tanque1 ataca con canion a Tanque2")
    expect(tanque.ataca_a(soldado)).to eq("Tanque1 ataca con ametralladora a Carlitos")

  end

  it 'multimethods para una clase ya existente' do
    class Soldado
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
    end

    class Tanque
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
      partial_def :ataca_a, [Tanque] do |objetivo|
        self.ataca_con_canion(objetivo)
      end

      partial_def :ataca_a, [Soldado] do |objetivo|
        self.ataca_con_ametralladora(objetivo)
      end

      def ataca_con_canion(objetivo)
         "#{@nombre} ataca con canion a #{objetivo.nombre}"
      end

      def ataca_con_ametralladora(objetivo)
        "#{@nombre} ataca con ametralladora a #{objetivo.nombre}"
      end

      def atacar_con_satelite(objetivo)
        "#{@nombre} ataca con satelite a #{objetivo.nombre}"
      end


      def pisar(objetivo)
        "#{@nombre} pisa a #{objetivo.nombre}"
      end

    end

    class Avion
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
    end

    #abro la clase Tanque
    class Tanque
      #Agrego una implementacion para atacar aviones que NO pisa las anteriores
      partial_def :ataca_a, [Avion] do |avion|
        self.atacar_con_satelite(avion)
      end

    end


    soldado = Soldado.new('Carlitos')
    tanque = Tanque.new('Tanque1')
    tanque2 = Tanque.new('Tanque2')
    avion = Avion.new('Avion1')

    #pruebo que las implementacion anteriores sigan funcionando
    expect(tanque.ataca_a(tanque2)).to eq("Tanque1 ataca con canion a Tanque2")
    expect(tanque.ataca_a(soldado)).to eq("Tanque1 ataca con ametralladora a Carlitos")

    #pruebo la nueva implementacion
    expect(tanque.ataca_a(avion)).to eq("Tanque1 ataca con satelite a Avion1")

    #abro la clase Tanque
    class Tanque
      #Cambio la definicion previa de como atacar a un soldado
      partial_def :ataca_a, [Soldado] do |soldado|
        self.pisar(soldado)
      end
    end

    expect(tanque.ataca_a(soldado)).to eq("Tanque1 pisa a Carlitos")

  end

  it 'metodo multimethods' do
    class Tanque
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
      partial_def :ataca_a, [Tanque] do |objetivo|
        self.ataca_con_canion(objetivo)
      end

      def nombre
        "mi nombre"
      end

    end

    expect(Tanque.multimethods).to eq([:ataca_a])
    expect(Tanque.multimethod(:ataca_a)).to eq(Tanque.instance_method(:ataca_a))

    #el metodo nombre esta definido como un metodo normal, no como multimetodo.
    expect {Tanque.multimethod(:nombre)}.to raise_error(NameError)
end

  it 'multimethods a un unico objeto' do

    class Soldado
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
    end

    class Tanque
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
    end

    tanque_modificado = Tanque.new('Tanque1')
    tanque_modificado.partial_def :tocar_bocina_a, [Soldado] do |soldado|
      "Honk honk! #{soldado.nombre}"
    end

     tanque_modificado.partial_def :tocar_bocina_a, [Tanque] do |tanque|
     "Hooooooonk!"
    end

    expect(tanque_modificado.tocar_bocina_a(Soldado.new("pepe"))).to eq("Honk honk! pepe")
    expect(tanque_modificado.tocar_bocina_a(Tanque.new("pepe"))).to eq("Hooooooonk!")

    expect {Tanque.new("Tanque2").tocar_bocina( Tanque.new("Tanque3")) }.to raise_error(NoMethodError)

  end

  it 'multimetodo a un unico objeto cuya clase ya tiene multimetodos ' do
    class Soldado
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end
    end

    class Tanque
      attr_accessor :nombre
      def initialize(nombre)
        @nombre = nombre
      end

      partial_def :tocar_bocina_a, [Object] do |obj|
        "Honk Object"
      end

      partial_def :explotar, [] do
        "#{@nombre} exploto"
      end
    end

    tanque_modificado = Tanque.new('Tanque1')
    tanque_modificado.partial_def :tocar_bocina_a, [Soldado] do |soldado|
      "Honk honk! #{soldado.nombre}"
    end

    tanque_modificado.partial_def :tocar_bocina_a, [Tanque] do |tanque|
      "Hooooooonk!"
    end

    expect(tanque_modificado.tocar_bocina_a(Soldado.new("pepe"))).to eq("Honk honk! pepe")
    expect(tanque_modificado.tocar_bocina_a(Tanque.new("pepe"))).to eq("Hooooooonk!")
    expect {Tanque.new("Tanque2").tocar_bocina( Tanque.new("Tanque3")) }.to raise_error(NoMethodError)
    expect(tanque_modificado.tocar_bocina_a(Object.new)).to eq("Honk Object")
    expect(tanque_modificado.explotar).to eq("Tanque1 exploto")

  end

  it 'Uso de Multimetodos definidos en un modulo' do
    module M1
      partial_def :sumar, [Integer, Integer] do |x, y|
        x + y
      end

      partial_def :sumar, [Array, Array] do |arr1, arr2|
        arr1.inject(:+) + arr2.inject(:+)
      end

      partial_def :sumar, [String] do |str|
        str
      end
    end

    class A
      include M1
    end

    class B < A
    end

    obj1 = B.new

    expect(obj1.send(:sumar,[1,2,3],[1,2,3])).to eq(12)
    expect(obj1.send(:sumar,1,2)).to eq(3)
    expect(obj1.send(:sumar,"hola")).to eq("hola")
  end

  it 'Multimetodos con herencia' do
    class A
      partial_def :concat, [Array] do |arg|
        arg.join
      end
    end

    class B < A
      partial_def :concat, [Array] do |arg|
        arg.size
      end

      partial_def :sumar, [Integer, Integer] do |n1 ,n2|
        n1 + n2
      end
    end

    class C < B
      def concat(arg)
        arg.join(".")
      end
    end

    class D < C
      partial_def :concat, [Array] do |arg|
       arg.join(",")
      end
    end

    expect(A.new.concat(["a", "b", "c"])).to eq("abc")
    expect(B.new.concat(["a", "b", "c"])).to eq(3)
    expect(C.new.concat(["a", "b", "c"])).to eq("a.b.c")
    expect(D.new.concat(["a", "b", "c"])).to eq("a,b,c")
  end

  it 'respond_to? y respond_to_multimethod?' do
    module M1
      partial_def :vacio, [] do
        nil
      end
      
      partial_def :sumar, [Integer, Integer] do |x, y|
        x + y
      end

      partial_def :sumar, [Array, Array] do |arr1, arr2|
        arr1.inject(:+) + arr2.inject(:+)
      end

      partial_def :concat, [String, String] do |s1, s2|
        s1 + s2
      end
    end

    class A
      include M1

      partial_def :sumar, [String] do |str|
        str
      end

      partial_def :concat, [String, Integer] do |s1, n|
        s1 * n
      end

      partial_def :concat, [Array] do |a|
        a.join
      end

      partial_def :concat, [Object, Object] do |o1, o2|
        "Objetos concatenados"
      end
    end

    object = A.new

    expect(object.respond_to_multimethod? :vacio, []).to eq(true)
    expect(object.respond_to_multimethod? :concat, []).to eq(false)
    expect(object.respond_to_multimethod? :sumar, [Array, Array]).to eq(true)
    expect(object.respond_to_multimethod? :sumar, [Integer, Integer]).to eq(true)
    expect(object.respond_to_multimethod? :sumar, [String]).to eq(true)
    expect(object.respond_to_multimethod? :sumar, [Float, Float]).to eq(false)

    expect(object.respond_to? :concat).to eq(true) # true, define el método como multimethod
    expect(object.respond_to? :to_s).to eq(true) # true, define el método normalmente
    expect(object.respond_to? :concat, false, [String, String]).to eq(true) # true, los tipos coinciden
    expect(object.respond_to? :concat, false, [Integer, A]).to eq(true) # true, matchea con [Object, Object]
    expect(object.respond_to? :to_s, false , [String]).to eq(false) # false, no es un multimethod
    expect(object.respond_to? :concat, false, [String, String, String]).to eq(false) # false, los tipos no coinciden
    expect(object.respond_to? :concat, false, []).to eq(false)
    expect(object.respond_to? :vacio, false, []).to eq(true)
  end

  it 'Herencia, implementacion mas especifica detener busqueda cuando aparece un metodo normal' do

    class A
      partial_def :m, [String] do |s|
        p s
      end
    end

    class B < A
      def m
        p 'B'
      end
    end

    class C < B
      partial_def :m, [Integer] do |i|
        i * 2
      end
    end

    #La implementacion de A es apropiada, pero B la sobreescribe con un metodo normal.
    #Por lo tanto C termina su propia implementacion de m (corta la busqueda en B)
    expect(A.new.m("Hola")).to eq("Hola")
    expect{C.new.m("Hola")}.to raise_error(NoMethodError)
  end

  it 'Pisar metodos en la misma clase' do
    class A
      partial_def :prueba, [String] do |s|
        s.length
      end
    end

    expect(A.new.prueba("Hola")).to eq(4)

    class A
      def prueba(p)
        p * 2
      end
    end

    class A
      partial_def :prueba, [Integer] do |i|
        i
      end
    end

    expect(A.new.prueba(4)).to eq(4)
    expect(A.new.prueba("Hola")).to eq(4)
  end

end
