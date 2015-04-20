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

    expect(pi.call()).to eq( 3.14159265359)
    expect(pi.matches()).to eq(true)
  end

  it 'PartialBlock distancia' do
    block = PartialBlock.new([Numeric]) do |p1|
      p1
    end

    expect(block.distancia(3)).to eq(2)
    expect(block.distancia(3.0)).to eq(1)


    block = PartialBlock.new([Numeric, Integer]) do |s1, s2|
      s1 + s2
    end

    expect(block.distancia(3.0, 3)).to eq(3)
    expect(block.distancia(3, 3)).to eq(4)
  end
end