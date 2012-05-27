class String

  def self.random(size)

    chars = ('a'..'z').to_a 
    chars += ('0'..'9').to_a
    (0...size).collect { chars[Kernel.rand(chars.length)] }.join

  end

end
