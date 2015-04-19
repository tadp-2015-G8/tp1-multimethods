require 'rspec'
require_relative '../src/partial_block'

describe 'test PartialBlock' do

  it 'PartialBlock constructor' do
    expect {PartialBlock.new([String, Integer]) do |who|
      "Hello #{who}"
    end
    }.to raise_error(ArgumentError)
  end

  it 'PartialBlock matches' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.matches("a")).to eq(true)
    expect(helloBlock.matches(1)).to eq(false)
    expect(helloBlock.matches("a", "b")).to eq(false)
  end

  it 'PartialBlock call' do
    helloBlock = PartialBlock.new([String]) do |who|
      "Hello #{who}"
    end

    expect(helloBlock.call("world!")).to eq("Hello world!")
    expect { helloBlock.call(1) }.to raise_error(ArgumentError)
  end

  it 'PartialBlock con subtipos' do
    pairBlock = PartialBlock.new([Object, Object]) do |left, right|
      [left, right]
    end

    expect(pairBlock.call("Hello", 1)).to eq(["Hello", 1])
  end

  it 'PartialBlock definido sin argumentos' do
    pi = PartialBlock.new([]) do
      3.14159265359
    end

    expect(pi.call()).to eq(3.14159265359)
    expect(pi.matches()).to eq(true)
  end

  it 'Multimetodos' do
    class A
      partial_def :concat, [Object, Object] do |o1, o2|
        "Objetos concatenados"
      end

      partial_def :concat, [String, String] do |s1, s2|
        s1 + s2
      end

      partial_def :concat, [String, Integer] do |s1, n|
        s1 * n
      end

      partial_def :concat, [Array] do |a|
        a.join
      end

      partial_def :clase, [] do
        self.class
      end

      partial_def :var, [] do
        @var
      end

      partial_def :var=, [Integer] do |arg|
        @var = arg
      end
    end

    expect(A.new.concat("hello", " world")).to eq("hello world")
    expect(A.new.concat("hello", 3)).to eq("hellohellohello")
    expect(A.new.concat(["hello", " world", "!"])).to eq("hello world!")
    expect(A.new.concat(Object.new, 3)).to eq("Objetos concatenados")
    expect(A.new.clase).to eq(A)
    expect {A.new.concat("hello", " world", "!")}.to raise_error(ArgumentError)

    b = A.new
    b.var = 123
    expect(b.var).to eq(123)
  end
end